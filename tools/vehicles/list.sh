#!/usr/bin/env bash
# List all vehicles
# Usage: bash tools/vehicles/list.sh [--summary]

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

SUMMARY="${1:-}"
BASE_DIR="$PROJECT_ROOT/vehicles"

if [[ ! -d "$BASE_DIR" ]]; then
  echo "[]"
  exit 0
fi

RESULTS="[]"
for dir in "$BASE_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  FILE="$dir/vehicle.json"
  [[ -f "$FILE" ]] || continue

  if [[ "$SUMMARY" == "--summary" ]]; then
    ITEM=$(jq '{id, name, plate, capacity_kg, capacity_m3, status}' "$FILE")
  else
    ITEM=$(cat "$FILE")
  fi
  RESULTS=$(echo "$RESULTS" | jq --argjson item "$ITEM" '. + [$item]')
done

echo "$RESULTS" | jq '.'
