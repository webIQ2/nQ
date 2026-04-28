#!/usr/bin/env bash
set -euo pipefail
HUB_SUB="${HUB_SUB:-7426560d-ace3-4e95-9df4-69985fb9d8cc}"
COMM_SUB="${COMM_SUB:-ff60f646-9751-4074-9f58-9fc310105c4c}"
GOV_SUB="${GOV_SUB:-1011dd77-657c-4c57-931b-0b77b92e7378}"
HUB_RG="${HUB_RG:-rg-webiq-vyos-hub}"
COMM_RG="${COMM_RG:-rg-netiq-vyos-commercial}"
GOV_RG="${GOV_RG:-rg-gi-vyos-government}"
WAIT="${WAIT:-true}"

delete_rg(){
  local sub="$1" rg="$2"
  az account set --subscription "$sub"
  if [[ "$(az group exists -n "$rg" -o tsv || echo false)" == "true" ]]; then
    echo "Deleting $rg in $sub"
    mapfile -t locks < <(az lock list -g "$rg" --query '[].id' -o tsv 2>/dev/null || true)
    for lockid in "${locks[@]}"; do
      [[ -n "$lockid" ]] && az lock delete --ids "$lockid" >/dev/null || true
    done
    az group delete -n "$rg" --yes --force-deletion-types Microsoft.Compute/virtualMachines
    if [[ "$WAIT" == "true" ]]; then
      until [[ "$(az group exists -n "$rg" -o tsv || echo false)" == "false" ]]; do
        echo "Waiting for $rg to be deleted..."
        sleep 20
      done
    fi
  else
    echo "Resource group $rg not found in $sub"
  fi
}
az account show >/dev/null 2>&1 || az login >/dev/null
delete_rg "$COMM_SUB" "$COMM_RG"
delete_rg "$GOV_SUB" "$GOV_RG"
delete_rg "$HUB_SUB" "$HUB_RG"
