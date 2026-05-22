#!/usr/bin/env bash
# =====================================================================
# TigerAI Monitoring Deployer
# Path: deployments/09-monitoring-alerting/deploy.sh
# =====================================================================

set -eo pipefail

LOG_PREFIX="TigerAI Monitor Deploy"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

cd "$(dirname "$0")"

# Simply install the systemd service
chmod +x tiger-monitor.sh
sudo ./tiger-monitor.sh install

LOG " Monitoring service deployed and activated."
