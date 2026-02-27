#!/usr/bin/env bash
# Remove a stop from a route (recalculates route totals)
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

ROUTE_ID="${1:?Usage: delete.sh <route_id> <stop_id>}"
STOP_ID="${2:?Usage: delete.sh <route_id> <stop_id>}"

STOP_DIR="$PROJECT_ROOT/routes/$ROUTE_ID/stops/$STOP_ID"
STOP_FILE="$STOP_DIR/stop.json"
if [[ ! -f "$STOP_FILE" ]]; then die "Stop '$STOP_ID' not found in route '$ROUTE_ID'"; fi

# Get shipment weight/volume to subtract from route
SHIPMENT_ID=$(jq -r '.shipment_id // empty' "$STOP_FILE")
SHIP_WEIGHT=0
SHIP_VOLUME=0
if [[ -n "$SHIPMENT_ID" ]] && entity_exists "shipments" "$SHIPMENT_ID"; then
  SHIP_FILE="$(entity_file "shipments" "$SHIPMENT_ID")"
  SHIP_WEIGHT=$(jq '.total_weight_kg // 0' "$SHIP_FILE")
  SHIP_VOLUME=$(jq '.total_volume_m3 // 0' "$SHIP_FILE")
  # Clear route_id from shipment
  jq '.route_id = null' "$SHIP_FILE" > "$SHIP_FILE.tmp" && mv "$SHIP_FILE.tmp" "$SHIP_FILE"
fi

STOP_STATUS=$(jq -r '.status // "pending"' "$STOP_FILE")

rm -rf "$STOP_DIR"

# Update route totals
ROUTE_FILE="$(entity_file "routes" "$ROUTE_ID")"
NOW=$(now_iso)
jq --argjson sw "$SHIP_WEIGHT" --argjson sv "$SHIP_VOLUME" --arg st "$STOP_STATUS" --arg now "$NOW" '
  .total_stops -= 1 |
  .total_weight_kg -= $sw |
  .total_volume_m3 -= $sv |
  .updated = $now |
  if $st == "pending" then .stops_pending -= 1
  elif $st == "delivered" then .stops_delivered -= 1
  elif $st == "exception" then .stops_exception -= 1
  else . end
' "$ROUTE_FILE" > "$ROUTE_FILE.tmp" && mv "$ROUTE_FILE.tmp" "$ROUTE_FILE"

info "Deleted stop: $STOP_ID from route: $ROUTE_ID"
echo "{\"deleted\": \"$STOP_ID\", \"route_id\": \"$ROUTE_ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
