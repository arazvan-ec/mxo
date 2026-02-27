#!/usr/bin/env bash
# Create a new vehicle
# Usage: bash tools/vehicles/create.sh [id=<id>] name=<name> capacity_kg=<kg> capacity_m3=<m3> [plate=...] [vehicle_type=...]
# Output: JSON of created vehicle

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

DATA=$(args_to_json "$@")

ID=$(echo "$DATA" | jq -r '.id // empty')
if [[ -z "$ID" ]]; then
  ID=$(generate_id)
  DATA=$(echo "$DATA" | jq --arg id "$ID" '.id = $id')
fi

validate_required "$DATA" "name" "capacity_kg" "capacity_m3" || exit 1

if entity_exists "vehicles" "$ID"; then
  die "Vehicle '$ID' already exists"
fi

NOW=$(now_iso)
DATA=$(echo "$DATA" | jq \
  --arg now "$NOW" \
  '.created //= $now | .updated = $now | .status //= "available"')

create_entity_dir "vehicles" "$ID" >/dev/null
write_json "$(entity_file "vehicles" "$ID")" "$DATA"

info "Created vehicle: $ID"
echo "$DATA" | jq '.'
