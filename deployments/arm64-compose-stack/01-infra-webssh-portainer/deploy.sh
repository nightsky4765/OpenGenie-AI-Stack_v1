#!/usr/bin/env bash
# =====================================================================
# TigerAI ARM64 Infra Deployer
# Path: deployments/arm64-compose-stack/01-infra-webssh-portainer/deploy.sh
# =====================================================================

set -eo pipefail

# --- 0) Configuration & Variables ---
# Import from local .env first
if [ -f .env ]; then
  export $(grep -v '^#' .env | sed 's/\r//g' | xargs)
fi

# Then import from tuning if exists
if [ -f ../tiger-tuning.env ]; then
  export $(grep -v '^#' ../tiger-tuning.env | sed 's/\r//g' | xargs)
fi

# Finally import from parent stack .env (if exists)
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | sed 's/\r//g' | xargs)
fi

LOG_PREFIX="TigerAI Infra"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

usage() {
    echo "Usage: sudo $0 {all | webssh | portainer | agent | down | restart}"
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
    webssh|portainer|agent)
        LOG " Starting specific service: $ACTION..."
        if [ "$ACTION" == "agent" ]; then
            docker compose up -d portainer-edge-agent
        else
            docker compose up -d "$ACTION"
        fi
        ;;
    down)
        LOG " Removing all infrastructure containers..."
        docker compose down
        ;;
    restart)
        LOG " Restarting all infrastructure..."
        # docker compose down && docker compose up -d
        docker compose restart 
        ;;
    *)
        usage
        ;;
esac

LOG " Deployment command finished."
