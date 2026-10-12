#!/usr/bin/env bash
set -euo pipefail

TARGETS_DIR="${TARGETS_DIR:-prometheus/targets}"
IP="${1:-}"
PORT="${2:-9100}"
CLOUD="${CLOUD:-${3:-alibaba}}"
ENV_LABEL="${4:-${ENV_LABEL:-ao-team}}"

usage() {
  cat <<USAGE
Usage: $0 <ip> [port] [cloud] [env]

Examples:
  $0 8.219.232.221                              # alibaba / ao-team
  $0 3.15.22.100 9100 aws prod                  # aws / prod
  $0 47.81.26.33 9100 alibaba ins               # alibaba / ins
USAGE
  exit 1
}
[[ -z "$IP" ]] && usage

VALID_CLOUDS=("alibaba" "aws" "gcp" "azure" "tencent" "custom" "z" "kvm")
VALID=false
for c in "${VALID_CLOUDS[@]}"; do [[ "$CLOUD" == "$c" ]] && VALID=true && break; done
[[ "$VALID" != "true" ]] && { echo "❌ Invalid cloud: $CLOUD"; exit 1; }

FILE="${TARGETS_DIR}/${CLOUD}-${ENV_LABEL}.json"
TARGET="${IP}:${PORT}"

if [[ ! -f "$FILE" ]]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

if ! jq -e --arg t "$TARGET" '.[0].targets | index($t)' "$FILE" >/dev/null; then
  echo "⚠️  $TARGET not found in $FILE"
  exit 0
fi

jq --arg t "$TARGET" '.[0].targets -= [$t]' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
echo "🗑️  Removed $TARGET ← $FILE  (cloud: $CLOUD, env: $ENV_LABEL)"
