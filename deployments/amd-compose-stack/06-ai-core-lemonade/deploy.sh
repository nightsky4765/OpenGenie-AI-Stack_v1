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
  # Prevent leaking variables from parent shell if they are commented out in local .env
  grep -q "^LLM_MODEL=" .env || unset LLM_MODEL
  grep -q "^EMBED_MODEL=" .env || unset EMBED_MODEL
fi

# Then import from parent stack .env (overrides local, with CRLF handling)
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | sed 's/\r//g' | xargs)
  # Prevent leaking variables from parent shell if they are commented out in parent .env
  grep -q "^LLM_MODEL=" ../.env || unset LLM_MODEL
  grep -q "^EMBED_MODEL=" ../.env || unset EMBED_MODEL
fi

LOG_PREFIX="TigerAI Lemonade"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }
ERROR(){ echo -e "${RED}[$LOG_PREFIX ERROR]${NC} $*"; exit 1; }

usage() {
    echo "Usage: sudo $0 {all | install | config | status | restart | edu | rag | purge}"
    echo "  all     : Install + Configure"
    echo "  purge   : ⚠️ COMPLETE UNINSTALL"
    echo "  restart : Restart all services"
    echo "  edu/rag : Switch modes"
    exit 1
}

[ $# -eq 0 ] && usage

# Fallback defaults
BASE_DIR=${BASE_DIR:-/opt/tigerai/lemonade}
MODELS_DIR=${MODELS_DIR:-$BASE_DIR/models}
LOG_DIR=${LOG_DIR:-/var/log/lemonade}
USER_NAME=${USER_NAME:-${SUDO_USER:-root}}
LEMONADE_API_KEY=${LEMONADE_API_KEY:-}
# Optional PPA version pin (e.g. "10.0.1~24.04"). Empty = latest available in PPA.
LEMONADE_PPA_VERSION=${LEMONADE_PPA_VERSION:-}

# --- 1) Installation (PPA) ---
install_lemonade() {
    LOG " Installing Lemonade via PPA..."
    if ! grep -q "lemonade-team/stable" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        sudo add-apt-repository -y ppa:lemonade-team/stable
    fi
    sudo apt-get update -qq
    if [ -n "$LEMONADE_PPA_VERSION" ]; then
        # Superseded versions are removed from the PPA apt index but the .deb
        # files remain downloadable from Launchpad directly. Always fetch the
        # pinned .deb from Launchpad to guarantee exact version, regardless of
        # whether it's still the "current" Published build.
        local DEB_FILE="lemonade-server_${LEMONADE_PPA_VERSION}_amd64.deb"
        local DEB_URL="https://launchpad.net/~lemonade-team/+archive/ubuntu/stable/+files/${DEB_FILE}"
        local DEB_PATH="/tmp/${DEB_FILE}"
        LOG " Pinning Lemonade to ${LEMONADE_PPA_VERSION} via Launchpad .deb..."
        sudo curl -fSL -o "$DEB_PATH" "$DEB_URL" || ERROR "Failed to download $DEB_URL"
        dpkg-deb --info "$DEB_PATH" >/dev/null 2>&1 || { sudo rm -f "$DEB_PATH"; ERROR "Downloaded file is not a valid .deb"; }
        sudo apt-get install -y --allow-downgrades "$DEB_PATH"
        sudo apt-mark hold lemonade-server
        sudo rm -f "$DEB_PATH"
    else
        sudo apt-mark unhold lemonade-server 2>/dev/null || true
        sudo apt-get install -y lemonade-server
    fi
    LOG " Lemonade installed via PPA."
}

# --- 2) Configuration & Service Setup ---
configure_services() {
    LOG " Configuring Lemonade Services (EDU, RAG, EMBED)..."
    
    # Model paths are now full paths from .env (matching src)
    local AUTO_THREADS=${TIGER_CPU_THREADS:-16}

    # --- 2.1) Nuclear Clean (Force Stop & Reset) ---
    LOG " Performing Nuclear Clean (Stop & Reset)..."
    sudo systemctl stop lemonade-server lemonade-edu lemonade-rag lemonade-embed || true
    sudo systemctl disable lemonade-server || true
    sudo pkill -9 lemonade-server || true
    sudo rm -rf /tmp/lemonade*
    sudo systemctl reset-failed
    
    sudo mkdir -p "${MODELS_DIR}" "${LOG_DIR}"
    sudo chown -R ${USER_NAME}:${USER_NAME} "${BASE_DIR}"
    sleep 2

    # --- 2.2) Pre-flight Check ---
    LOG " Checking directories..."
    
    local LEMONADE_BIN=$(command -v lemonade-server || echo "/usr/local/bin/lemonade-server")
    LOG " Detected lemonade-server at: ${LEMONADE_BIN}"

    # A. EDU Service (Port 8800)
    cat <<EOF | sudo tee /etc/systemd/system/lemonade-edu.service > /dev/null
[Unit]
Description=TigerAI Lemonade - EDU
After=network.target

[Service]
Type=simple
User=root
PrivateTmp=true
LimitMEMLOCK=infinity
TasksMax=4096
Environment=LEMONADE_API_KEY=${LEMONADE_API_KEY}
Environment=GGML_VULKAN_DEVICE=${GGML_VULKAN_DEVICE_EDU}
Environment=LEMONADE_EXTRA_MODELS_DIR=${MODELS_DIR}
ExecStart=${LEMONADE_BIN} serve --host 0.0.0.0 --port 8800 --extra-models-dir ${MODELS_DIR} --ctx-size 81920 --llamacpp vulkan --llamacpp-args "--flash-attn on --threads ${AUTO_THREADS} --parallel 28 --tensor-split 1,1 --cache-type-k q8_0 --cache-type-v q8_0"
StandardOutput=append:${LOG_DIR}/edu.log
StandardError=append:${LOG_DIR}/edu.log
Restart=always
RestartSec=15
[Install]
WantedBy=multi-user.target
EOF

    # B. RAG Service (Port 8801)
    cat <<EOF | sudo tee /etc/systemd/system/lemonade-rag.service > /dev/null
[Unit]
Description=TigerAI Lemonade - RAG
After=network.target

[Service]
Type=simple
User=root
PrivateTmp=true
LimitMEMLOCK=infinity
TasksMax=4096
Environment=LEMONADE_API_KEY=${LEMONADE_API_KEY}
Environment=GGML_VULKAN_DEVICE=${GGML_VULKAN_DEVICE_RAG}
Environment=LEMONADE_EXTRA_MODELS_DIR=${MODELS_DIR}
ExecStart=${LEMONADE_BIN} serve --host 0.0.0.0 --port 8801 --extra-models-dir ${MODELS_DIR} --ctx-size 131072 --llamacpp vulkan --llamacpp-args "--flash-attn on --threads ${AUTO_THREADS} --parallel 2 --tensor-split 3,1 --cache-type-k q8_0 --cache-type-v q8_0"
StandardOutput=append:${LOG_DIR}/rag.log
StandardError=append:${LOG_DIR}/rag.log
Restart=always
RestartSec=15
[Install]
WantedBy=multi-user.target
EOF

    # C. EMBED Service (Port 8802)
    cat <<EOF | sudo tee /etc/systemd/system/lemonade-embed.service > /dev/null
[Unit]
Description=TigerAI Lemonade - EMBED Daemon
After=network.target

[Service]
Type=simple
User=root
PrivateTmp=true
LimitMEMLOCK=infinity
Environment=LEMONADE_API_KEY=${LEMONADE_API_KEY}
Environment=GGML_VULKAN_DEVICE=${GGML_VULKAN_DEVICE_EMBED}
Environment=LEMONADE_EXTRA_MODELS_DIR=${MODELS_DIR}
ExecStart=${LEMONADE_BIN} serve --host 0.0.0.0 --port 8802 --extra-models-dir ${MODELS_DIR} --ctx-size 8192 --llamacpp vulkan --llamacpp-args "--flash-attn on --threads 8"
StandardOutput=append:${LOG_DIR}/embed.log
StandardError=append:${LOG_DIR}/embed.log
Restart=always
[Install]
WantedBy=multi-user.target
EOF

    # D. Mode Switching Scripts
    cat <<EOF | sudo tee /usr/local/bin/tiger-mode-edu > /dev/null
#!/usr/bin/env bash
sudo systemctl stop lemonade-rag
sudo systemctl reset-failed
sleep 3
sudo systemctl restart lemonade-embed
sleep 5
sudo systemctl restart lemonade-edu
echo ">> [TigerAI] 教學模式已就緒 (8800 + 8802)"
EOF

    cat <<EOF | sudo tee /usr/local/bin/tiger-mode-rag > /dev/null
#!/usr/bin/env bash
sudo systemctl stop lemonade-edu
sudo systemctl reset-failed
sleep 3
sudo systemctl restart lemonade-embed
sleep 5
sudo systemctl restart lemonade-rag
echo ">> [TigerAI] 研究模式已就緒 (8801 + 8802)"
EOF

    # E. 全域狀態檢查指令 (補強模型偵測)
    cat <<EOF | sudo tee /usr/local/bin/tiger-status > /dev/null
#!/usr/bin/env bash
echo -e "\033[0;34m===== [TigerAI Lemonade 核心服務狀態] =====\033[0m"
systemctl status lemonade-embed lemonade-edu lemonade-rag --no-pager | grep -E "●|Active:|Process:|Main PID:"
echo -e "\n\033[0;36m[模型文件偵測]\033[0m"
[ -f "${LLM_MODEL}" ] && echo -e "✅ LLM 模型: 存在" || echo -e "❌ LLM 模型: 遺失 (${LLM_MODEL})"
[ -f "${EMBED_MODEL}" ] && echo -e "✅ Embed 模型: 存在" || echo -e "❌ Embed 模型: 遺失 (${EMBED_MODEL})"
echo -e "\033[0;34m===========================================\033[0m"
EOF

    sudo chmod +x /usr/local/bin/tiger-mode-edu /usr/local/bin/tiger-mode-rag /usr/local/bin/tiger-status

    LOG " Reloading systemd and enabling services..."
    sudo systemctl daemon-reload
    sudo systemctl enable lemonade-embed lemonade-rag lemonade-edu
    
    LOG " Granting hardware permissions..."
    # Ensure user is in render/video groups for Vulkan/GPU access
    sudo usermod -aG render,video $USER || true
    LOG " Hardware permissions updated. (Effect takes place after next login or systemctl restart)"
    
    # E. Logrotate Configuration
    LOG " Configuring Logrotate for Lemonade logs..."
    sudo tee /etc/logrotate.d/lemonade > /dev/null <<ROT
${LOG_DIR}/*.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
ROT
    LOG " Configuration complete. Use 'tiger-mode-rag' to start research mode."
}

# --- 3) Logic Execution ---
[ "$(id -u)" -ne 0 ] && ERROR "Please run with sudo."

case "$1" in
    all)
        install_lemonade
        configure_services
        ;;
    install)
        install_lemonade
        ;;
    config)
        configure_services
        ;;
    status)
        systemctl status lemonade-edu lemonade-rag lemonade-embed --no-pager || true
        ;;
    restart)
        LOG " Restarting all Lemonade services..."
        sudo systemctl restart lemonade-embed lemonade-edu lemonade-rag
        LOG "✅ Services restarted."
        ;;
    edu)
        LOG " Switching to EDU Mode..."
        /usr/local/bin/tiger-mode-edu
        ;;
    rag)
        LOG " Switching to RAG Mode..."
        /usr/local/bin/tiger-mode-rag
        ;;
    purge)
        LOG " ⚠️ Starting FULL PURGE..."
        sudo systemctl stop lemonade-server lemonade-edu lemonade-rag lemonade-embed || true
        sudo systemctl disable lemonade-server lemonade-edu lemonade-rag lemonade-embed || true
        sudo rm -f /etc/systemd/system/lemonade-*.service
        sudo systemctl daemon-reload
        sudo systemctl reset-failed
        
        LOG " Uninstalling Snap packages..."
        sudo snap remove lemonade-server || true
        sudo snap remove lemonade || true
        
        LOG " Removing Global Commands & Links..."
        sudo rm -f /usr/local/bin/tiger-mode-edu /usr/local/bin/tiger-mode-rag /usr/local/bin/tiger-status
        sudo rm -rf /tmp/lemonade*
        
        LOG "✅ System is now CLEAN. You can reinstall using 'sudo ./deploy.sh all'."
        ;;
    *)
        usage
        ;;
esac

LOG " Lemonade command finished."
