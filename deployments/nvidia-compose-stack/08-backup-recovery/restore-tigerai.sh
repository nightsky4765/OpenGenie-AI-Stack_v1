#!/usr/bin/env bash
# =====================================================================
# TigerAI Data Restoration Tool (P1 Tier)
# Path: deployments/08-backup-recovery/restore-tigerai.sh
# =====================================================================

set -eo pipefail

# --- 0) Configuration ---
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

BACKUP_ROOT=${BACKUP_ROOT:-"/opt/tigerai/backups"}
NODERED_DATA=${NODERED_DATA:-"/root/.node-red"}

LOG_PREFIX="TigerAI Restore"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }
WARN(){ echo -e "${YELLOW}[$LOG_PREFIX WARN]${NC} $*"; }
ERROR(){ echo -e "${RED}[$LOG_PREFIX ERROR]${NC} $*"; exit 1; }

usage() {
    echo "Usage: sudo $0 [backup_date_folder] {all | db | nodered | data}"
    echo "Example: sudo $0 20260202_120000 all"
    echo ""
    echo "Available backups in $BACKUP_ROOT:"
    ls -1 "$BACKUP_ROOT" 2>/dev/null || echo "  (None found)"
    exit 1
}

# --- Validation ---
[ "$(id -u)" -ne 0 ] && ERROR "Please run with sudo."
[ $# -lt 2 ] && usage

RESTORE_DIR="${BACKUP_ROOT:-"/opt/tigerai/backups"}/$1"
TARGET=$2

[ ! -d "$RESTORE_DIR" ] && ERROR "Backup directory $RESTORE_DIR does not exist."

# --- 1) Restore Database ---
restore_db() {
    local file="${RESTORE_DIR}/database.sql.gz"
    LOG " [1/3] Restoring PostgreSQL Database..."
    if [ -f "$file" ]; then
        if docker ps | grep -q "$PG_CONTAINER"; then
            LOG "Dropping and re-creating database $PG_DB_NAME..."
            docker exec "$PG_CONTAINER" dropdb -U "$PG_USER" --if-exists "$PG_DB_NAME"
            docker exec "$PG_CONTAINER" createdb -U "$PG_USER" "$PG_DB_NAME"
            LOG "Importing data from $file..."
            gunzip -c "$file" | docker exec -i "$PG_CONTAINER" psql -U "$PG_USER" "$PG_DB_NAME"
            LOG " Database restoration complete."
        else
            ERROR "PostgreSQL container ($PG_CONTAINER) is not running."
        fi
    else
        WARN "Database backup file not found in $RESTORE_DIR."
    fi
}

# --- 2) Restore Node-RED ---
restore_nodered() {
    local file="${RESTORE_DIR}/nodered_config.tar.gz"
    LOG " [2/3] Restoring Node-RED Configurations..."
    if [ -f "$file" ]; then
        sudo systemctl stop nodered || true
        sudo mkdir -p "$NODERED_DATA"
        sudo tar -xzf "$file" -C "$NODERED_DATA"
        sudo systemctl start nodered
        LOG " Node-RED restoration complete and service restarted."
    else
        WARN "Node-RED backup file not found."
    fi
}

# --- 3) Restore Data Directories ---
restore_data() {
    LOG " [3/3] Restoring Application Data Volumes..."
    # Note: Requires services to be stopped for safety
    WARN "This will overwrite existing data in $DATA_DIRS. Services should be stopped."
    
    for file in "${RESTORE_DIR}"/data_*.tar.gz; do
        if [ -f "$file" ]; then
            # Extract folder name from data_NAME.tar.gz
            local base_name=$(basename "$file" .tar.gz)
            local folder_name="${base_name#data_}"
            local target_path="/opt/tigerai/${folder_name}"
            
            LOG "Restoring $folder_name to $target_path..."
            sudo mkdir -p "$target_path"
            sudo tar -xzf "$file" -C "$target_path"
        fi
    done
    LOG " Data volumes restoration complete."
}

# --- Execution ---
LOG " Starting restoration from $RESTORE_DIR..."

case "$TARGET" in
    all)
        restore_db
        restore_nodered
        restore_data
        ;;
    db)
        restore_db
        ;;
    nodered)
        restore_nodered
        ;;
    data)
        restore_data
        ;;
    *)
        usage
        ;;
esac

LOG " Restoration Process Finished."
