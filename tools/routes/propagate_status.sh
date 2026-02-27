#!/usr/bin/env bash
# Propagate route status changes to all associated shipments
# Usage: bash tools/routes/propagate_status.sh <route_id> <event_type> [description=...]
# Updates all shipments in the route with the given event

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ROUTE_ID="${1:?Usage: propagate_status.sh <route_id> <event_type> [description=...]}"
EVENT_TYPE="${2:?Usage: propagate_status.sh <route_id> <event_type>}"
DESC="${3:-Route $ROUTE_ID status update: $EVENT_TYPE}"

if ! entity_exists "routes" "$ROUTE_ID"; then die "Route '$ROUTE_ID' not found"; fi

STOPS_DIR="$PROJECT_ROOT/routes/$ROUTE_ID/stops"
COUNT=0

if [[ -d "$STOPS_DIR" ]]; then
  for sdir in "$STOPS_DIR"/*/; do
    [[ -d "$sdir" ]] || continue
    SFILE="$sdir/stop.json"
    [[ -f "$SFILE" ]] || continue
    SID=$(jq -r '.shipment_id // empty' "$SFILE")
    if [[ -n "$SID" ]] && entity_exists "shipments" "$SID"; then
      bash "$(dirname "${BASH_SOURCE[0]}")/../shipments/events/add.sh" "$SID" "type=$EVENT_TYPE" "description=$DESC" >/dev/null 2>&1
      COUNT=$((COUNT + 1))
    fi
  done
fi

info "Propagated '$EVENT_TYPE' to $COUNT shipments in route $ROUTE_ID"
jq -n --arg rid "$ROUTE_ID" --arg evt "$EVENT_TYPE" --argjson count "$COUNT" \
  '{route_id: $rid, event_type: $evt, shipments_updated: $count}'
