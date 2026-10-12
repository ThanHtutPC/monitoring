#!/usr/bin/env bash
set -euo pipefail

TARGETS_DIR="${TARGETS_DIR:-prometheus/targets}"
IP="${1:-}"
PORT="${2:-9100}"
CLOUD="${CLOUD:-${3:-alibaba}}"
ENV_LABEL="${4:-${ENV_LABEL:-ao-team}}"

if [[ -z "$IP" ]]; then
  echo "Usage: $0 <ip> [port] [cloud] [env]"
  exit 1
fi

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
echo "✅ Removed $TARGET from $FILE"
