"""
register_device.py

One-off script to register the device to the MQTT broker.
Designed to be run once at system startup (e.g., via cron @reboot).
"""

import asyncio
import json
import logging
import os
import socket
import ssl
import subprocess
from pathlib import Path

from aiomqtt import Client
from dotenv import load_dotenv

# Load .env files in sequence (later files override earlier ones)
_SCRIPT_DIR = Path(__file__).resolve().parent

# 1. Local .env
load_dotenv(dotenv_path=_SCRIPT_DIR / ".env", override=True)
# 2. Tuning .env
load_dotenv(dotenv_path=_SCRIPT_DIR.parent / "tiger-tuning.env", override=True)
# 3. Parent stack .env (Highest priority)
load_dotenv(dotenv_path=_SCRIPT_DIR.parent / ".env", override=True)

MQTT_BROKER_HOST = os.getenv("LANDING_CLOUD_MQTT_HOST", "localhost")
MQTT_BROKER_PORT = int(os.getenv("LANDING_CLOUD_MQTT_PORT", "443"))
MQTT_USER = os.getenv("LANDING_CLOUD_MQTT_USER")
MQTT_PASSWORD = os.getenv("LANDING_CLOUD_MQTT_PASSWORD")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)


def get_device_id() -> str:
    """Read product_uuid from DMI if available, then try dmidecode, else fallback to env."""
    uuid_path = "/sys/class/dmi/id/product_uuid"
    try:
        if os.path.exists(uuid_path):
            with open(uuid_path, "r") as f:
                return f.read().strip()
    except Exception as e:
        log.debug("Could not read %s: %s", uuid_path, e)

    try:
        result = subprocess.run(
            ["sudo", "dmidecode", "-s", "system-uuid"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            uuid = result.stdout.strip()
            if uuid:
                return uuid
    except Exception as e:
        log.debug("dmidecode failed: %s", e)

    return os.getenv("DEVICE_ID", "550e8400-e29b-41d4-a716-446655440000")


def get_device_ip() -> str:
    """Get the primary outbound IP address of the device."""
    try:
        # Create a UDP socket. It doesn't actually send any data.
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # Connect to a public IP to determine the active outbound interface
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception as e:
        log.debug("Failed to get outbound IP: %s", e)

    return os.getenv("DEVICE_IP", "127.0.0.1")


DEVICE_ID = get_device_id()


async def main():
    # Wait for DHCP IP if currently 127.0.0.1
    current_ip = get_device_ip()
    while current_ip == "127.0.0.1":
        log.info("⏳ Waiting for DHCP IP (currently 127.0.0.1)...")
        await asyncio.sleep(5)
        current_ip = get_device_ip()

    log.info(
        "🚀 Registering device to MQTT broker %s:%s", MQTT_BROKER_HOST, MQTT_BROKER_PORT
    )
    log.info("   DEVICE_ID: %s", DEVICE_ID)
    log.info("   DEVICE_IP: %s", current_ip)

    try:
        async with Client(
            hostname=MQTT_BROKER_HOST,
            port=MQTT_BROKER_PORT,
            username=MQTT_USER,
            password=MQTT_PASSWORD,
            transport="websockets",
            tls_context=ssl.create_default_context(),  # 建立 TLS 上下文,
        ) as client:
            register_payload = {"device_id": DEVICE_ID, "ip": current_ip}
            await client.publish(
                "devices/register", payload=json.dumps(register_payload)
            )
            log.info("📡 Published: devices/register  →  %s", register_payload)
            log.info("✅ Registration complete.")
    except Exception as e:
        log.error("❌ Failed to register device: %s", e)


if __name__ == "__main__":
    asyncio.run(main())
