#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"
PARAMS_FILE="${PARAMS_FILE:?Set PARAMS_FILE to parameters.commercial.json or parameters.government.json.}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-vyos-peering-$(date +%Y%m%d%H%M%S)}"
DEPLOYMENT_LOCATION="${DEPLOYMENT_LOCATION:-eastus2}"
az account show >/dev/null 2>&1 || az login >/dev/null
az deployment tenant validate --name "$DEPLOYMENT_NAME" --location "$DEPLOYMENT_LOCATION" --template-file "$TEMPLATE_FILE" --parameters @"$PARAMS_FILE"
az deployment tenant create --name "$DEPLOYMENT_NAME" --location "$DEPLOYMENT_LOCATION" --template-file "$TEMPLATE_FILE" --parameters @"$PARAMS_FILE"
