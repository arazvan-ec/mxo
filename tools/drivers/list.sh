#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
SUMMARY="${1:-}"
BASE_DIR="$PROJECT_ROOT/drivers"
if [[ ! -d "$BASE_DIR" ]]; then echo "[]"; exit 0; fi
RESULTS="[]"
for dir in "$BASE_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  FILE="$dir/driver.json"
  [[ -f "$FILE" ]] || continue
  if [[ "$SUMMARY" == "--summary" ]]; then
    ITEM=$(jq '{id, name, status, customer_id}' "$FILE")
  else
    ITEM=$(cat "$FILE")
  fi
  RESULTS=$(echo "$RESULTS" | jq --argjson item "$ITEM" '. + [$item]')
done
echo "$RESULTS" | jq '.'
