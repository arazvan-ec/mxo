#!/usr/bin/env bash
# List routes, optionally filtered
# Usage: bash tools/routes/list.sh [--customer=<cid>] [--status=<status>] [--driver=<did>] [--summary]

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

FILTER_CUSTOMER="" FILTER_STATUS="" FILTER_DRIVER="" SUMMARY=false
for arg in "$@"; do
  case "$arg" in
    --customer=*) FILTER_CUSTOMER="${arg#*=}" ;;
    --status=*) FILTER_STATUS="${arg#*=}" ;;
    --driver=*) FILTER_DRIVER="${arg#*=}" ;;
    --summary) SUMMARY=true ;;
  esac
done

BASE_DIR="$PROJECT_ROOT/routes"
if [[ ! -d "$BASE_DIR" ]]; then echo "[]"; exit 0; fi

RESULTS="[]"
for dir in "$BASE_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  FILE="$dir/route.json"
  [[ -f "$FILE" ]] || continue
  if [[ -n "$FILTER_CUSTOMER" ]]; then
    [[ "$(jq -r '.customer_id // empty' "$FILE")" == "$FILTER_CUSTOMER" ]] || continue
  fi
  if [[ -n "$FILTER_STATUS" ]]; then
    [[ "$(jq -r '.status // empty' "$FILE")" == "$FILTER_STATUS" ]] || continue
  fi
  if [[ -n "$FILTER_DRIVER" ]]; then
    [[ "$(jq -r '.driver_id // empty' "$FILE")" == "$FILTER_DRIVER" ]] || continue
  fi
  if [[ "$SUMMARY" == true ]]; then
    ITEM=$(jq '{id, name, status, customer_id, driver_id, vehicle_id, total_stops, total_weight_kg, total_volume_m3}' "$FILE")
  else
    ITEM=$(cat "$FILE")
  fi
  RESULTS=$(echo "$RESULTS" | jq --argjson item "$ITEM" '. + [$item]')
done

echo "$RESULTS" | jq '.'
