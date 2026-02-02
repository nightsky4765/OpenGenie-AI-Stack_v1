# Software Design Document (SDD) - TigerAI Open-AI-Stack

## 📝 Document Metadata
*   **Project Name:** Open-AI-Stack (Enterprise & SaaS Edition)
*   **Tier:** P1 (Mission Critical Infrastructure)
*   **Version:** v1.1.0 (Commercial Ready)
*   **Author:** TigerAI Engineering
*   **Methodology:** [TigerAI Enterprise Stack Methodology](.agent/skills/tigerai-p1-stack/SKILL.md)
*   **Last Updated:** 2026-02-02

---

## 1. Executive Summary & Commercial Vision
The TigerAI Open-AI-Stack is a P1-tier (99.9% availability target) private AI infrastructure designed for Edge Computing and SaaS-as-a-Product deployment. 
*   **Base + Plugin Model**: A rock-solid open-source foundation (Phases 00-11) supplemented by a proprietary, license-controlled Commercial Gateway (Phase 12).
*   **Hybrid Connectivity**: Optimized for air-gapped or intermittently connected environments using OTA Time-Sync and Offline Token validation.

---

## 2. Hardware Intelligence (HWI) Advisor
Calibration is mandatory before deployment via `./00-pre-flight-advisor/tiger-advisor.sh` within each stack directory:
*   **Architecture Agility**: Automatically detects X86_64, ARM64 (Apple Silicon/Blackwell), or AMD ROCm.
*   **Conservative (Default)**: 50% CPU threads, 2 n8n workers. Stability priority.
*   **Balanced**: 75% CPU threads, 5 n8n workers. Optimized for multi-user workloads.
*   **Optimal**: 100% CPU threads, 10 n8n workers. Max throughput for heavy RAG/OCR pipelines.

---

## 3. 12-Phase Architecture (Modular Decomposition)
| Phase | Layer | Name | Core Components | Commercial Value |
| :--- | :--- | :--- | :--- | :--- |
| **00** | Advisor | HWI Advisor | ./00-pre-flight-advisor/ | Initial hardware calibration and profile generation. |
| **00** | System | Foundation | ./00-system-setup-*/ | Architecture-specific driver and foundation setup. |
| **01** | Infra | Infrastructure | ./01-infra-*/ | Secure orchestration visibility (Portainer/WebSSH). |
| **02** | DB | Database | ./02-database-*/ | Hardened PostgreSQL 17 audit persistence. |
| **03** | Chat | AI Interface | ./03-ai-interface-*/ | High-speed interactive LLM experience. |
| **04** | Auto | Automation | ./04-automation-*/ | Enterprise workflow engine (n8n). |
| **05** | RAG | Knowledge Base | ./05-rag-stack-*/ | Vector storage and document processing. |
| **06** | Core | AI Core Engine | ./06-ai-core-*/ | Native inference engines. |
| **07** | Test | Validation | ./07-validation-stack/ | Automated QA and delivery verification. |
| **08** | Backup | Disaster Recovery| ./08-backup-recovery/ | 1-Click backup and timestamped restore. |
| **09** | Alert | Proactive Mon | ./09-monitoring-alerting/ | MQTT-based alarm escalation and notification. |
| **10** | Ops | Observability | ./10-observability-*/ | GPU telemetry and SLA performance dashboards. |
| **11** | Life | Lifecycle | ./11-lifecycle-wud/ | Controlled container updates and versioning. |
| **12** | SaaS | Commercial Gwy | ./12-commercial-*/ | **SaaS connection, license management & OTA sync.** |

---

## 4. Service Port Matrix
| Layer | Service | Host Port | Commercial Exposure |
| :--- | :--- | :--- | :--- |
| 00 | Node-RED (Native) | **1880** | Internal Admin (Stealth) |
| 12 | Commercial Gateway | **8000** | **Public/Customer API Access Point** |
| 03 | OpenWebUI | **8080** | Internal Interactive UI |
| 10 | Grafana | **3000** | Admin Performance Dashboard |
| 11 | WUD (Lifecycle) | **3838** | Admin Update Manager |
| 01 | Portainer | **9000** | Admin Container Manager |

---

## 5. Commercial OTA & License Management
### A. Offline Time Synchronization
Since many deployment units are air-gapped, standard NTP is unreliable. 
*   **Mechanism**: The `ota-sync.sh` agent extracts high-precision timestamps from signed OTA commands and executes `hwclock` synchronization.
*   **Impact**: Ensures subscription expiry logic (TTL) remains accurate without internet access.

### B. The Kill-Switch (License Enforcement)
*   **Control Agent**: Native Node-RED listens to authorized MQTT signals.
*   **Enforcement**: On license expiry, Node-RED executes `docker stop system-api-bridge`.
*   **Graceful Degradation**: Foundation layers (Ollama/n8n) remain available for basic open-source use, but proprietary "Product Features" (Phase 12 API) are locked.

---

## 6. Enterprise Reliability (HA & Maintenance)
### A. High Availability (HA Ready)
*   **Keepalived Support**: All endpoint checks utilize the `TARGET_HOST` variable for VIP fail-over.
*   **Stateless Scaling**: AI Inference layers (03, 06, 12) are stateless, supporting Nginx/F5 load balancing.
*   **Persistent Data**: DB layers are pre-configured for Primary-Replica streaming (WAL level: logical).

### B. Automated Maintenance
*   **04:00 AM**: Version check (WUD).
*   **05:00 AM**: VRAM Purge (Phase 08) ensures 100% GPU memory clearing and engine refresh for peak morning performance.

---

## 7. ISO Standards Alignment (ISO 標準對齊)
The TigerAI Open-AI-Stack architecture is designed to support enterprise-grade compliance audits:

### A. ISO/IEC 27001 (Information Security Management)
*   **A.12 Operations Security**: Automated backups (Phase 08) and comprehensive monitoring (Phase 10).
*   **A.13 Network Security**: Air-gapped readiness, Port Matrix isolation, and Docker Socket Proxy.
*   **A.18 Compliance**: 100% data sovereignty; all processing remains within local infrastructure.

### B. ISO/IEC 42001 (Artificial Intelligence Management)
*   **AI Life Cycle**: 12-Phase structured methodology from calibration to decommissioning.
*   **Transparency**: Detailed SDD and audit logs in Phase 02 (PostgreSQL).
*   **Risk Management**: Real-time GPU telemetry and performance warning thresholds.

### C. ISO/IEC 27701 (Privacy Information Management)
*   **Data Residency**: Zero-cloud dependency ensures no PII (Personally Identifiable Information) leaves the premises.
*   **Auditability**: Complete request/response logging capabilities for AI interactions.