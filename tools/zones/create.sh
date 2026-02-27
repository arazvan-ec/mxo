#!/usr/bin/env bash
# Create a zone (RGU/isochrone)
# Usage: bash tools/zones/create.sh name=<name> center_lat=<lat> center_lng=<lng> radius_minutes=<min>

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
DATA=$(args_to_json "$@")

ID=$(echo "$DATA" | jq -r '.id // empty')
if [[ -z "$ID" ]]; then ID=$(generate_id); DATA=$(echo "$DATA" | jq --arg id "$ID" '.id = $id'); fi

validate_required "$DATA" "name" "center_lat" "center_lng" "radius_minutes" || exit 1

if entity_exists "zones" "$ID"; then die "Zone '$ID' already exists"; fi

# Calculate approximate radius in km from minutes at avg speed
RADIUS_MIN=$(echo "$DATA" | jq '.radius_minutes')
# Load avg speed from config
AVG_SPEED=30
CONFIG="$PROJECT_ROOT/config/defaults.json"
if [[ -f "$CONFIG" ]]; then
  AVG_SPEED=$(jq '.avg_speed_kmh // 30' "$CONFIG")
fi
RADIUS_KM=$(echo "scale=2; $RADIUS_MIN * $AVG_SPEED / 60" | bc)

NOW=$(now_iso)
DATA=$(echo "$DATA" | jq --arg now "$NOW" --argjson rkm "$RADIUS_KM" \
  '.created //= $now | .updated = $now | .radius_km = $rkm | .status //= "active"')

create_entity_dir "zones" "$ID" >/dev/null
write_json "$(entity_file "zones" "$ID")" "$DATA"
info "Created zone: $ID (radius: ${RADIUS_KM}km / ${RADIUS_MIN}min)"
echo "$DATA" | jq '.'
