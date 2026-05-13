#!/usr/bin/env bash
# =====================================================================
# TigerAI n8n Deployer
# Path: deployments/amd-compose-stack/04-automation-n8n/deploy.sh
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

LOG_PREFIX="TigerAI n8n"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }
ERROR(){ echo -e "${RED}[$LOG_PREFIX ERROR]${NC} $*"; exit 1; }

usage() {
    echo "Usage: sudo $0 {all | main | worker | down | restart}"
    exit 1
}

# --- 1) Database Schema Check ---
check_db_schema() {
    LOG "🔍 Verifying PostgreSQL Schema for n8n..."
    
    # Check if Postgres container is running
    if ! docker ps --format '{{.Names}}' | grep -qx "$DB_POSTGRESDB_HOST"; then
        ERROR "PostgreSQL container '$DB_POSTGRESDB_HOST' not found. Please deploy infrastructure first."
    fi

    # Create Schema if it doesn't exist
    LOG "Ensuring schema '$DB_POSTGRESDB_SCHEMA' exists in database '$DB_POSTGRESDB_DATABASE'..."
    docker exec -i "$DB_POSTGRESDB_HOST" /usr/bin/env PGPASSWORD="$DB_POSTGRESDB_PASSWORD" psql -U "$DB_POSTGRESDB_USER" -d "$DB_POSTGRESDB_DATABASE" -c "CREATE SCHEMA IF NOT EXISTS $DB_POSTGRESDB_SCHEMA AUTHORIZATION $DB_POSTGRESDB_USER;" || ERROR "Failed to create schema."
    LOG "✅ Schema '$DB_POSTGRESDB_SCHEMA' is ready."
}

# --- 2) Logic ---
[ $# -eq 0 ] && usage

# Auto-detect N8N_URL from hostname if not set in .env
if [ -z "$N8N_URL" ]; then
    N8N_URL="http://$(hostname).local:${N8N_PORT:-5678}"
    LOG "N8N_URL not set, auto-detected: $N8N_URL"
fi
export N8N_URL

# Fallback defaults
DB_POSTGRESDB_HOST=${DB_POSTGRESDB_HOST:-postgres}
DB_POSTGRESDB_USER=${DB_POSTGRESDB_USER:-adm}
DB_POSTGRESDB_PASSWORD=${DB_POSTGRESDB_PASSWORD:-CHANGE_ME}
DB_POSTGRESDB_DATABASE=${DB_POSTGRESDB_DATABASE:-tigerai}
DB_POSTGRESDB_SCHEMA=${DB_POSTGRESDB_SCHEMA:-n8n}
N8N_DIR=${N8N_DIR:-/home/wrt/TigerAI/node/n8n}
FILES_DIR=${FILES_DIR:-/home/wrt/TigerAI/node/n8n/files}

prep_files() {
    LOG " Configuring Directories and Permissions..."
    sudo mkdir -p "$N8N_DIR" "$FILES_DIR"
    sudo chown "${SUDO_USER:-wrt}":"${SUDO_USER:-wrt}" "$(dirname "$N8N_DIR")"
    sudo chown -R 1000:1000 "$N8N_DIR" "$FILES_DIR"
    sudo chmod -R 775 "$N8N_DIR" "$FILES_DIR"
}

ensure_network() {
    docker network inspect ai_stack_net >/dev/null 2>&1 || docker network create ai_stack_net
}

ACTION=$1
prep_files
ensure_network

case "$ACTION" in
    all)
        check_db_schema
        # Use TIGER_N8N_WORKERS if available (from tiger-tuning.env), otherwise use N8N_WORKERS
        WORKER_COUNT=${TIGER_N8N_WORKERS:-${N8N_WORKERS:-2}}
        LOG " Starting n8n Full Stack with $WORKER_COUNT workers..."
        docker compose up -d --scale n8n-worker=$WORKER_COUNT
        LOG "✅ n8n deployed: 1 main + $WORKER_COUNT workers"
        ;;
    main)
        check_db_schema
        LOG " Starting n8n Main only..."
        docker compose up -d n8n-main
        ;;
    worker)
        check_db_schema
        WORKER_COUNT=${TIGER_N8N_WORKERS:-${N8N_WORKERS:-2}}
        LOG " Launching n8n Workflow Engine (Queue Mode) with $WORKER_COUNT workers..."
        docker compose up -d --scale n8n-worker=$WORKER_COUNT
        ;;
    down)
        LOG " Stopping n8n services..."
        docker compose down
        ;;
    restart)
        LOG " Restarting n8n..."
        docker compose down && $0 all
        ;;
    *)
        usage
        ;;
esac

LOG " n8n Deployment command finished."
