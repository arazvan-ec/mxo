#!/usr/bin/env bash
# Update a vehicle
# Usage: bash tools/vehicles/update.sh <vehicle_id> [field=value ...]

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: update.sh <vehicle_id> [field=value ...]}"
shift

if ! entity_exists "vehicles" "$ID"; then
  die "Vehicle '$ID' not found"
fi

FILE="$(entity_file "vehicles" "$ID")"
CURRENT=$(read_json "$FILE")
UPDATES=$(args_to_json "$@")

NOW=$(now_iso)
MERGED=$(merge_json "$CURRENT" "$UPDATES" | jq --arg now "$NOW" '.updated = $now')

write_json "$FILE" "$MERGED"

info "Updated vehicle: $ID"
echo "$MERGED" | jq '.'
