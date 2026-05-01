#!/usr/bin/env bash
set -euo pipefail
HUB_SUB="${HUB_SUB:-7426560d-ace3-4e95-9df4-69985fb9d8cc}"
COMM_SUB="${COMM_SUB:-ff60f646-9751-4074-9f58-9fc310105c4c}"
GOV_SUB="${GOV_SUB:-1011dd77-657c-4c57-931b-0b77b92e7378}"

az account show >/dev/null 2>&1 || az login >/dev/null

echo '=== VyOS hub ==='
az account set --subscription "$HUB_SUB"
az vm show -d -g rg-webiq-vyos-hub -n vyos-hub --query '{power:powerState,privateIps:privateIps,publicIps:publicIps}' -o yaml

echo '=== Commercial VM ==='
az account set --subscription "$COMM_SUB"
az vm show -d -g rg-netiq-vyos-commercial -n vm-commercial-test --query '{power:powerState,privateIps:privateIps,publicIps:publicIps}' -o yaml

echo '=== Government VM ==='
az account set --subscription "$GOV_SUB"
az vm show -d -g rg-gi-vyos-government -n vm-government-test --query '{power:powerState,privateIps:privateIps,publicIps:publicIps}' -o yaml
