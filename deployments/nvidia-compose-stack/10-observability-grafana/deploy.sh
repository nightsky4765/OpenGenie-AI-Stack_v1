#!/usr/bin/env bash
# =====================================================================
# TigerAI NVIDIA Observability Deployer
# Path: deployments/nvidia-compose-stack/10-observability-grafana/deploy.sh
# =====================================================================

set -eo pipefail

LOG_PREFIX="TigerAI Observability"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

cd "$(dirname "$0")"

LOG " Launching NVIDIA Observability Stack (Grafana/Prometheus/DCGM)..."
docker compose up -d

LOG " Observability stack is up. Access Grafana at http://localhost:3000 (User: admin / Pass: CHANGE_ME)"
