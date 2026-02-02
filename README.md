# TigerAI Open-AI-Stack: Enterprise Private AI Infrastructure

[**中文版本說明 (README_zh.md)**](./README_zh.md)

![Project Tier](https://img.shields.io/badge/Tier-P1_Mission_Critical-red)
![SaaS](https://img.shields.io/badge/Business-OTA_SaaS_Ready-blue)
![GPU](https://img.shields.io/badge/Vendor-AMD_|_NVIDIA_|_ARM64-green)

TigerAI Open-AI-Stack is a highly modular, professional-grade private AI deployment framework. It transforms standard hardware into a **SaaS-Ready AI Appliance**, supporting Over-The-Air (OTA) management, subscription-based licensing, and mission-critical reliability.

---

## 🏗️ 12-Layer Methodology (12 層級方法論)
Deployment is orchestrated through a 12-Phase structured methodology:

1.  **HWI Advisor**: Pre-flight calibration & NVIDIA/AMD agility.
2.  **Foundation**: Native **Stealth Admin Agent (Node-RED)** for OTA control.
3.  **Infrastructure**: Orchestration visibility (Portainer/WebSSH).
4.  **Data Core**: Hardened PostgreSQL 17 audit persistence.
5.  **Interactive AI**: Real-time **Always-Ready** Chat (Ollama/WebUI).
6.  **Automation**: Enterprise Workflow Queue (n8n).
7.  **Knowledge Base**: RAG Pipeline & Vector Storage (Qdrant/Docling).
8.  **Inference Core**: Native Performance Engines (Lemonade).
9.  **Validation**: Automated QA & Health-check scripts.
10. **DR & Backup**: 1-Click Backup & Maintenance (VRAM Purge).
11. **SLA Monitoring**: Proactive Health Checks (Grafana/MQTT).
12. **Commercial Gateway**: **Proprietary SaaS Bridge & OTA License Controller.**

---

## � Documentation Index (文件索引)

### 🎯 Marketing & Decision Making (產品與行銷)
*   **[Executive One-Pager](./docs/marketing/Executive_One_Pager_v1.1.2.md)**: Ideal for CEO/GM to understand value quickly.
*   **[Product Whitepaper v1.1.3](./docs/marketing/Whitepaper_v1.1.3.md)**: Detailed features, hardware matrix, and competitive edge.
*   **[Architecture Topology](./docs/marketing/Architecture_Topology_v1.1.2.md)**: For IT/Security review of data flow and boundaries.

### 💼 Commercial & Legal (商務與簽約)
*   **[SOW v1.1 Template](./docs/commercial/SOW_v1.1_Template.md)**: Professional Statement of Work with clear boundaries.
*   **[Appendix 02: OSS Compliance](./docs/commercial/Appendix_02_OSS_License_v1.1.md)**: Legal shield using "Customer Pull" delivery model.
*   **[Third-Party Notices Template](./docs/commercial/THIRD_PARTY_NOTICES_TEMPLATE.md)**: Standard attribution template for open-source dependencies.

### ⚙️ Technical Reference (技術總覽)
*   **[Software Design Document (SDD)](./SDD.md)**: Port matrix, service mapping, and ISO standards alignment.

---

### 🚀 快速部署路徑 (Deployment Paths)
*   **[NVIDIA Stack](./deployments/nvidia-compose-stack/)**：適用於 NVIDIA GPU 環境（Ubuntu/Windows WSL）。
*   **[AMD Stack](./deployments/amd-compose-stack/)**：適用於 AMD ROCm 環境。
*   **[ARM64 Stack](./deployments/arm64-compose-stack/)**：適用於 Apple Silicon (Mac), NVIDIA Jetson, Ampere ARM Servers。

## 🔧 Enterprise Features
*   **Offline Time-Sync**: Correct hardware clock drift in air-gapped environments via signed OTA tokens.
*   **License Kill-Switch**: Remotely lock proprietary API layers while keeping OSS layers accessible.
*   **Dual-Vendor Agility**: Native support for both NVIDIA (CUDA) and AMD (ROCm).
*   **Self-Healing**: Automated 5:00 AM VRAM purging ensures long-term stability.

## 🧑‍💻 Business & Engineering Contact
**TigerAI Morris Lu** / Lead Architect  
*Project Category: P1 Edge AI Appliance*