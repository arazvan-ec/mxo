#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
BASE_DIR="$PROJECT_ROOT/imports"
if [[ ! -d "$BASE_DIR" ]]; then echo "[]"; exit 0; fi
RESULTS="[]"
for dir in "$BASE_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  FILE="$dir/import.json"
  [[ -f "$FILE" ]] || continue
  RESULTS=$(echo "$RESULTS" | jq --argjson item "$(cat "$FILE")" '. + [$item]')
done
echo "$RESULTS" | jq '.'
