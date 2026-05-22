#!/usr/bin/env bash
# =====================================================================
# TigerAI arm64-compose-stack Lifecycle Deployer
# =====================================================================
set -eo pipefail

# --- 0) Configuration & Cleansing ---
# Import from local .env first
if [ -f .env ]; then
  export $(grep -v '^#' .env | sed 's/\r//g' | xargs)
fi

# Then import from tuning if exists
if [ -f ../tiger-tuning.env ]; then
  export $(grep -v '^#' ../tiger-tuning.env | sed 's/\r//g' | xargs)
fi

# Finally import from parent stack .env (overrides local)
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | sed 's/\r//g' | xargs)
fi

# Robust Variable Cleansing (Against Windows CRLF)
for var in $(env | grep -E 'PORT|IMAGE|URL|PATH|USER|PASS|DB|SECRET|TZ|TIGER_LOG_MAX_SIZE' | cut -d= -f1); do
  export "$var"="$(echo "${!var}" | tr -d '\r')"
done

LOG_PREFIX="TigerAI Lifecycle"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }
ERROR(){ echo -e "${RED}[$LOG_PREFIX ERROR]${NC} $*"; exit 1; }

ensure_network() {
    docker network inspect ai_stack_net >/dev/null 2>&1 || docker network create ai_stack_net
}

LOG " Initializing Lifecycle Layer..."
ensure_network

case "$1" in
    all|up)
        LOG " Deploying Lifecycle..."
        docker compose up -d
        ;;
    down)
        LOG " Stopping Lifecycle..."
        docker compose down
        ;;
    *)
        LOG "Usage: $0 {all|up|down}"
        exit 1
        ;;
esac

# --- 3) Post-Deployment Check ---
echo -e "\n${BLUE}=====================================================================${NC}"
echo -e "${GREEN}  $LOG_PREFIX DEPLOYMENT SUCCESSFUL${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo -e "Service Checklist:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=wud" | sed 's/^/  /'
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "Useful Information:"
echo -e "  - Architecture : arm64-compose-stack"
echo -e "  - Layer Details: Container Update Notifier (3838)"
echo -e "${BLUE}=====================================================================${NC}\n"
