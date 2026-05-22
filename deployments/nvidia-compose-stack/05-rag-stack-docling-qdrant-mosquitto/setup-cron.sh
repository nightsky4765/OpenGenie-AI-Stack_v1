#!/usr/bin/env bash
# =====================================================================
# TigerAI Device MQTT Cron Installer
# Path: deployments/nvidia-compose-stack/05-rag-stack-docling-qdrant-mosquitto/setup-cron.sh
# =====================================================================

set -eo pipefail

LOG_PREFIX="TigerAI Device Cron"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTER_SCRIPT="$SCRIPT_DIR/register_device.py"
MONITOR_SCRIPT="$SCRIPT_DIR/monitor_device.py"
VENV_PYTHON="$SCRIPT_DIR/.venv/bin/python3"

# Check if scripts and venv exist
if [ ! -f "$REGISTER_SCRIPT" ]; then
    echo "Error: $REGISTER_SCRIPT not found"
    exit 1
fi
if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo "Error: $MONITOR_SCRIPT not found"
    exit 1
fi
if [ ! -f "$VENV_PYTHON" ]; then
    echo "Error: Virtual environment not found at $VENV_PYTHON. Please run deploy.sh first."
    exit 1
fi

# 1. Setup Register Cron (@reboot)
REG_CRON_JOB="@reboot cd $SCRIPT_DIR && $VENV_PYTHON $REGISTER_SCRIPT > $SCRIPT_DIR/device_register.log 2>&1"

if crontab -l 2>/dev/null | grep -q "$REGISTER_SCRIPT"; then
    LOG "Device Registration cron job already exists, skipping."
else
    LOG "Installing Device Registration cron job (@reboot)..."
    (crontab -l 2>/dev/null; echo "$REG_CRON_JOB") | crontab -
fi

# 2. Setup Monitor Cron (@reboot)
MON_CRON_JOB="@reboot cd $SCRIPT_DIR && $VENV_PYTHON $MONITOR_SCRIPT > $SCRIPT_DIR/device_monitor.log 2>&1"

if crontab -l 2>/dev/null | grep -q "$MONITOR_SCRIPT"; then
    LOG "Device Monitor cron job already exists, skipping."
else
    LOG "Installing Device Monitor cron job (@reboot)..."
    (crontab -l 2>/dev/null; echo "$MON_CRON_JOB") | crontab -
fi

LOG "MQTT Device scripts installed to crontab."
crontab -l | grep -E "register_device|monitor_device"
