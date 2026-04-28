# webIQ VyOS v5 CI/CD Recovery Package

This package restores the files needed to deploy, validate, and destroy the proven `webIQ_clean_hubspoke_v5` baseline from GitHub Actions.

## Contents
- `.github/workflows/deploy-vyos-v5.yml`
- `.github/workflows/destroy-vyos-v5.yml`
- `infra/webIQ_clean_hubspoke_v5/...`
- `docs/webIQ_v5_github_actions_runbook.md`
- `scripts/create-webiq-repo-layout.ps1`
- `scripts/create-webiq-repo-layout.sh`

## Intended repo layout
```text
repo-root/
  .github/workflows/
  docs/
  infra/webIQ_clean_hubspoke_v5/
  scripts/
```
