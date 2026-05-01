#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
TEMPLATE_FILE="$ROOT_DIR/shared/ops/test-vm-only.bicep"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-ff60f646-9751-4074-9f58-9fc310105c4c}"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-netiq-vyos-commercial}"
LOCATION="${LOCATION:-eastus2}"
VNET_NAME="${VNET_NAME:-vnet-netiq-commercial}"
SUBNET_NAME="${SUBNET_NAME:-WorkloadSubnet}"
VM_NAME="${VM_NAME:-vm-commercial-test}"
VM_SIZE="${VM_SIZE:-Standard_D2s_v3}"
DEPLOY_PUBLIC_IP="${DEPLOY_PUBLIC_IP:-false}"
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519.pub}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-commercial-testvm-$(date +%Y%m%d%H%M%S)}"
: "${ADMIN_SOURCE_PREFIX:?Set ADMIN_SOURCE_PREFIX to your public IP/CIDR, for example 203.0.113.10/32.}"
if [[ ! -f "$SSH_KEY_FILE" ]]; then echo "SSH public key not found: $SSH_KEY_FILE" >&2; exit 1; fi
SSH_KEY=$(<"$SSH_KEY_FILE")
SUBNET_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${VNET_NAME}/subnets/${SUBNET_NAME}"
az account show >/dev/null 2>&1 || az login >/dev/null
az account set --subscription "$SUBSCRIPTION_ID"
az deployment group validate -g "$RESOURCE_GROUP" -n "$DEPLOYMENT_NAME" --template-file "$TEMPLATE_FILE"   --parameters vmName="$VM_NAME" subnetId="$SUBNET_ID" sshPublicKey="$SSH_KEY" vmSize="$VM_SIZE"                deployPublicIp="$DEPLOY_PUBLIC_IP" adminSourcePrefix="$ADMIN_SOURCE_PREFIX"                tags='{"owner":"webIQ","lane":"commercial","role":"test-vm","nvaVendor":"VyOS"}'
az deployment group create -g "$RESOURCE_GROUP" -n "$DEPLOYMENT_NAME" --template-file "$TEMPLATE_FILE"   --parameters vmName="$VM_NAME" subnetId="$SUBNET_ID" sshPublicKey="$SSH_KEY" vmSize="$VM_SIZE"                deployPublicIp="$DEPLOY_PUBLIC_IP" adminSourcePrefix="$ADMIN_SOURCE_PREFIX"                tags='{"owner":"webIQ","lane":"commercial","role":"test-vm","nvaVendor":"VyOS"}'
