#!/usr/bin/env bash
# =====================================================================
# TigerAI Infra Deployer
# Path: deployments/amd-compose-stack/01-infra-webssh-portainer/deploy.sh
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

LOG_PREFIX="TigerAI Infra"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }
ERROR(){ echo -e "${RED}[$LOG_PREFIX ERROR]${NC} $*"; exit 1; }

usage() {
    echo "Usage: sudo $0 {all | webssh | portainer | down | restart}"
    exit 1
}

# --- 1) Logic ---
[ $# -eq 0 ] && usage

ensure_network() {
    docker network inspect ai_stack_net >/dev/null 2>&1 || docker network create ai_stack_net
}

ACTION=$1
ensure_network

case "$ACTION" in
    all)
        LOG " Starting ALL Infrastructure (WebSSH, Portainer)..."
        docker compose up -d
        ;;
    webssh|portainer)
        LOG " Starting specific service: $ACTION..."
        docker compose up -d "$ACTION"
        ;;
    down)
        LOG " Removing all infrastructure containers..."
        docker compose down
        ;;
    restart)
        LOG " Restarting all infrastructure..."
        docker compose down && docker compose up -d
        ;;
    *)
        usage
        ;;
esac

LOG " Deployment command finished."
