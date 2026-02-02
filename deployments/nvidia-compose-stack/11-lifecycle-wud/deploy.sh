#!/usr/bin/env bash
# =====================================================================
# TigerAI Container Lifecycle Deployer (WUD)
# Path: deployments/11-lifecycle-wud/deploy.sh
# =====================================================================

set -eo pipefail

LOG_PREFIX="TigerAI Lifecycle"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

cd "$(dirname "$0")"

LOG " Launching What's Up Docker (WUD) Container Management Center..."
docker compose up -d

LOG " Lifecycle dashboard is up. Access at http://localhost:3838"
