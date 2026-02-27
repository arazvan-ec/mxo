#!/usr/bin/env bash
# Create a new route
# Usage: bash tools/routes/create.sh name=<name> customer_id=<cid> origin_lat=<lat> origin_lng=<lng> [driver_id=...] [vehicle_id=...]

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

DATA=$(args_to_json "$@")

ID=$(echo "$DATA" | jq -r '.id // empty')
if [[ -z "$ID" ]]; then
  ID=$(generate_id)
  DATA=$(echo "$DATA" | jq --arg id "$ID" '.id = $id')
fi

validate_required "$DATA" "name" "customer_id" "origin_lat" "origin_lng" || exit 1

if entity_exists "routes" "$ID"; then
  die "Route '$ID' already exists"
fi

NOW=$(now_iso)
DATA=$(echo "$DATA" | jq \
  --arg now "$NOW" \
  '.created //= $now | .updated = $now | .status //= "planned" | .total_stops //= 0 | .total_weight_kg //= 0 | .total_volume_m3 //= 0 | .total_distance_km //= 0 | .stops_delivered //= 0 | .stops_exception //= 0 | .stops_pending //= 0')

DIR=$(create_entity_dir "routes" "$ID")
mkdir -p "$DIR/stops"
write_json "$DIR/route.json" "$DATA"

info "Created route: $ID"
echo "$DATA" | jq '.'
