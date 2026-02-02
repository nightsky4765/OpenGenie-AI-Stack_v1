#!/usr/bin/env bash
# =====================================================================
# TigerAI Validation Module Initializer
# Path: deployments/amd-compose-stack/07-validation-stack/deploy.sh
# =====================================================================

set -eo pipefail

LOG_PREFIX="TigerAI Validation"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

LOG "Initializing Validation scripts..."

chmod +x check-health.sh

LOG "✅ Validation module ready. Run './check-health.sh' to verify stack."
