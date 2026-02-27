#!/usr/bin/env bash
# Confirm delivery at stop with Proof of Delivery (POD)
# Usage: bash tools/routes/stops/deliver.sh <route_id> <stop_id> signed_by_name=<name> [recipient_id_encoded=...] [notes=...]

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

ROUTE_ID="${1:?Usage: deliver.sh <route_id> <stop_id> signed_by_name=<name>}"
STOP_ID="${2:?Usage: deliver.sh <route_id> <stop_id> signed_by_name=<name>}"
shift 2

POD_DATA=$(args_to_json "$@")
validate_required "$POD_DATA" "signed_by_name" || exit 1

STOP_FILE="$PROJECT_ROOT/routes/$ROUTE_ID/stops/$STOP_ID/stop.json"
if [[ ! -f "$STOP_FILE" ]]; then die "Stop '$STOP_ID' not found"; fi

STATUS=$(jq -r '.status' "$STOP_FILE")
if [[ "$STATUS" != "pending" && "$STATUS" != "arrived" ]]; then
  die "Stop status is '$STATUS', expected 'pending' or 'arrived'"
fi

NOW=$(now_iso)

# Build POD
POD=$(echo "$POD_DATA" | jq --arg ts "$NOW" '. + {timestamp: $ts, confirmed_by_driver: true}')

# Update stop
jq --argjson pod "$POD" --arg now "$NOW" \
  '.status = "delivered" | .pod = $pod | .completed_at = $now | .updated = $now' \
  "$STOP_FILE" > "$STOP_FILE.tmp" && mv "$STOP_FILE.tmp" "$STOP_FILE"

# Update shipment event
SID=$(jq -r '.shipment_id // empty' "$STOP_FILE")
if [[ -n "$SID" ]] && entity_exists "shipments" "$SID"; then
  bash "$(dirname "${BASH_SOURCE[0]}")/../../shipments/events/add.sh" "$SID" type=DELIVERED description="Delivered at stop $STOP_ID" >/dev/null 2>&1
  # Update all packages to entregado
  SHIP_FILE="$(entity_file "shipments" "$SID")"
  jq '.packages = [.packages[] | .status = "entregado"]' "$SHIP_FILE" > "$SHIP_FILE.tmp" && mv "$SHIP_FILE.tmp" "$SHIP_FILE"
fi

# Update route counts
ROUTE_FILE="$(entity_file "routes" "$ROUTE_ID")"
jq --arg now "$NOW" '.stops_delivered += 1 | .stops_pending -= 1 | .updated = $now' \
  "$ROUTE_FILE" > "$ROUTE_FILE.tmp" && mv "$ROUTE_FILE.tmp" "$ROUTE_FILE"

# Log
LOG="$PROJECT_ROOT/routes/$ROUTE_ID/execution_log.md"
SIGNED=$(echo "$POD_DATA" | jq -r '.signed_by_name')
echo -e "\n## $NOW — Delivered: $STOP_ID\n\nSigned by: $SIGNED\n" >> "$LOG"

info "Delivered stop: $STOP_ID (signed by: $SIGNED)"
cat "$STOP_FILE"
