# TigerAI Node-RED System Installation

## ⚠️ 重要說明
Node-RED 是作為 **系統服務 (systemd)** 安裝，**不是 Docker 容器**。

這是刻意的設計選擇，原因：
1. 更好的系統整合能力
2. 直接訪問系統資源
3. 作為系統服務更穩定
4. 可以直接使用系統的 Node.js 環境

## 🚀 安裝

### 基本安裝（使用預設密碼）
```bash
cd deployments/amd-compose-stack/07-automation-nodered/
sudo ./install.sh install
```

### 自訂密碼安裝
```bash
sudo ./install.sh install --password your_password
```

## 📝 管理指令

```bash
# 查看服務狀態
sudo ./install.sh status

# 重啟服務
sudo ./install.sh restart

# 查看即時日誌
sudo ./install.sh logs
```

## 🔧 系統整合

### Systemd 服務
- **服務名稱**: `nodered.service`
- **設定檔**: `/root/.node-red/settings.js`
- **效能配置**: `/etc/systemd/system/nodered.service.d/performance.conf`

### 直接使用 systemctl
```bash
sudo systemctl status nodered
sudo systemctl restart nodered
sudo systemctl stop nodered
sudo journalctl -u nodered -f
```

## 🌐 訪問

- **URL**: http://localhost:1880
- **預設帳號**: admin
- **預設密碼**: CHANGE_ME

## 🔧 效能優化

自動配置：
- `--max-old-space-size=1024` (針對 56T CPU 系統)
- Systemd service 優化

## 🔐 安全建議

1. 首次登入後立即修改密碼
2. 考慮使用反向代理 (nginx) 加上 HTTPS
3. 限制網路訪問範圍

## 📚 資源

- [Node-RED 官方文檔](https://nodered.org/docs/)
- [Node 目錄](https://flows.nodered.org/)
