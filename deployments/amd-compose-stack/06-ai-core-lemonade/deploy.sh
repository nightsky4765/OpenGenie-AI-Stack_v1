#!/usr/bin/env bash
# =====================================================================
# TigerAI Lemonade Core Service Deployer
# Path: deployments/amd-compose-stack/06-ai-core-lemonade/deploy.sh
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

# Finally import from tiger-tuning.env (highest priority - hardware optimized)
if [ -f ../tiger-tuning.env ]; then
  export $(grep -v '^#' ../tiger-tuning.env | sed 's/\r//g' | xargs)
fi

LOG_PREFIX="TigerAI Lemonade"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }
ERROR(){ echo -e "${RED}[$LOG_PREFIX ERROR]${NC} $*"; exit 1; }

usage() {
    echo "Usage: sudo $0 {all | down | restart | status | logs | edu | rag | purge}"
    echo "  all     : Pull image + start all services"
    echo "  down    : Stop all services"
    echo "  restart : Restart all services"
    echo "  status  : Show container status"
    echo "  logs    : Follow logs"
    echo "  edu     : EDU mode  — stop rag, keep edu + embed"
    echo "  rag     : RAG mode  — stop embed, keep edu + rag"
    echo "  purge   : ⚠️  Stop + remove containers and volumes"
    exit 1
}

[ $# -eq 0 ] && usage

# Fallback defaults
MODELS_DIR=${MODELS_DIR:-/home/wrt/TigerAI/models}
LEMONADE_API_KEY=${LEMONADE_API_KEY:-}
TIGER_CPU_THREADS=${TIGER_CPU_THREADS:-16}
GGML_VULKAN_DEVICE_EDU=${GGML_VULKAN_DEVICE_EDU:-0}
GGML_VULKAN_DEVICE_RAG=${GGML_VULKAN_DEVICE_RAG:-0}
GGML_VULKAN_DEVICE_EMBED=${GGML_VULKAN_DEVICE_EMBED:-0}
TIGER_RENDER_GID=${TIGER_RENDER_GID:-$(getent group render 2>/dev/null | cut -d: -f3 || echo "992")}
TIGER_VIDEO_GID=${TIGER_VIDEO_GID:-$(getent group video  2>/dev/null | cut -d: -f3 || echo "44")}
export TIGER_RENDER_GID TIGER_VIDEO_GID

prep_dirs() {
    REAL_USER="${SUDO_USER:-${USER:-wrt}}"
    sudo mkdir -p "$MODELS_DIR"
    sudo chown -R "$REAL_USER":"$REAL_USER" "$MODELS_DIR"
}

ensure_network() {
    docker network inspect ai_stack_net >/dev/null 2>&1 || docker network create ai_stack_net
}

ACTION=$1
prep_dirs
ensure_network

case "$ACTION" in
    all)
        LOG " Pulling image and starting all services..."
        docker compose pull
        docker compose up -d
        LOG "✅ Lemonade services started (edu:8800, rag:8801, embed:8802)"
        ;;
    down)
        LOG " Stopping Lemonade services..."
        docker compose down
        ;;
    restart)
        LOG " Restarting Lemonade services..."
        docker compose down && $0 all
        ;;
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs -f
        ;;
    edu)
        LOG " Switching to EDU mode (edu + embed)..."
        docker compose stop lemonade-rag
        docker compose start lemonade-embed lemonade-edu
        LOG "✅ EDU mode active (8800 + 8802)"
        ;;
    rag)
        LOG " Switching to RAG mode (edu + rag)..."
        docker compose stop lemonade-embed
        docker compose start lemonade-rag lemonade-edu
        LOG "✅ RAG mode active (8800 + 8801)"
        ;;
    purge)
        LOG " ⚠️ Purging containers and volumes..."
        docker compose down -v
        LOG "✅ Purged. Reinstall with: sudo $0 all"
        ;;
    *)
        usage
        ;;
esac

LOG " Lemonade deployment command finished."
