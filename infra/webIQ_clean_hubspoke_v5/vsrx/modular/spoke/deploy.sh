#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"
PARAMS_FILE="${PARAMS_FILE:?Set PARAMS_FILE to parameters.netiq.json or parameters.gi.json.}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-vyos-spoke-$(date +%Y%m%d%H%M%S)}"
DEPLOYMENT_LOCATION="${DEPLOYMENT_LOCATION:-eastus2}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:?Set SUBSCRIPTION_ID to the target spoke subscription.}"
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519.pub}"
: "${ADMIN_SOURCE_PREFIX:?Set ADMIN_SOURCE_PREFIX to your public IP/CIDR.}"
if [[ ! -f "$SSH_KEY_FILE" ]]; then
  echo "SSH public key not found: $SSH_KEY_FILE" >&2
  exit 1
fi
TEST_VM_SSH_PUBLIC_KEY="${TEST_VM_SSH_PUBLIC_KEY:-$(cat "$SSH_KEY_FILE")}" 
az account show >/dev/null 2>&1 || az login >/dev/null
az account set --subscription "$SUBSCRIPTION_ID"
az deployment sub validate --name "$DEPLOYMENT_NAME" --location "$DEPLOYMENT_LOCATION" --template-file "$TEMPLATE_FILE" --parameters @"$PARAMS_FILE" --parameters testVmSshPublicKey="$TEST_VM_SSH_PUBLIC_KEY" adminSourcePrefix="$ADMIN_SOURCE_PREFIX"
az deployment sub create --name "$DEPLOYMENT_NAME" --location "$DEPLOYMENT_LOCATION" --template-file "$TEMPLATE_FILE" --parameters @"$PARAMS_FILE" --parameters testVmSshPublicKey="$TEST_VM_SSH_PUBLIC_KEY" adminSourcePrefix="$ADMIN_SOURCE_PREFIX"
