#!/usr/bin/env bash
# List shipments, optionally filtered by customer_id
# Usage: bash tools/shipments/list.sh [--customer=<cid>] [--summary] [--status=<status>]

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

FILTER_CUSTOMER=""
FILTER_STATUS=""
SUMMARY=false

for arg in "$@"; do
  case "$arg" in
    --customer=*) FILTER_CUSTOMER="${arg#*=}" ;;
    --status=*) FILTER_STATUS="${arg#*=}" ;;
    --summary) SUMMARY=true ;;
  esac
done

BASE_DIR="$PROJECT_ROOT/shipments"
if [[ ! -d "$BASE_DIR" ]]; then echo "[]"; exit 0; fi

RESULTS="[]"
for dir in "$BASE_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  FILE="$dir/shipment.json"
  [[ -f "$FILE" ]] || continue

  # Apply filters
  if [[ -n "$FILTER_CUSTOMER" ]]; then
    CID=$(jq -r '.customer_id // empty' "$FILE")
    [[ "$CID" == "$FILTER_CUSTOMER" ]] || continue
  fi
  if [[ -n "$FILTER_STATUS" ]]; then
    ST=$(jq -r '.status // empty' "$FILE")
    [[ "$ST" == "$FILTER_STATUS" ]] || continue
  fi

  if [[ "$SUMMARY" == true ]]; then
    ITEM=$(jq '{id, reference, customer_id, recipient_name, status, tracking_token, total_packages, total_weight_kg}' "$FILE")
  else
    ITEM=$(cat "$FILE")
  fi
  RESULTS=$(echo "$RESULTS" | jq --argjson item "$ITEM" '. + [$item]')
done

echo "$RESULTS" | jq '.'
