#!/usr/bin/env bash
# =====================================================================
# TigerAI OTA Time & License Sync Agent (Stealth Native)
# Path: deployments/12-commercial-gateway/ota-sync.sh
# =====================================================================

# Usage: ./ota-sync.sh "2026-02-02 12:00:00" "ACTIVE"

SYNC_TIME=$1
STATUS=$2

LOG_PREFIX="TigerAI OTA"
GREEN='\033[0;32m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }

[ "$(id -u)" -ne 0 ] && echo "Need sudo" && exit 1

# 1.  ()
if [ ! -z "$SYNC_TIME" ]; then
    LOG " Syncing system time via OTA command: $SYNC_TIME"
    date -s "$SYNC_TIME"
    # 
    hwclock -w || true
fi

# 2.  ( FastAPI )
if [ "$STATUS" == "EXPIRED" ]; then
    LOG " License Expired. Shutting down commercial services..."
    #  API 
    docker stop system-api-bridge || true
else
    LOG " License Valid. Ensuring gateway is running..."
    cd "$(dirname "$0")"
    docker compose up -d
fi

LOG " OTA Command Processed Successfully."
