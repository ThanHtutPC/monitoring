#!/usr/bin/env bash
set -euo pipefail

TARGETS_DIR="${TARGETS_DIR:-prometheus/targets}"
IP="${1:-}"
PORT="${2:-9100}"
CLOUD="${CLOUD:-${3:-alibaba}}"
ENV_LABEL="${4:-${ENV_LABEL:-ao-team}}"
NODENAME="${5:-${NODENAME:-promt}}"

usage() {
  cat <<USAGE
Usage: $0 <ip> [port] [cloud] [env] [nodename]

Examples:
  $0 8.219.232.221                              # alibaba / ao-team / promt
  $0 3.15.22.100 9100 aws prod web01            # aws / prod / web01
  $0 3.15.22.101 9100 aws staging web02         # aws / staging / web02
  $0 34.56.78.90 9100 gcp prod api01            # gcp / prod / api01
  $0 47.81.26.33 9100 alibaba ins promt         # alibaba / ins / promt
USAGE
  exit 1
}
[[ -z "$IP" ]] && usage

VALID_CLOUDS=("alibaba" "aws" "gcp" "azure" "tencent" "custom" "z" "kvm")
VALID=false
for c in "${VALID_CLOUDS[@]}"; do [[ "$CLOUD" == "$c" ]] && VALID=true && break; done
[[ "$VALID" != "true" ]] && { echo "❌ Invalid cloud: $CLOUD"; exit 1; }

# 🔑 One file per cloud+env
FILE="${TARGETS_DIR}/${CLOUD}-${ENV_LABEL}.json"
TARGET="${IP}:${PORT}"

mkdir -p "$TARGETS_DIR"

if [[ ! -f "$FILE" ]]; then
  echo '[{"targets":[],"labels":{"env":"'"$ENV_LABEL"'","cloud":"'"$CLOUD"'","nodename":"'"$NODENAME"'"}}]' > "$FILE"
fi

if jq -e --arg t "$TARGET" '.[0].targets | index($t)' "$FILE" >/dev/null; then
  echo "⚠️  $TARGET already in $FILE"
  exit 0
fi

jq --arg t "$TARGET" --arg n "$NODENAME" \
  '.[0].targets += [$t] | .[0].labels.nodename = $n' \
  "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
echo "✅ Added $TARGET → $FILE  (cloud: $CLOUD, env: $ENV_LABEL, nodename: $NODENAME)"
