#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [[ ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "webiq-cloudshell" >/dev/null
fi
MYIP=$(curl -fsS https://ifconfig.me)
export ADMIN_SOURCE_PREFIX="${ADMIN_SOURCE_PREFIX:-${MYIP}/32}"
export SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519.pub}"
: "${NVA_ADMIN_PASSWORD:?Set NVA_ADMIN_PASSWORD before running this script.}"
chmod +x ./deploy.sh ./validate.sh ./decommission.sh
./deploy.sh
