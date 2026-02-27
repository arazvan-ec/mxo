#!/usr/bin/env bash
# List all stops in a route, ordered by sequence
# Usage: bash tools/routes/stops/list.sh <route_id> [--summary]

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

ROUTE_ID="${1:?Usage: list.sh <route_id> [--summary]}"
SUMMARY="${2:-}"

STOPS_DIR="$PROJECT_ROOT/routes/$ROUTE_ID/stops"
if [[ ! -d "$STOPS_DIR" ]]; then echo "[]"; exit 0; fi

RESULTS="[]"
for dir in "$STOPS_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  FILE="$dir/stop.json"
  [[ -f "$FILE" ]] || continue
  if [[ "$SUMMARY" == "--summary" ]]; then
    ITEM=$(jq '{id, sequence, shipment_id, recipient_name, status, address}' "$FILE")
  else
    ITEM=$(cat "$FILE")
  fi
  RESULTS=$(echo "$RESULTS" | jq --argjson item "$ITEM" '. + [$item]')
done

# Sort by sequence
echo "$RESULTS" | jq 'sort_by(.sequence)'
