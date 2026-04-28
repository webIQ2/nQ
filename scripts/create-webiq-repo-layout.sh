#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="${1:-}"
SOURCE_ROOT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
if [[ -z "$REPO_ROOT" ]]; then
  echo "usage: $0 <repo-root> [source-root]" >&2
  exit 1
fi
mkdir -p "$REPO_ROOT"
find "$REPO_ROOT" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
mkdir -p "$REPO_ROOT/.github/workflows" "$REPO_ROOT/docs" "$REPO_ROOT/infra" "$REPO_ROOT/scripts"
cp "$SOURCE_ROOT/.github/workflows/deploy-vyos-v5.yml" "$REPO_ROOT/.github/workflows/"
cp "$SOURCE_ROOT/.github/workflows/destroy-vyos-v5.yml" "$REPO_ROOT/.github/workflows/"
cp "$SOURCE_ROOT/docs/webIQ_v5_github_actions_runbook.md" "$REPO_ROOT/docs/"
cp -r "$SOURCE_ROOT/infra/webIQ_clean_hubspoke_v5" "$REPO_ROOT/infra/"
cp "$SOURCE_ROOT/README.md" "$REPO_ROOT/"
echo "Repo layout restored at: $REPO_ROOT"
