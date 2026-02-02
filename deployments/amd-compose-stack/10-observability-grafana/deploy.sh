#!/usr/bin/env bash
# =====================================================================
# TigerAI AMD Observability Deployer
# Path: deployments/amd-compose-stack/10-observability-grafana/deploy.sh
# =====================================================================

set -eo pipefail

# --- 0) Configuration & Variables ---
# Import from local .env first (with CRLF handling)
if [ -f .env ]; then
  export $(grep -v '^#' .env | sed 's/\r//g' | xargs)
fi

# Then import from parent stack .env (overrides local, with CRLF handling)
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | sed 's/\r//g' | xargs)
fi

LOG_PREFIX="TigerAI Observability"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

cd "$(dirname "$0")"

# --- 1) Install ROCm SMI textfile collector ---
LOG " Setting up ROCm SMI GPU metrics collector..."
sudo mkdir -p /var/lib/node_exporter/textfile_collector
sudo cp ./rocm-smi-collector.sh /usr/local/bin/rocm-smi-collector.sh
sudo chmod +x /usr/local/bin/rocm-smi-collector.sh

# Run once to generate initial metrics
sudo /usr/local/bin/rocm-smi-collector.sh

# Add cron job (every 15 seconds via 4 entries)
CRON_CMD="/usr/local/bin/rocm-smi-collector.sh"
if ! sudo crontab -l 2>/dev/null | grep -q "rocm-smi-collector"; then
    (sudo crontab -l 2>/dev/null; echo "* * * * * ${CRON_CMD}") | sudo crontab -
    LOG " Cron job installed (runs every minute)."
else
    LOG " Cron job already exists."
fi

# --- 2) Launch stack ---
LOG " Launching AMD Observability Stack (Grafana/Prometheus/ROCm)..."
docker compose up -d

LOG " Observability stack is up. Access Grafana at http://localhost:3000 (User: admin / Pass: CHANGE_ME)"
