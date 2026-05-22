#!/usr/bin/env bash
# =====================================================================
# TigerAI amd-compose-stack Lifecycle Deployer
# =====================================================================
set -eo pipefail

# --- 0) Configuration & Cleansing ---
# Import from local .env first
if [ -f .env ]; then
  export $(grep -v '^#' .env | sed 's/\r//g' | xargs)
fi

# Then import from tiger-tuning.env (if exists)
if [ -f ../tiger-tuning.env ]; then
  export $(grep -v '^#' ../tiger-tuning.env | sed 's/\r//g' | xargs)
fi

# Finally import from parent stack .env (overrides all)
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | sed 's/\r//g' | xargs)
fi

# Robust Variable Cleansing (Against Windows CRLF)
for var in $(env | grep -E 'PORT|IMAGE|URL|PATH|USER|PASS|DB|SECRET|TZ' | cut -d= -f1); do
  export "$var"="$(echo "${!var}" | tr -d '\r')"
done

# --- 1) Port Intelligence ---
find_free_port() {
    local port=$1
    while ss -tuln | grep -q ":$port\b"; do
        port=$((port + 1))
    done
    echo "$port"
}

for port_var in $(env | grep '_PORT=' | cut -d= -f1); do
  original_port="${!port_var}"
  fixed_port=$(find_free_port "$original_port")
  if [ "$original_port" != "$fixed_port" ]; then
    echo -e "\033[1;33m[Port Collision]\033[0m $port_var: $original_port -> $fixed_port"
    export "$port_var"="$fixed_port"
  fi
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

LOG " Deploying Lifecycle..."
docker compose up -d

# --- 3) Post-Deployment Check ---
echo -e "\n${BLUE}=====================================================================${NC}"
echo -e "${GREEN}  $LOG_PREFIX DEPLOYMENT SUCCESSFUL${NC}"
echo -e "${BLUE}=====================================================================${NC}"
echo -e "Service Checklist:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "label=com.docker.compose.project=$(basename $(pwd))" | sed 's/^/  /'
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "Useful Information:"
echo -e "  - Architecture : amd-compose-stack"
echo -e "  - Layer Details: Container Update Notifier (3838)"
echo -e "  - Tuning File  : tiger-tuning.env (detected: $([ -f ../tiger-tuning.env ] && echo "Yes" || echo "No"))"
echo -e "${BLUE}=====================================================================${NC}\n"