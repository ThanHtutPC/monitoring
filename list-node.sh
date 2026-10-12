#!/usr/bin/env bash
set -euo pipefail

TARGETS_DIR="${TARGETS_DIR:-prometheus/targets}"

if [[ ! -d "$TARGETS_DIR" ]]; then
  echo "❌ Directory not found: $TARGETS_DIR"
  exit 1
fi

shopt -s nullglob
for FILE in "$TARGETS_DIR"/*.json; do
  CLOUD=$(basename "$FILE" .json)
  COUNT=$(jq '.[0].targets | length' "$FILE")
  echo "☁️  $CLOUD ($COUNT targets) — $FILE"
  jq -r '.[0].targets[] | "   • \(.)"' "$FILE"
  echo
done
