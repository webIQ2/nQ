#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"
PARAMS_FILE="${PARAMS_FILE:-$SCRIPT_DIR/parameters.webiq.json}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-vsrx-hub-$(date +%Y%m%d%H%M%S)}"
DEPLOYMENT_LOCATION="${DEPLOYMENT_LOCATION:-eastus2}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-7426560d-ace3-4e95-9df4-69985fb9d8cc}"
: "${NVA_ADMIN_PASSWORD:?Set NVA_ADMIN_PASSWORD before running this script.}"
: "${ADMIN_SOURCE_PREFIX:?Set ADMIN_SOURCE_PREFIX to your public IP/CIDR.}"
az account show >/dev/null 2>&1 || az login >/dev/null
az account set --subscription "$SUBSCRIPTION_ID"
az vm image terms accept --publisher "Juniper Networks" --offer "vSRX Virtual Firewall-next-generation-firewall" --plan "vSRX Virtual Firewall-byol-azure-image" >/dev/null
az deployment sub validate --name "$DEPLOYMENT_NAME" --location "$DEPLOYMENT_LOCATION" --template-file "$TEMPLATE_FILE" --parameters @"$PARAMS_FILE" --parameters nvaAdminPassword="$NVA_ADMIN_PASSWORD" adminSourcePrefix="$ADMIN_SOURCE_PREFIX"
az deployment sub create --name "$DEPLOYMENT_NAME" --location "$DEPLOYMENT_LOCATION" --template-file "$TEMPLATE_FILE" --parameters @"$PARAMS_FILE" --parameters nvaAdminPassword="$NVA_ADMIN_PASSWORD" adminSourcePrefix="$ADMIN_SOURCE_PREFIX"
