#!/usr/bin/env bash
# Start a route (PLANNED → ACTIVE)
# Usage: bash tools/routes/start.sh <route_id> [--force]
# Validates capacity before starting unless --force

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ROUTE_ID="${1:?Usage: start.sh <route_id> [--force]}"
FORCE="${2:-}"

if ! entity_exists "routes" "$ROUTE_ID"; then die "Route '$ROUTE_ID' not found"; fi

ROUTE_FILE="$(entity_file "routes" "$ROUTE_ID")"
ROUTE=$(read_json "$ROUTE_FILE")
STATUS=$(echo "$ROUTE" | jq -r '.status')

if [[ "$STATUS" != "planned" ]]; then
  die "Cannot start route with status '$STATUS' (must be planned)"
fi

# Validate capacity unless forced
if [[ "$FORCE" != "--force" ]]; then
  VEHICLE_ID=$(echo "$ROUTE" | jq -r '.vehicle_id // empty')
  if [[ -n "$VEHICLE_ID" ]]; then
    VALIDATION=$(bash "$(dirname "${BASH_SOURCE[0]}")/validate_capacity.sh" "$ROUTE_ID")
    VALID=$(echo "$VALIDATION" | jq -r '.valid')
    if [[ "$VALID" != "true" ]]; then
      echo "$VALIDATION" >&2
      die "Capacity validation failed. Use --force to override."
    fi
  fi
fi

NOW=$(now_iso)
ROUTE=$(echo "$ROUTE" | jq --arg now "$NOW" '.status = "active" | .started_at = $now | .updated = $now')
write_json "$ROUTE_FILE" "$ROUTE"

# Update all stop shipments to OUT_FOR_DELIVERY
STOPS_DIR="$PROJECT_ROOT/routes/$ROUTE_ID/stops"
if [[ -d "$STOPS_DIR" ]]; then
  for sdir in "$STOPS_DIR"/*/; do
    [[ -d "$sdir" ]] || continue
    SFILE="$sdir/stop.json"
    [[ -f "$SFILE" ]] || continue
    SID=$(jq -r '.shipment_id // empty' "$SFILE")
    if [[ -n "$SID" ]] && entity_exists "shipments" "$SID"; then
      bash "$(dirname "${BASH_SOURCE[0]}")/../shipments/events/add.sh" "$SID" type=OUT_FOR_DELIVERY description="Route $ROUTE_ID started" >/dev/null 2>&1
    fi
  done
fi

# Log
LOG_FILE="$PROJECT_ROOT/routes/$ROUTE_ID/execution_log.md"
echo -e "\n## $NOW — Route Started\n\nStatus: PLANNED → ACTIVE\n" >> "$LOG_FILE"

info "Started route: $ROUTE_ID"
echo "$ROUTE" | jq '.'
