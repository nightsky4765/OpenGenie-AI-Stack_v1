#!/usr/bin/env bash
# =====================================================================
# TigerAI NVIDIA & Docker Foundation Installer (RTX 5090 Ready)
# Path: deployments/nvidia-compose-stack/00-system-setup-nvidia-docker/deploy.sh
# =====================================================================

set -eo pipefail

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

# Fallback defaults
NVIDIA_DRIVER_PACKAGE=${NVIDIA_DRIVER_PACKAGE:-"nvidia-driver-580-open"}
NVIDIA_DKMS_PACKAGE=${NVIDIA_DKMS_PACKAGE:-"nvidia-dkms-580"}
NVIDIA_UTILS_PACKAGE=${NVIDIA_UTILS_PACKAGE:-"nvidia-utils-580"}
VM_MAP_COUNT=${VM_MAP_COUNT:-2097152}
NODE_RED_MAX_OLD_SPACE=${NODE_RED_MAX_OLD_SPACE:-"1024"}
NODE_RED_SETTINGS_FILE=${NODE_RED_SETTINGS_FILE:-"/root/.node-red/settings.js"}
NODE_RED_PASS=${NODE_RED_PASS:-"CHANGE_ME"}

LOG_PREFIX="TigerAI Foundation (NVIDIA)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
LOG(){ echo -e "${GREEN}[$LOG_PREFIX INFO]${NC} $*"; }
SKIP(){ echo -e "${BLUE}[$LOG_PREFIX SKIP]${NC} $*"; }
ERROR(){ echo -e "${RED}[$LOG_PREFIX ERROR]${NC} $*"; exit 1; }

# --- 1. NVIDIA Driver (PPA) ---
install_nvidia() {
    LOG " [1/6] Installing NVIDIA Drivers ($NVIDIA_DRIVER_PACKAGE)..."
    
    if command -v nvidia-smi &>/dev/null; then
        SKIP "NVIDIA Driver detected."
    else
        LOG "Adding PPA: graphics-drivers..."
        sudo add-apt-repository -y ppa:graphics-drivers/ppa
        sudo apt update
        
        LOG "Installing Driver Packages..."
        sudo apt install -y "$NVIDIA_DRIVER_PACKAGE" "$NVIDIA_DKMS_PACKAGE" "$NVIDIA_UTILS_PACKAGE"
    fi
}

# --- 2. Docker CE & NVIDIA Container Toolkit ---
install_docker_nvidia() {
    LOG " [2/6] Installing Docker CE & NVIDIA Container Toolkit..."
    
    # 2.1 Docker CE
    if command -v docker &>/dev/null; then
        SKIP "Docker already exists."
    else
        sudo apt update && sudo apt install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl enable --now docker
        sudo usermod -aG docker,render,video "$USER"
    fi

    # 2.2 NVIDIA Container Toolkit
    if dpkg -l | grep -q nvidia-container-toolkit; then
       SKIP "NVIDIA Container Toolkit already installed."
    else
       LOG "Configuring NVIDIA Container Toolkit Repository..."
       curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
       && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
       sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
       sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

       sudo apt-get update
       sudo apt-get install -y nvidia-container-toolkit

       LOG "Generating CDI configuration..."
       sudo nvidia-ctk runtime configure --runtime=docker
       sudo systemctl restart docker
    fi
}

# --- 3. System Performance & Persistence ---
configure_performance() {
    LOG " [3/6] Configuring System Limits (vm.max_map_count)..."
    if ! grep -q "vm.max_map_count=$VM_MAP_COUNT" /etc/sysctl.conf; then
        echo "vm.max_map_count=$VM_MAP_COUNT" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    else
        SKIP "vm.max_map_count already configured."
    fi
}

configure_persistenced() {
    LOG " [4/6] Configuring NVIDIA Persistence Daemon (v1.7) to prevent GPU sleep..."
    
    sudo tee /etc/systemd/system/nvidia-persistenced.service > /dev/null <<EOF
[Unit]
Description=NVIDIA Persistence Daemon (TigerAI v1.7)
After=multi-user.target

[Service]
Type=forking
ExecStartPre=/bin/mkdir -p /var/run/nvidia-persistenced
ExecStartPre=/bin/chown root:root /var/run/nvidia-persistenced
ExecStart=/usr/bin/nvidia-persistenced --user root --verbose
ExecStopPost=/bin/rm -rf /var/run/nvidia-persistenced
PIDFile=/var/run/nvidia-persistenced/nvidia-persistenced.pid
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now nvidia-persistenced.service || true
    LOG " NVIDIA Persistence Daemon enabled."
}

# --- 5. UI and Power Management ---
configure_ui_and_power() {
    LOG " [5/6] Configuring UI & Power Management (Wayland off, No Sleep)..."
    
    # 1. Disable Wayland & Set Xorg
    LOG "Disabling Wayland and setting GNOME Xorg session..."
    sudo sed -i '/^WaylandEnable=/d' /etc/gdm3/custom.conf
    sudo sed -i '/^DefaultSession=/d' /etc/gdm3/custom.conf
    sudo sed -i '/^\[daemon\]/a WaylandEnable=false\nDefaultSession=gnome-xorg.desktop' /etc/gdm3/custom.conf
    
    # 2. GNOME GSettings (Run as the base user)
    LOG "Applying GNOME Power & Screen lock settings..."
    REAL_USER=${SUDO_USER:-$USER}
    sudo -u "$REAL_USER" gsettings set org.gnome.desktop.session idle-delay 0 || true
    sudo -u "$REAL_USER" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' || true
    sudo -u "$REAL_USER" gsettings set org.gnome.desktop.screensaver lock-enabled false || true
}

# --- 6. Node-RED (Stealth Native Installation) ---
install_nodered() {
    LOG " [6/6] Installing Node-RED (Native Mode - Hidden from Portainer)..."
    
    if command -v node-red &>/dev/null; then
        SKIP "Node-RED already exists. Refreshing config..."
    else
        LOG "Executing official Node-RED installation script..."
        bash <(curl -sL https://github.com/node-red/linux-installers/releases/latest/download/update-nodejs-and-nodered-deb) --confirm-root --confirm-install --skip-pi
    fi

    # 1. Performance Optimization
    sudo mkdir -p /etc/systemd/system/nodered.service.d
    echo -e "[Service]\nEnvironment=\"NODE_OPTIONS=--max-old-space-size=$NODE_RED_MAX_OLD_SPACE\"" | sudo tee /etc/systemd/system/nodered.service.d/performance.conf > /dev/null

    # 2. Password Injection (Bypass Admin Init)
    LOG "Injecting Admin Password for Node-RED..."
    TEMP_DIR="/tmp/nr_gen_$(date +%s)"
    mkdir -p "$TEMP_DIR" && pushd "$TEMP_DIR" > /dev/null
    npm init -y >/dev/null 2>&1 && npm install bcryptjs --silent --no-save >/dev/null 2>&1
    HASH=$(node -e "console.log(require('bcryptjs').hashSync('$NODE_RED_PASS', 8))")
    popd > /dev/null && rm -rf "$TEMP_DIR"

    # Ensure settings.js exists
    if [ ! -f "$NODE_RED_SETTINGS_FILE" ]; then
        sudo systemctl start nodered.service && sleep 5 && sudo systemctl stop nodered.service
    fi

    # 3. Modify settings.js
    sudo node -e "
    const fs = require('fs');
    const path = '$NODE_RED_SETTINGS_FILE';
    let c = fs.readFileSync(path, 'utf8');
    c = c.replace(/adminAuth\s*:\s*\{[\s\S]*?\},/g, '');
    const auth = \"\n    adminAuth: { type: 'credentials', users: [{ username: 'admin', password: '$HASH', permissions: '*' }] },\";
    fs.writeFileSync(path, c.replace('module.exports = {', 'module.exports = {' + auth), 'utf8');
    "
    
    sudo systemctl daemon-reload
    sudo systemctl restart nodered.service
    LOG " Node-RED Native Setup & Stealth mode configured."
}

# --- Main Logic ---
[ "$(id -u)" -ne 0 ] && ERROR "Please run with sudo."
install_nvidia
install_docker_nvidia
configure_performance
configure_persistenced
configure_ui_and_power
install_nodered

LOG " System Foundation (NVIDIA RTX 5090 Ready) Setup Complete. Please reboot (sudo reboot)!"
