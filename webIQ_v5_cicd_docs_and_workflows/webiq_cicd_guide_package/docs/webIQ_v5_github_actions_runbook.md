# webIQ `webIQ_clean_hubspoke_v5` GitHub Actions deployment runbook

## Goal
Deploy, validate, and destroy the proven VyOS one-click baseline (`webIQ_clean_hubspoke_v5`) from GitHub Actions using Azure federated identity (OIDC), with approval gates for destructive actions.

## What to correct in the sample workflow you shared

Your current sample is a good learning start, but it has four problems for production use:

1. The workflow YAML is malformed. The line `- uses: actions/checkout@v4 {` is invalid YAML, and the ARM JSON templates are embedded directly inside the workflow file instead of being stored as separate files.
2. It uses `Azure/Login@v1` with `creds: ${{ secrets.AZURE_CREDENTIALS }}`. Prefer `azure/login@v2` with OIDC so you do not keep a long-lived client secret in GitHub.
3. It mixes a subscription-scope resource-group deployment and a separate resource-group deployment for a sample storage account, which is fine for learning ARM, but it is unrelated to the current VyOS delivery.
4. It does not separate deploy and destroy, and it does not use GitHub Environments or required reviewers for destructive work.

## Recommended repository layout

```text
repo-root/
  .github/
    workflows/
      deploy-vyos-v5.yml
      destroy-vyos-v5.yml
  infra/
    webIQ_clean_hubspoke_v5/
      vyos/
        oneclick/
          main.bicep
          parameters.webiq.json
          deploy.sh
          decommission.sh
          validate.sh
      shared/            # only if you later move to modularized repo layout
  docs/
    webIQ_v5_github_actions_runbook.md
```

## GitHub prerequisites

Create these repository or environment secrets/variables:

### Environment: `lab`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID` (use `7426560d-ace3-4e95-9df4-69985fb9d8cc` only as the default login subscription; the Bicep itself still targets the hub/commercial/government subscriptions from the parameter file)
- `NVA_ADMIN_PASSWORD`
- `ADMIN_SOURCE_PREFIX` (for example `203.0.113.10/32`)
- `TEST_VM_SSH_PUBLIC_KEY`

### Environment: `destroy`
Same as `lab`, but protect this environment with required reviewers.

## Parameter values to keep for the proven v5 baseline

These are the subscription targets already proven in successful runs:
- Hub subscription: `7426560d-ace3-4e95-9df4-69985fb9d8cc` (`webIQ Infrastructure`)
- Commercial spoke subscription: `ff60f646-9751-4074-9f58-9fc310105c4c` (`netIQ`)
- Government spoke subscription: `1011dd77-657c-4c57-931b-0b77b92e7378` (`Gi (Government Issue)`)

Do not change those for the first CI/CD baseline.

## Required edit to `parameters.webiq.json`

Do **not** hardcode secrets into the repo. Keep the non-secret values in the file, but set these at workflow time:
- `adminSourcePrefix`
- `nvaAdminPassword`
- `testVmSshPublicKey`

Recommended pattern:
1. Commit a repo-safe parameter file with placeholders.
2. In the workflow, copy it to a temporary file.
3. Use `jq` to inject the three secret values.

## Deploy workflow behavior

The deploy workflow should:
1. Check out code.
2. Log in with OIDC using `azure/login@v2`.
3. Confirm Bicep/CLI are available.
4. Build a temporary parameter file with injected secret values.
5. Run tenant-scope deployment with the one-click Bicep.
6. Run `validate.sh`.
7. Run guest-level smoke tests using `az vm run-command invoke`.

## Destroy workflow behavior

The destroy workflow should:
1. Require approval by using the `destroy` GitHub Environment.
2. Log in with OIDC.
3. Run `decommission.sh`.
4. Optionally verify the three resource groups no longer exist.

## First-time manual test before enabling pipeline

From a workstation or Cloud Shell, verify the repo contents and Bicep are correct:

```bash
cd infra/webIQ_clean_hubspoke_v5/vyos/oneclick
az bicep build --file main.bicep
```

If build succeeds, the repo is structurally ready.

## First deploy from GitHub Actions

1. Push the repo to `main`.
2. Open **Actions**.
3. Run `deploy-vyos-v5` manually.
4. Confirm these success criteria:
   - deployment state is `Succeeded`
   - VyOS hub VM is running
   - both test VMs are running
   - commercial VM can reach government VM
   - government VM can reach commercial VM
   - both VMs can reach `management.azure.com` and `management.usgovcloudapi.net`

## Validation commands

These are the same smoke tests used during prior successful validation:

```bash
az vm run-command invoke \
  -g rg-netiq-vyos-commercial \
  -n vm-commercial-test \
  --subscription ff60f646-9751-4074-9f58-9fc310105c4c \
  --command-id RunShellScript \
  --scripts "ping -c 3 10.62.1.4; curl -I -sS https://management.azure.com; curl -I -sS https://management.usgovcloudapi.net"

az vm run-command invoke \
  -g rg-gi-vyos-government \
  -n vm-government-test \
  --subscription 1011dd77-657c-4c57-931b-0b77b92e7378 \
  --command-id RunShellScript \
  --scripts "ping -c 3 10.61.1.4; curl -I -sS https://management.azure.com; curl -I -sS https://management.usgovcloudapi.net"
```

## Suggested delivery path

### Phase 1
Freeze the proven one-click baseline in GitHub Actions using the two workflows in this package.

### Phase 2
After the one-click pipeline is stable, migrate to the modular VyOS pipeline using the repo skeleton already prepared earlier.

### Phase 3
After modular VyOS is green, repeat the same CI/CD design for vSRX.
