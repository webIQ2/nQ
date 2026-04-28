# webIQ VyOS v5 GitHub Actions runbook

## Goal
Deploy, validate, and destroy the proven `webIQ_clean_hubspoke_v5` baseline from GitHub Actions.

## Repository layout
```text
repo-root/
  .github/workflows/
  docs/
  infra/webIQ_clean_hubspoke_v5/
  scripts/
```

## Why this replaces the old lab
The old repo was organized for a storage-account ARM lab. This package replaces it with the proven VyOS v5 deployment baseline.

## Required GitHub environments
Create these GitHub Environments:
- `lab`
- `destroy`

Protect `destroy` with required reviewers.

## Required environment secrets
### lab
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `ADMIN_SOURCE_PREFIX`
- `NVA_ADMIN_PASSWORD`
- `TEST_VM_SSH_PUBLIC_KEY`

### destroy
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

## Azure permissions required
The GitHub OIDC identity must have rights in these subscriptions:
- `7426560d-ace3-4e95-9df4-69985fb9d8cc` (`webIQ Infrastructure`)
- `ff60f646-9751-4074-9f58-9fc310105c4c` (`netIQ`)
- `1011dd77-657c-4c57-931b-0b77b92e7378` (`Gi (Government Issue)`)

## What the deploy workflow does
1. Checks out the repo.
2. Logs into Azure with OIDC.
3. Builds a temporary parameter file from `parameters.webiq.json`.
4. Injects `ADMIN_SOURCE_PREFIX`, `NVA_ADMIN_PASSWORD`, and `TEST_VM_SSH_PUBLIC_KEY` from secrets.
5. Runs `az deployment tenant validate`.
6. Runs `az deployment tenant create`.
7. Runs `validate.sh`.
8. Runs two smoke tests from inside the commercial and government VMs.

## First-time local file placement
You can use either helper script in `scripts/` to create the repo layout from a workstation.

## Manual smoke tests
```bash
az vm run-command invoke   -g rg-netiq-vyos-commercial   -n vm-commercial-test   --subscription ff60f646-9751-4074-9f58-9fc310105c4c   --command-id RunShellScript   --scripts "ping -c 3 10.62.1.4; curl -I -sS https://management.azure.com; curl -I -sS https://management.usgovcloudapi.net"

az vm run-command invoke   -g rg-gi-vyos-government   -n vm-government-test   --subscription 1011dd77-657c-4c57-931b-0b77b92e7378   --command-id RunShellScript   --scripts "ping -c 3 10.61.1.4; curl -I -sS https://management.azure.com; curl -I -sS https://management.usgovcloudapi.net"
```
