#!/usr/bin/env bash
# Create a new shipment
# Usage: bash tools/shipments/create.sh reference=<ref> customer_id=<cid> recipient_name=<name> address=<addr> lat=<lat> lng=<lng> [service_type=entrega] [phone=...] [notes=...]
# Output: JSON of created shipment (with tracking_token and events.json initialized)

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

DATA=$(args_to_json "$@")

ID=$(echo "$DATA" | jq -r '.id // empty')
if [[ -z "$ID" ]]; then
  ID=$(generate_id)
  DATA=$(echo "$DATA" | jq --arg id "$ID" '.id = $id')
fi

validate_required "$DATA" "reference" "customer_id" "recipient_name" "address" "lat" "lng" || exit 1

if entity_exists "shipments" "$ID"; then
  die "Shipment '$ID' already exists"
fi

# Check for duplicate reference within customer
CUSTOMER_ID=$(echo "$DATA" | jq -r '.customer_id')
REF=$(echo "$DATA" | jq -r '.reference')
for dir in "$PROJECT_ROOT/shipments"/*/; do
  [[ -d "$dir" ]] || continue
  FILE="$dir/shipment.json"
  [[ -f "$FILE" ]] || continue
  EXISTING_CID=$(jq -r '.customer_id // empty' "$FILE")
  EXISTING_REF=$(jq -r '.reference // empty' "$FILE")
  if [[ "$EXISTING_CID" == "$CUSTOMER_ID" && "$EXISTING_REF" == "$REF" ]]; then
    die "Duplicate reference '$REF' for customer '$CUSTOMER_ID'"
  fi
done

# Generate tracking token
TOKEN=$(generate_tracking_token)

NOW=$(now_iso)
DATA=$(echo "$DATA" | jq \
  --arg now "$NOW" \
  --arg token "$TOKEN" \
  '.created //= $now | .updated = $now | .status //= "created" | .service_type //= "entrega" | .tracking_token = $token | .packages //= [] | .total_packages //= 0 | .total_weight_kg //= 0 | .total_volume_m3 //= 0')

# Create directory and write
DIR=$(create_entity_dir "shipments" "$ID")
write_json "$DIR/shipment.json" "$DATA"

# Initialize events with CREATED event
EVENTS=$(jq -n \
  --arg ts "$NOW" \
  --arg type "CREATED" \
  '[{"type": $type, "timestamp": $ts, "description": "Shipment created"}]')
write_json "$DIR/events.json" "$EVENTS"

info "Created shipment: $ID (tracking: $TOKEN)"
echo "$DATA" | jq '.'
