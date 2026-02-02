#!/usr/bin/env bash
# =====================================================================
# TigerAI n8n Deployer
# Path: deployments/amd-compose-stack/04-automation-n8n/deploy.sh
# =====================================================================

set -eo pipefail

# --- 0) Configuration & Variables ---
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

# And global root .env (highest priority overrides)
if [ -f ../../.env ]; then
  export $(grep -v '^#' ../../.env | sed 's/\r//g' | xargs)
fi

# Robust Variable Cleansing (Against Windows CRLF)
for var in $(env | grep -E 'PORT|IMAGE|URL|PATH|USER|PASS|DB|SECRET|TZ|LANG' | cut -d= -f1); do
  export "$var"="$(echo "${!var}" | tr -d '\r')"
done

LOG_PREFIX="TigerAI n8n"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }
ERROR(){ echo -e "${RED}[$LOG_PREFIX ERROR]${NC} $*"; exit 1; }

usage() {
    echo "Usage: sudo $0 {all | main | worker}"
    exit 1
}

[ $# -eq 0 ] && usage

prep_files() {
    LOG " Configuring Directories and Permissions..."
    local N8N_DIR="${N8N_DIR:-/home/wrt/TigerAI/node/n8n}"
    local FILES_DIR="${FILES_DIR:-/home/wrt/TigerAI/node/n8n/files}"
    sudo mkdir -p "$N8N_DIR" "$FILES_DIR"
    sudo chown -R 1000:1000 "$N8N_DIR" "$FILES_DIR"
    sudo chmod -R 775 "$N8N_DIR" "$FILES_DIR"
}

ensure_network() {
    docker network inspect ai_stack_net >/dev/null 2>&1 || docker network create ai_stack_net
}

check_db_schema() {
    LOG "🔍 Verifying PostgreSQL connection and Schema..."
    
    # Check if Postgres container is running
    local PG_HOST_NAME="${DB_POSTGRESDB_HOST:-postgres}"
    if ! docker ps --format '{{.Names}}' | grep -q "^${PG_HOST_NAME}$"; then
        ERROR "Database container '${PG_HOST_NAME}' not found. Please start 02-database stack first."
    fi

    local TARGET_SCHEMA="${DB_POSTGRESDB_SCHEMA:-n8n}"
    local PG_USER="${DB_POSTGRESDB_USER:-adm}"
    local PG_DB_NAME="${DB_POSTGRESDB_DATABASE:-tigerai}"

    # Check and Create Schema
    SCHEMA_EXISTS=$(docker exec -i "$PG_HOST_NAME" psql -U "$PG_USER" -d "$PG_DB_NAME" -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name = '$TARGET_SCHEMA';")
    
    if [ "$SCHEMA_EXISTS" != "1" ]; then
        LOG "⚠️  Schema '$TARGET_SCHEMA' does not exist. Creating it now..."
        docker exec -i "$PG_HOST_NAME" psql -U "$PG_USER" -d "$PG_DB_NAME" -c "CREATE SCHEMA IF NOT EXISTS $TARGET_SCHEMA AUTHORIZATION $PG_USER;"
        LOG "✅ Schema '$TARGET_SCHEMA' created successfully."
    else
        LOG "✅ Schema '$TARGET_SCHEMA' already exists."
    fi
}

ACTION=$1
prep_files
ensure_network

case "$ACTION" in
    all)
        check_db_schema
        LOG " Starting n8n Full Stack..."
        docker compose up -d
        ;;
    main)
        check_db_schema
        LOG " Starting n8n Main only..."
        docker compose up -d n8n-main
        ;;
    worker)
        LOG " Launching n8n Workflow Engine (Queue Mode)..."
#  Advisor 
export N8N_CONCURRENCY=${TIGER_N8N_WORKERS:-5}
docker compose up -d n8n-worker-01
        ;;
    *)
        usage
        ;;
esac

LOG " n8n Deployment command finished."
