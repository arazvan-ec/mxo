#!/usr/bin/env bash
# Add an event to a shipment's lifecycle
# Usage: bash tools/shipments/events/add.sh <shipment_id> type=<event_type> [description=...]
# Event types are flexible (agent-native): CREATED, PICKED_UP, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED, EXCEPTION, etc.

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

SHIPMENT_ID="${1:?Usage: add.sh <shipment_id> type=<event_type> [description=...]}"
shift

EVENT=$(args_to_json "$@")
validate_required "$EVENT" "type" || exit 1

if ! entity_exists "shipments" "$SHIPMENT_ID"; then
  die "Shipment '$SHIPMENT_ID' not found"
fi

NOW=$(now_iso)
EVENT=$(echo "$EVENT" | jq --arg ts "$NOW" '.timestamp //= $ts')

EVENTS_FILE="$(entity_dir "shipments" "$SHIPMENT_ID")/events.json"

# Initialize events.json if it doesn't exist
if [[ ! -f "$EVENTS_FILE" ]]; then
  echo "[]" > "$EVENTS_FILE"
fi

# Append event
jq --argjson evt "$EVENT" '. + [$evt]' "$EVENTS_FILE" > "$EVENTS_FILE.tmp" && mv "$EVENTS_FILE.tmp" "$EVENTS_FILE"

# Update shipment status based on latest event type
EVENT_TYPE=$(echo "$EVENT" | jq -r '.type')
STATUS_MAP="CREATED:created PICKED_UP:picked_up IN_TRANSIT:in_transit OUT_FOR_DELIVERY:out_for_delivery DELIVERED:delivered EXCEPTION:exception"
NEW_STATUS=""
for mapping in $STATUS_MAP; do
  EVT="${mapping%%:*}"
  ST="${mapping#*:}"
  if [[ "$EVENT_TYPE" == "$EVT" ]]; then
    NEW_STATUS="$ST"
    break
  fi
done

if [[ -n "$NEW_STATUS" ]]; then
  SHIPMENT_FILE="$(entity_file "shipments" "$SHIPMENT_ID")"
  jq --arg s "$NEW_STATUS" --arg now "$NOW" '.status = $s | .updated = $now' "$SHIPMENT_FILE" > "$SHIPMENT_FILE.tmp" && mv "$SHIPMENT_FILE.tmp" "$SHIPMENT_FILE"
fi

info "Added event '$EVENT_TYPE' to shipment $SHIPMENT_ID"
echo "$EVENT" | jq '.'
