#!/bin/bash
# =====================================================================
# TigerAI Lemonade Test Script
# Path: tests/lemonade-test.sh
# Purpose: Clean install, configure permissions, and manually start lemonade-server
#          to verify GGUF model loading from /home/wrt/TigerAI/models
# =====================================================================

set -e

MODELS_DIR="/home/wrt/TigerAI/models"
# Default to standard install, can be overridden if needed
SNAP_CHANNEL="stable" 

echo -e "\n\033[0;33m[1/4] Cleaning up existing Lemonade installations...\033[0m"
# Remove existing snaps to ensure a clean state
if snap list | grep -q lemonade-server; then
    sudo snap remove lemonade-server
fi
if snap list | grep -q lemonade; then
    sudo snap remove lemonade
fi

echo -e "\n\033[0;32m[2/4] Installing Lemonade Server & Client...\033[0m"
# Install via Snap
sudo snap install lemonade-server
sudo snap install lemonade

echo -e "\n\033[0;34m[3/4] Configuring Permissions...\033[0m"
# IMPORTANT: Connect 'home' plug to allow access to /home/wrt/TigerAI/models
# If the snap doesn't declare this plug, this might fail, but standard lemonade-server usually does.
sudo snap connect lemonade-server:home || echo "Warning: Could not connect 'home' plug. Check snap confinement."
sudo snap connect lemonade-server:removable-media || true
sudo snap connect lemonade-server:network-bind || true

# Stop the systemd service automatically created by snap to prevent port conflict
# and allow us to run it manually in the foreground.
echo "Stopping background snap service..."
sudo snap stop lemonade-server

echo -e "\n\033[0;36m[4/4] Verifying Configuration...\033[0m"

if [ ! -d "$MODELS_DIR" ]; then
    echo -e "\033[0;31m[ERROR] Models directory not found: $MODELS_DIR\033[0m"
    echo "Please ensure the directory exists and contains GGUF models."
    exit 1
else
    echo "✅ Models directory found: $MODELS_DIR"
    ls -lh "$MODELS_DIR" | head -n 5
fi

echo -e "\n\033[1;32m=== Starting Lemonade Server Manually ===\033[0m"
echo "Command: lemonade-server serve --host 0.0.0.0 --extra-models-dir $MODELS_DIR"
echo "----------------------------------------------------------------"
echo "Press Ctrl+C to stop the server."
echo "In another terminal, you can run 'lemonade list' or 'lemonade chat' to test."
echo "----------------------------------------------------------------"

# Run in foreground to show startup messages as requested
lemonade-server serve --host 0.0.0.0 --extra-models-dir "$MODELS_DIR"
