# Contributing to OpenGenie-AI-Stack

Thank you for your interest in contributing! Please follow the guidelines below.

---

## Getting Started

1. **Fork** this repository
2. **Clone** your fork locally
3. Create a new branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```

---

## Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feat/<name>` | `feat/arm64-ollama` |
| Bug fix | `fix/<name>` | `fix/n8n-migration-race` |
| Hotfix | `hotfix/<name>` | `hotfix/lemonade-version` |
| Docs | `docs/<name>` | `docs/amd-setup` |

---

## Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short description>

[optional body]
```

**Types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`

**Scopes:** `amd`, `nvidia`, `arm64`, `n8n`, `openwebui`, `lemonade`, `apisix`, `observability`

Examples:
```
feat(amd): add ROCm 6.2 support
fix(n8n): serialize worker deployment to avoid migration race
chore: remove obsolete config audit reports
```

---

## Submitting a Pull Request

1. Make sure your branch is up to date with `main`
2. Test your changes on the relevant stack (AMD / NVIDIA / ARM64)
3. Push your branch and open a PR against `main`
4. Fill in the PR template — include what changed and how to test it
5. A maintainer will review within a few business days

---

## Stack Testing

Before submitting, verify your changes against the relevant deployment stack:

```bash
# AMD
./deployments/amd-compose-stack/reinstall-all.sh

# NVIDIA
./deployments/nvidia-compose-stack/reinstall-all.sh

# ARM64
./deployments/arm64-compose-stack/reinstall-all.sh
```

---

## Reporting Issues

Use the [issue templates](.github/ISSUE_TEMPLATE/) to report bugs or request features.
