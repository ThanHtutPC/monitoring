#!/usr/bin/env bash
set -euo pipefail

TARGETS_DIR="${TARGETS_DIR:-prometheus/targets}"
FILTER_CLOUD="${1:-}"
FILTER_ENV="${2:-}"

usage() {
  cat <<USAGE
Usage: $0 [cloud] [env]

Examples:
  $0                       # list all target files
  $0 alibaba               # only alibaba targets
  $0 alibaba ins           # only alibaba / ins targets
  $0 "" prod               # all clouds, env=prod
USAGE
  exit 1
}

if [[ ! -d "$TARGETS_DIR" ]]; then
  echo "❌ Directory not found: $TARGETS_DIR"
  exit 1
fi

shopt -s nullglob
FILES=("$TARGETS_DIR"/*.json)
shopt -u nullglob

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "📭 No target files in $TARGETS_DIR"
  exit 0
fi

found=0
for f in "${FILES[@]}"; do
  base="$(basename "$f" .json)"

  # filename format: <cloud>-<env>
  file_cloud="${base%%-*}"
  file_env="${base#*-}"

  [[ -n "$FILTER_CLOUD" && "$file_cloud" != "$FILTER_CLOUD" ]] && continue
  [[ -n "$FILTER_ENV"   && "$file_env"   != "$FILTER_ENV"   ]] && continue

  found=1
  count=$(jq '.[0].targets | length' "$f")

  echo "📄 $f  (cloud: $file_cloud, env: $file_env, nodename: $(jq -r '.[0].labels.nodename // "-"' "$f"), targets: $count)"
  if [[ "$count" -gt 0 ]]; then
    jq -r '.[0].targets[]' "$f" | sed 's/^/   • /'
  else
    echo "   (empty)"
  fi
  echo
done

if [[ "$found" -eq 0 ]]; then
  echo "📭 No matching target files (cloud='${FILTER_CLOUD:-*}' env='${FILTER_ENV:-*}')"
fi
