#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"
PARAMS_FILE="${PARAMS_FILE:-$SCRIPT_DIR/parameters.webiq.json}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-vyos-oneclick-$(date +%Y%m%d%H%M%S)}"
DEPLOYMENT_LOCATION="${DEPLOYMENT_LOCATION:-eastus2}"
HUB_SUBSCRIPTION_ID="${HUB_SUBSCRIPTION_ID:-7426560d-ace3-4e95-9df4-69985fb9d8cc}"
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519.pub}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

require_cmd az
require_cmd ssh-keygen
require_cmd python3

if [[ ! -f "$SSH_KEY_FILE" ]]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "webiq-cloudshell" >/dev/null
  SSH_KEY_FILE="$HOME/.ssh/id_ed25519.pub"
fi

TEST_VM_SSH_PUBLIC_KEY="${TEST_VM_SSH_PUBLIC_KEY:-$(cat "$SSH_KEY_FILE")}" 
: "${NVA_ADMIN_PASSWORD:?Set NVA_ADMIN_PASSWORD before running this script.}"

if [[ -z "${ADMIN_SOURCE_PREFIX:-}" ]]; then
  MYIP=$(curl -fsS https://ifconfig.me || true)
  if [[ -z "$MYIP" ]]; then
    echo "Set ADMIN_SOURCE_PREFIX to your public IP/CIDR, for example 203.0.113.10/32." >&2
    exit 1
  fi
  ADMIN_SOURCE_PREFIX="${MYIP}/32"
fi

if [[ "$ADMIN_SOURCE_PREFIX" == *YOUR.PUBLIC.IP* || "$ADMIN_SOURCE_PREFIX" == *'/32/32'* ]]; then
  echo "Invalid ADMIN_SOURCE_PREFIX: $ADMIN_SOURCE_PREFIX" >&2
  exit 1
fi

az account show >/dev/null 2>&1 || az login >/dev/null
az account set --subscription "$HUB_SUBSCRIPTION_ID"

TERMS_ACCEPTED=$(az vm image terms show   --publisher "sentriumsl"   --offer "vyos-1-2-lts-on-azure"   --plan "vyos-1-3"   --query accepted -o tsv 2>/dev/null || echo "false")

if [[ "$TERMS_ACCEPTED" == "true" ]]; then
  echo "VyOS Marketplace terms already accepted in this subscription. Skipping accept step."
else
  echo "VyOS Marketplace terms not yet accepted. Attempting acceptance..."
  az vm image terms accept --publisher "sentriumsl" --offer "vyos-1-2-lts-on-azure" --plan "vyos-1-3" >/dev/null
fi

echo "Validating deployment $DEPLOYMENT_NAME"
az deployment tenant validate \
  --name "$DEPLOYMENT_NAME" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters @"$PARAMS_FILE" \
  --parameters nvaAdminPassword="$NVA_ADMIN_PASSWORD" adminSourcePrefix="$ADMIN_SOURCE_PREFIX" testVmSshPublicKey="$TEST_VM_SSH_PUBLIC_KEY"

echo "Creating deployment $DEPLOYMENT_NAME"
az deployment tenant create \
  --name "$DEPLOYMENT_NAME" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters @"$PARAMS_FILE" \
  --parameters nvaAdminPassword="$NVA_ADMIN_PASSWORD" adminSourcePrefix="$ADMIN_SOURCE_PREFIX" testVmSshPublicKey="$TEST_VM_SSH_PUBLIC_KEY"
