#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"
PARAMS_FILE="${PARAMS_FILE:-$SCRIPT_DIR/parameters.webiq.json}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-vsrx-oneclick-$(date +%Y%m%d%H%M%S)}"
DEPLOYMENT_LOCATION="${DEPLOYMENT_LOCATION:-eastus2}"
HUB_SUBSCRIPTION_ID="${HUB_SUBSCRIPTION_ID:-7426560d-ace3-4e95-9df4-69985fb9d8cc}"
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519.pub}"

: "${NVA_ADMIN_PASSWORD:?Set NVA_ADMIN_PASSWORD before running this script.}"
: "${ADMIN_SOURCE_PREFIX:?Set ADMIN_SOURCE_PREFIX to your public IP/CIDR, for example 203.0.113.10/32.}"

if [[ ! -f "$SSH_KEY_FILE" ]]; then
  echo "SSH public key not found: $SSH_KEY_FILE" >&2
  exit 1
fi

TEST_VM_SSH_PUBLIC_KEY="${TEST_VM_SSH_PUBLIC_KEY:-$(cat "$SSH_KEY_FILE")}" 

az account show >/dev/null 2>&1 || az login >/dev/null
az account set --subscription "$HUB_SUBSCRIPTION_ID"
az vm image terms accept --publisher "Juniper Networks" --offer "vSRX Virtual Firewall-next-generation-firewall" --plan "vSRX Virtual Firewall-byol-azure-image" >/dev/null

az deployment tenant validate   --name "$DEPLOYMENT_NAME"   --location "$DEPLOYMENT_LOCATION"   --template-file "$TEMPLATE_FILE"   --parameters @"$PARAMS_FILE"   --parameters nvaAdminPassword="$NVA_ADMIN_PASSWORD" adminSourcePrefix="$ADMIN_SOURCE_PREFIX" testVmSshPublicKey="$TEST_VM_SSH_PUBLIC_KEY"

az deployment tenant create   --name "$DEPLOYMENT_NAME"   --location "$DEPLOYMENT_LOCATION"   --template-file "$TEMPLATE_FILE"   --parameters @"$PARAMS_FILE"   --parameters nvaAdminPassword="$NVA_ADMIN_PASSWORD" adminSourcePrefix="$ADMIN_SOURCE_PREFIX" testVmSshPublicKey="$TEST_VM_SSH_PUBLIC_KEY"
