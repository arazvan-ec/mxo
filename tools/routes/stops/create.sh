#!/usr/bin/env bash
# Add a stop to a route
# Usage: bash tools/routes/stops/create.sh route_id=<rid> shipment_id=<sid> [sequence=<n>] [address=...] [lat=...] [lng=...]
# If address/lat/lng not provided, copies from shipment

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

DATA=$(args_to_json "$@")

validate_required "$DATA" "route_id" "shipment_id" || exit 1

ROUTE_ID=$(echo "$DATA" | jq -r '.route_id')
SHIPMENT_ID=$(echo "$DATA" | jq -r '.shipment_id')

# Validate route exists and is planned
if ! entity_exists "routes" "$ROUTE_ID"; then
  die "Route '$ROUTE_ID' not found"
fi

ROUTE_FILE="$(entity_file "routes" "$ROUTE_ID")"
ROUTE_STATUS=$(jq -r '.status' "$ROUTE_FILE")
if [[ "$ROUTE_STATUS" != "planned" ]]; then
  die "Cannot add stops to route with status '$ROUTE_STATUS' (must be planned)"
fi

# Validate shipment exists
if ! entity_exists "shipments" "$SHIPMENT_ID"; then
  die "Shipment '$SHIPMENT_ID' not found"
fi

# Copy address/lat/lng from shipment if not provided
SHIPMENT_FILE="$(entity_file "shipments" "$SHIPMENT_ID")"
SHIPMENT=$(read_json "$SHIPMENT_FILE")

for field in address lat lng recipient_name; do
  EXISTING=$(echo "$DATA" | jq -r --arg f "$field" '.[$f] // empty')
  if [[ -z "$EXISTING" ]]; then
    VAL=$(echo "$SHIPMENT" | jq --arg f "$field" '.[$f]')
    DATA=$(echo "$DATA" | jq --arg f "$field" --argjson v "$VAL" '.[$f] = $v')
  fi
done

# Generate stop ID
STOP_ID=$(echo "$DATA" | jq -r '.id // empty')
if [[ -z "$STOP_ID" ]]; then
  STOP_ID=$(generate_id)
  DATA=$(echo "$DATA" | jq --arg id "$STOP_ID" '.id = $id')
fi

# Auto-assign sequence if not provided
STOPS_DIR="$PROJECT_ROOT/routes/$ROUTE_ID/stops"
EXISTING_SEQ=$(echo "$DATA" | jq -r '.sequence // empty')
if [[ -z "$EXISTING_SEQ" ]]; then
  MAX_SEQ=0
  for sdir in "$STOPS_DIR"/*/; do
    [[ -d "$sdir" ]] || continue
    SFILE="$sdir/stop.json"
    [[ -f "$SFILE" ]] || continue
    S=$(jq -r '.sequence // 0' "$SFILE")
    (( S > MAX_SEQ )) && MAX_SEQ=$S
  done
  SEQ=$((MAX_SEQ + 1))
  DATA=$(echo "$DATA" | jq --argjson s "$SEQ" '.sequence = $s')
fi

NOW=$(now_iso)
DATA=$(echo "$DATA" | jq --arg now "$NOW" '.created //= $now | .updated = $now | .status //= "pending"')

# Create stop directory
STOP_DIR="$STOPS_DIR/$STOP_ID"
mkdir -p "$STOP_DIR"
write_json "$STOP_DIR/stop.json" "$DATA"

# Update route totals
SHIP_WEIGHT=$(echo "$SHIPMENT" | jq '.total_weight_kg // 0')
SHIP_VOLUME=$(echo "$SHIPMENT" | jq '.total_volume_m3 // 0')

ROUTE=$(read_json "$ROUTE_FILE")
ROUTE=$(echo "$ROUTE" | jq \
  --argjson sw "$SHIP_WEIGHT" \
  --argjson sv "$SHIP_VOLUME" \
  --arg now "$NOW" \
  '.total_stops += 1 | .stops_pending += 1 | .total_weight_kg += $sw | .total_volume_m3 += $sv | .updated = $now')
write_json "$ROUTE_FILE" "$ROUTE"

# Mark shipment as assigned to route
jq --arg rid "$ROUTE_ID" '.route_id = $rid' "$SHIPMENT_FILE" > "$SHIPMENT_FILE.tmp" && mv "$SHIPMENT_FILE.tmp" "$SHIPMENT_FILE"

info "Created stop: $STOP_ID (seq: $(echo "$DATA" | jq '.sequence'), route: $ROUTE_ID)"
echo "$DATA" | jq '.'
