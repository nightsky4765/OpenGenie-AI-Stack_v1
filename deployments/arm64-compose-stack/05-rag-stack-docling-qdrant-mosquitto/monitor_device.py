"""
monitor_device.py

Continuous loop script to monitor GPU metrics and publish via MQTT.

Designed to be run as a daemon or via cron @reboot on the HOST machine
(not inside a container), so nvidia-smi / rocm-smi are directly available.

Published MQTT topics:
  device/gpu/metrics — GPU temperature/utilization/VRAM (every cycle)

Loop interval set to 5 seconds.
"""

import asyncio
import json
import logging
import os
import re
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

MQTT_BROKER_HOST = os.getenv("LANDING_LOCAL_MQTT_HOST", "localhost")
MQTT_BROKER_PORT = int(os.getenv("LANDING_LOCAL_MQTT_PORT", "9013"))
MQTT_USER = os.getenv("LANDING_LOCAL_MQTT_USER")
MQTT_PASSWORD = os.getenv("LANDING_LOCAL_MQTT_PASSWORD")
MONITOR_INTERVAL = int(os.getenv("HEALTH_CHECK_INTERVAL", "5"))  # Seconds

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# GPU Probe
# ─────────────────────────────────────────────────────────────────────────────

_GPU_PROBE_TIMEOUT = 5  # seconds


def _probe_nvidia_gpu() -> dict | None:
    """
    Query NVIDIA GPU via nvidia-smi.

    nvidia-smi --query-gpu=name,memory.total,memory.used,utilization.gpu,temperature.gpu
               --format=csv,noheader,nounits

    Example output: "NVIDIA GeForce RTX 3080, 10240, 4096, 45, 62"
    Multi-GPU: one line per GPU.
    """
    try:
        proc = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=index,name,memory.total,memory.used,utilization.gpu,temperature.gpu",
                "--format=csv,noheader,nounits",
            ],
            capture_output=True,
            text=True,
            timeout=_GPU_PROBE_TIMEOUT,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None

    if proc.returncode != 0 or not proc.stdout.strip():
        return None

    def _safe_int(val: str) -> int:
        """Parse int, return 0 for [N/A] or non-numeric values."""
        try:
            return int(val)
        except (ValueError, TypeError):
            return 0

    def _safe_float(val: str) -> float | None:
        """Parse float, return None for [N/A] or non-numeric values."""
        try:
            return float(val)
        except (ValueError, TypeError):
            return None

    gpus = []
    for line in proc.stdout.strip().split("\n"):
        parts = [p.strip() for p in line.split(",")]
        if len(parts) < 6:
            continue
        gpus.append(
            {
                "index": _safe_int(parts[0]),
                "model": parts[1],
                "vram_total_mb": _safe_int(parts[2]),
                "vram_used_mb": _safe_int(parts[3]),
                "gpu_usage_percent": _safe_float(parts[4]) or 0.0,
                "temperature_celsius": _safe_float(parts[5]),
            }
        )

    if not gpus:
        return None

    return {
        "gpu_type": "NVIDIA",
        "gpu_count": len(gpus),
        "gpus": gpus,
    }


def _probe_amd_gpu() -> dict | None:
    """
    Query AMD GPU via rocm-smi.

    rocm-smi --showuse --showtemp --showmeminfo vram
    """
    try:
        proc = subprocess.run(
            ["rocm-smi", "--showuse", "--showtemp", "--showmeminfo", "vram"],
            capture_output=True,
            text=True,
            timeout=_GPU_PROBE_TIMEOUT,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None

    if proc.returncode != 0 or not proc.stdout.strip():
        return None

    output = proc.stdout

    gpu_usage = 0.0
    m = re.search(r"GPU use \(%\):\s*([\d.]+)", output)
    if m:
        gpu_usage = float(m.group(1))

    temperature: float | None = None
    m = re.search(r"Temperature.*?:\s*([\d.]+)", output)
    if m:
        temperature = float(m.group(1))

    vram_total_mb = 0
    m = re.search(r"VRAM Total Memory \(B\):\s*(\d+)", output)
    if m:
        vram_total_mb = int(m.group(1)) // (1024 * 1024)

    vram_used_mb = 0
    m = re.search(r"VRAM Total Used Memory \(B\):\s*(\d+)", output)
    if m:
        vram_used_mb = int(m.group(1)) // (1024 * 1024)

    model = "AMD GPU"
    m = re.search(r"Card series:\s*(.+)", output)
    if m:
        model = m.group(1).strip()

    return {
        "gpu_type": "AMD",
        "gpu_count": 1,
        "gpus": [
            {
                "index": 0,
                "model": model,
                "vram_total_mb": vram_total_mb,
                "vram_used_mb": vram_used_mb,
                "gpu_usage_percent": gpu_usage,
                "temperature_celsius": temperature,
            }
        ],
    }


def get_gpu_metrics() -> dict | None:
    """
    Detect GPU vendor and return metrics.

    Returns dict with gpu_type, gpu_count, gpus[] or None if CPU-only.
    """
    result = _probe_nvidia_gpu()
    if result is not None:
        return result

    result = _probe_amd_gpu()
    if result is not None:
        return result

    return None


# ─────────────────────────────────────────────────────────────────────────────
# Core Logic
# ─────────────────────────────────────────────────────────────────────────────


async def publish_gpu_metrics(client: Client) -> None:
    metrics = await asyncio.to_thread(get_gpu_metrics)
    if metrics is None:
        return

    topic = "device/gpu/metrics"
    await client.publish(topic, payload=json.dumps(metrics))

    for gpu in metrics["gpus"]:
        log.info(
            "🎮 GPU[%d] %s — %.1f%% util, %.0f°C, VRAM %d/%d MB",
            gpu["index"],
            gpu["model"],
            gpu["gpu_usage_percent"],
            gpu.get("temperature_celsius") or 0,
            gpu["vram_used_mb"],
            gpu["vram_total_mb"],
        )


async def main():
    log.info(
        "🚀 Monitor starting up. Broker: %s:%s", MQTT_BROKER_HOST, MQTT_BROKER_PORT
    )
    log.info("   Interval: %ds", MONITOR_INTERVAL)

    while True:
        try:
            async with Client(
                hostname=MQTT_BROKER_HOST,
                port=MQTT_BROKER_PORT,
                username=MQTT_USER,
                password=MQTT_PASSWORD,
            ) as client:
                while True:
                    log.info("── Monitoring Round ──")
                    await publish_gpu_metrics(client)
                    await asyncio.sleep(MONITOR_INTERVAL)
        except Exception as e:
            log.error("❌ Broker connection lost: %s. Retrying in 5s...", e)
            await asyncio.sleep(5)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        log.info("👋 Stopped by user")
