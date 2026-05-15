# OpenGenie AI Deployment: Full Purge Procedure

## Purpose
This skill covers the complete teardown of the OpenGenie stack and all its dependencies (Docker, NVIDIA drivers, volumes, configs).
Use this during training loops or when a completely clean reinstall is required.

**Trigger phrase:** User says `"full purge and reinstall"` or deployment is broken beyond recovery.

---

## Phase 1: Stop All Running Containers
Navigate to the detected stack directory first, then stop all compose services:

```bash
cd deployments/<STACK_DIR>
sudo ./master-deploy.sh clean
```

If `master-deploy.sh clean` fails (Docker daemon is broken), force-remove containers manually:
```bash
docker ps -aq | xargs docker rm -f 2>/dev/null || true
```

---

## Phase 2: Remove Docker Volumes (Data Wipe — Scoped to This Stack Only)
This permanently deletes all database data, AI model caches, and configuration volumes **owned by this stack**. Volumes from unrelated Docker projects on the same host are NOT touched.

```bash
# From deployments/<STACK_DIR>/ — iterate every numbered module and let compose
# remove only the volumes it created (matched by its own compose project label).
for dir in [0-9][0-9]-*/; do
  [ -d "$dir" ] || continue
  ( cd "$dir" && sudo docker compose down -v 2>/dev/null || true )
done

# Belt-and-braces sweep: remove any leftover volumes still labeled as belonging
# to this stack's compose projects (label name = the module directory name).
for dir in [0-9][0-9]-*/; do
  proj="${dir%/}"
  docker volume ls --filter "label=com.docker.compose.project=${proj}" -q \
    | xargs -r docker volume rm 2>/dev/null || true
done
```

> ⚠️ This is irreversible. Only do this if a full fresh install is intended.
> 🛡️ **Safety:** Never run `docker volume ls -q | xargs docker volume rm` — that nukes volumes belonging to unrelated Docker projects on the same machine.

---

## Phase 3: Purge Docker Completely

```bash
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get autoremove -y
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
sudo rm -f /usr/local/bin/docker-compose
```

Verify Docker is gone:
```bash
command -v docker && echo "DOCKER_STILL_PRESENT" || echo "DOCKER_REMOVED_OK"
```

---

## Phase 4: Purge NVIDIA Drivers (if reinstalling GPU stack)

```bash
sudo apt-get purge -y '*nvidia*'
sudo apt-get purge -y '*cuda*'
sudo apt-get autoremove -y
sudo apt-get autoclean
```

Remove leftover NVIDIA container toolkit configs:
```bash
sudo rm -f /etc/docker/daemon.json
sudo rm -rf /etc/nvidia-container-runtime
```

Verify drivers are gone:
```bash
dpkg -l | grep -i nvidia && echo "NVIDIA_PKGS_STILL_PRESENT" || echo "NVIDIA_REMOVED_OK"
```

---

## Phase 5: Clean Project State Files

Reset the agent's memory so the next invocation starts from `PRISTINE`:

```bash
# $PROJECT_ROOT should already be set per 00-master-orchestrator.md §2.0.
# If not, run the locator block from there first.
rm -f "$PROJECT_ROOT/.agent-state.json"
rm -f "$PROJECT_ROOT/deployments/nvidia-compose-stack/00-pre-flight-advisor/tiger-tuning.env"
rm -f "$PROJECT_ROOT/deployments/amd-compose-stack/00-pre-flight-advisor/tiger-tuning.env"
rm -f "$PROJECT_ROOT/deployments/arm64-compose-stack/00-pre-flight-advisor/tiger-tuning.env"
```

---

## Phase 6: Reboot to Clear Kernel Modules

```bash
sudo reboot
```

**STOP and print this exact message to the user:**

---
🧹 **Full purge complete. The system is clean.**

The machine is rebooting to clear all kernel modules.

After restart:
1. SSH back into the machine.
2. Start a new conversation and say: **"start fresh installation"**

I will start the fresh installation from the beginning.

---

---

## Post-Purge Verification (Run after reboot, before reinstalling)

```bash
# These should ALL return "not found" / errors — confirming a clean slate
command -v docker && echo "DOCKER_FOUND (unexpected)" || echo "Docker: clean ✅"
command -v nvidia-smi && echo "NVIDIA_SMI_FOUND (unexpected)" || echo "NVIDIA SMI: clean ✅"
ls /var/lib/docker 2>/dev/null && echo "Docker data still exists (unexpected)" || echo "Docker data: clean ✅"
```

Only proceed with reinstall if all three show clean.
