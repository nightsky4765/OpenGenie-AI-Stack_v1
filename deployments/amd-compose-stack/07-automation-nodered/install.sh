#!/usr/bin/env bash
# =====================================================================
# TigerAI Node-RED System Installer
# Path: deployments/amd-compose-stack/07-automation-nodered/install.sh
# =====================================================================
# Note: Node-RED is intentionally installed as a SYSTEM SERVICE,
# not as a Docker container, for better system integration.
# =====================================================================

set -eo pipefail

# --- Configuration ---
NODE_RED_MAX_OLD_SPACE="1024"
NODE_RED_SETTINGS_FILE="/root/.node-red/settings.js"
DEFAULT_PASSWORD="CHANGE_ME"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[TigerAI Node-RED]${NC} $*"; }
WARN(){ echo -e "${YELLOW}[TigerAI Node-RED]${NC} $*"; }
ERROR(){ echo -e "${RED}[TigerAI Node-RED]${NC} $*"; exit 1; }

usage() {
    echo -e "${BLUE}Usage: sudo $0 {install|status|restart|logs} [--password <pass>]${NC}"
    echo ""
    echo "Commands:"
    echo "  install   - Install Node-RED as system service"
    echo "  status    - Check Node-RED service status"
    echo "  restart   - Restart Node-RED service"
    echo "  logs      - View Node-RED logs"
    echo ""
    echo "Options:"
    echo "  --password <pass>  - Set admin password (default: CHANGE_ME)"
    exit 1
}

check_root() {
    [ "$EUID" -ne 0 ] && ERROR "請使用 sudo 執行此腳本"
}

install_nodered() {
    local PASS=$1
    LOG "--- [部署 Node-RED] ---"
    
    if command -v node-red &> /dev/null; then
        WARN "偵測到 Node-RED 已安裝，僅更新設定與優化參數。"
    else
        LOG "正在執行官方安裝腳本..."
        bash <(curl -sL https://github.com/node-red/linux-installers/releases/latest/download/update-nodejs-and-nodered-deb) --confirm-root --confirm-install --skip-pi
    fi

    # 效能優化注入
    LOG "配置效能優化參數 (max-old-space-size=${NODE_RED_MAX_OLD_SPACE}MB)..."
    sudo mkdir -p /etc/systemd/system/nodered.service.d
    echo -e "[Service]\nEnvironment=\"NODE_OPTIONS=--max-old-space-size=$NODE_RED_MAX_OLD_SPACE\"" | sudo tee /etc/systemd/system/nodered.service.d/performance.conf > /dev/null

    # 密碼注入 (Bypass Admin Init)
    LOG "正在注入管理員密碼 (Hash Generation)..."
    TEMP_DIR="/tmp/nr_gen_$(date +%s)"
    mkdir -p "$TEMP_DIR" && pushd "$TEMP_DIR" > /dev/null
    npm init -y > /dev/null 2>&1 && npm install bcryptjs --silent --no-save > /dev/null 2>&1
    HASH=$(node -e "console.log(require('bcryptjs').hashSync('$PASS', 8))")
    popd > /dev/null && rm -rf "$TEMP_DIR"

    if [ ! -f "$NODE_RED_SETTINGS_FILE" ]; then
        LOG "初始化 Node-RED 設定檔..."
        sudo systemctl start nodered.service && sleep 5 && sudo systemctl stop nodered.service
    fi

    LOG "注入管理員認證設定..."
    sudo node -e "
    const fs = require('fs');
    const path = '$NODE_RED_SETTINGS_FILE';
    let c = fs.readFileSync(path, 'utf8');
    c = c.replace(/adminAuth\\s*:\\s*\\{[\\s\\S]*?\\},/g, '');
    const auth = \"\\n    adminAuth: { type: 'credentials', users: [{ username: 'admin', password: '$HASH', permissions: '*' }] },\";
    fs.writeFileSync(path, c.replace('module.exports = {', 'module.exports = {' + auth), 'utf8');
    "
    
    sudo systemctl daemon-reload
    sudo systemctl enable nodered.service
    sudo systemctl restart nodered.service
    
    LOG "✅ Node-RED 安裝與設定完成！"
    LOG "   訪問地址: http://localhost:1880"
    LOG "   管理帳號: admin"
    LOG "   管理密碼: $PASS"
}

show_status() {
    LOG "--- Node-RED 服務狀態 ---"
    sudo systemctl status nodered.service --no-pager
}

restart_service() {
    LOG "重啟 Node-RED 服務..."
    sudo systemctl restart nodered.service
    LOG "✅ 重啟完成"
}

show_logs() {
    LOG "顯示 Node-RED 日誌 (Ctrl+C 退出)..."
    sudo journalctl -u nodered.service -f
}

# --- Main Logic ---
[ $# -eq 0 ] && usage
check_root

ACTION=""
PASSWORD="$DEFAULT_PASSWORD"

while [[ $# -gt 0 ]]; do
    case "$1" in
        install|status|restart|logs) ACTION="$1"; shift ;;
        --password) PASSWORD="$2"; shift 2 ;;
        *) shift ;;
    esac
done

case "$ACTION" in
    install) install_nodered "$PASSWORD" ;;
    status) show_status ;;
    restart) restart_service ;;
    logs) show_logs ;;
    *) usage ;;
esac
