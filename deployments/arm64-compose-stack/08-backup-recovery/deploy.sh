#!/usr/bin/env bash
# =====================================================================
# TigerAI Backup/Recovery Module Initializer
# Path: deployments/arm64-compose-stack/08-backup-recovery/deploy.sh
# =====================================================================

set -eo pipefail

LOG_PREFIX="TigerAI Backup/Recovery"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

LOG "Initializing Backup/Recovery scripts..."

chmod +x backup-tigerai.sh restore-tigerai.sh setup-cron.sh vram-purge.sh

LOG "✅ Backup/Recovery module ready."
