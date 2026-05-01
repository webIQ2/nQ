#!/usr/bin/env bash
set -euo pipefail
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:?Set SUBSCRIPTION_ID}"
RESOURCE_GROUP="${RESOURCE_GROUP:?Set RESOURCE_GROUP}"
VM_NAME="${VM_NAME:?Set VM_NAME}"
az account show >/dev/null 2>&1 || az login >/dev/null
az account set --subscription "$SUBSCRIPTION_ID"
echo "=== vm summary ==="
az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query '{name:name,power:powerState,privateIps:privateIps,publicIps:publicIps,location:location}' -o json

echo "=== security profile ==="
az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" --query 'securityProfile' -o json

echo "=== cloud probe log ==="
az vm run-command invoke -g "$RESOURCE_GROUP" -n "$VM_NAME" --command-id RunShellScript   --scripts 'sudo cloud-init status --wait || true; echo "--- /var/log/cloud-probe.log ---"; sudo cat /var/log/cloud-probe.log || true'   --query 'value[0].message' -o tsv

echo "=== rerun probes ==="
az vm run-command invoke -g "$RESOURCE_GROUP" -n "$VM_NAME" --command-id RunShellScript   --scripts 'for h in management.azure.com login.microsoftonline.com management.usgovcloudapi.net login.microsoftonline.us; do echo "--- $h ---"; curl -I --max-time 10 https://$h || true; done'   --query 'value[0].message' -o tsv
