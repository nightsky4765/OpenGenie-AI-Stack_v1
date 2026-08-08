# OpenGenie AI Stack v2.0.1

本版本僅用於在 Fork repository 驗證 tag push 能否自動觸發 Release workflow，不包含任何程式、部署或設定變更。

## What's Changed

- 新增純文件測試版本，驗證 `v*` tag push 自動建立 GitHub Release。

**Full Changelog**: [v2.0.0 baseline...v2.0.1](https://github.com/nightsky4765/OpenGenie-AI-Stack_v1/compare/a87452855f46cf4fdf2f1140a1f536dc7e6a9543...v2.0.1)

## Release Details

### Test Scope

- 驗證 GitHub Actions 能從 tag 指向的 commit 讀取 `.github/workflows/release.yml`。
- 驗證 workflow 能讀取 `docs/v2.0.1/RELEASE-NOTE.md` 並建立 Release。
- 本版本沒有 runtime、container、database 或 deployment 行為變更。
