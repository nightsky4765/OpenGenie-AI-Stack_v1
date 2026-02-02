# TigerAI Open-AI-Stack：企業級私有 AI 基礎設施

![專案分級](https://img.shields.io/badge/分級-P1_Mission_Critical-red)
![商務狀態](https://img.shields.io/badge/商務-Commercial_Ready-blue)
![支援硬體](https://img.shields.io/badge/供應鏈-NVIDIA_|_AMD_|_ARM64-green)

TigerAI Open-AI-Stack 是一套專為企業、邊緣運算 (Edge) 與高資安需求環境設計的 **AI-as-a-Product** 交付框架。本系統整合了從硬體感知道商業授權的全流程邏輯，旨在將分散的開源組件轉化為可規模交付、具備商業防禦力的私有化 AI 產品。

---

## 🏗️ 核心架構：12 層級方法論 (12-Phase Methodology)

本專案採用嚴格的層級解耦設計，確保系統的穩定性與擴充性：

1.  **HWI 評估 (Phase 00)**：自動感知硬體體質並進行效能調優。
2.  **系統底座 (Phase 00)**：驅動、Docker 及原生隱形管理特工 (Node-RED)。
3.  **基礎建設 (Phase 01)**：容器編排與遠端管理介面。
4.  **數據中心 (Phase 02)**：硬化後的 PostgreSQL 17 審計資料庫。
5.  **互動介面 (Phase 03)**：秒回響應 (Always-Ready) 的 AI 聊天介面。
6.  **自動化引擎 (Phase 04)**：企業級分散式任務佇列 (n8n Queue Mode)。
7.  **知識庫管線 (Phase 05)**：RAG 向量檢索與文件解析 (Qdrant/Docling)。
8.  **推論核心 (Phase 06)**：原生高效能推論引擎 (Lemonade)。
9.  **驗證與 QA (Phase 07)**：自動化健康檢查與交付驗收腳本。
10. **災備與維運 (Phase 08-09)**：一鍵備份還原與 MQTT 無人值守告警。
11. **監控與生命週期 (Phase 10-11)**：GPU 實時效能監視與容器更新管理。
12. **商業閘道 (Phase 12)**：**專有 API 橋接、離線授權與時間同步中心。**

---

## 📚 文件指南 (Documentation Index)

專案包含完整的商務與技術文檔，存放於 `docs/` 目錄中：

### 🎯 產品與行銷 (docs/marketing/)
*   **[決策層一頁式 (Executive One-Pager)](./docs/marketing/Executive_One_Pager_v1.1.2.md)**：適合 CEO/GM 快速理解價值與決策。
*   **[產品白皮書 v1.1.3 (Whitepaper)](./docs/marketing/Whitepaper_v1.1.3.md)**：詳盡的產品功能、硬體矩陣與商業競爭力分析。
*   **[技術架構拓樸 (Architecture Topology)](./docs/marketing/Architecture_Topology_v1.1.2.md)**：IT 與資安審核專用，展示數據流與安全邊界。

### 💼 商務與簽約 (docs/commercial/)
*   **[工作說明書 v1.1 (SOW Template)](./docs/commercial/SOW_v1.1_Template.md)**：專業的專案交付範本，含責任分界與驗收標準。
*   **[第三方授權合規附件 (Appendix 02)](./docs/commercial/Appendix_02_OSS_License_v1.1.md)**：法律防禦武器，透過 Customer Pull 模式規避授權風險。
*   **[第三方軟體聲明模板 (Third-Party Notices)](./docs/commercial/THIRD_PARTY_NOTICES_TEMPLATE.md)**：標準的開源組件與授權標註模板。

### 🛠️ 技術對帳單 (Root)
*   **[軟體設計文件 (SDD.md)](./SDD.md)**：最完整的技術架構、端口矩陣與 ISO 對標說明。

---

## 🌟 核心商務特點

*   **離線時間同步 (Offline Time-Sync)**：無網環境下透過簽章指令校時，確保授權不漂移。
*   **授權優雅降級 (Kill-Switch)**：授權到期僅鎖定商業 API，保障底座開源資料可存取。
*   **雙供應商敏捷 (Dual-Vendor)**：同時支援 NVIDIA 與 AMD，解除供應鏈綁定風險。
*   **Always-Ready 體驗**：深度顯存最佳化，解決 AI 首字延遲痛點。

### 🚀 快速部署路徑 (Deployment Paths)
*   **[NVIDIA Stack](./deployments/nvidia-compose-stack/)**：適用於 NVIDIA GPU 環境（Ubuntu/Windows WSL）。
*   **[AMD Stack](./deployments/amd-compose-stack/)**：適用於 AMD ROCm 環境。
*   **[ARM64 Stack](./deployments/arm64-compose-stack/)**：適用於 Apple Silicon (Mac), NVIDIA Jetson, Ampere ARM 伺服器。

---

## ⚙️ 快速啟動 (Quick Start)

1.  **環境初始化**：
    進入對應的堆疊目錄 (NVIDIA/AMD)，執行硬體評估：
    ```bash
    sudo bash master-deploy.sh init
    ```
2.  **全量部署**：
    ```bash
    sudo bash master-deploy.sh all
    ```
3.  **交付驗收**：
    ```bash
    sudo bash master-deploy.sh test
    ```

---

## 🧠 專業技能 (Global Skill)
本專案的開發邏輯已封裝為 [TigerAI Enterprise Stack Methodology](.agent/skills/tigerai-p1-stack/SKILL.md)，確保未來的開發與擴充皆遵循 P1 等級的嚴謹標準。

**TigerAI Engineering**
*追求極致穩定的私有 AI 數位骨幹*
