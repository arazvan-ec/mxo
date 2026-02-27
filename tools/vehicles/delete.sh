#!/usr/bin/env bash
# Delete a vehicle
# Usage: bash tools/vehicles/delete.sh <vehicle_id>

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: delete.sh <vehicle_id>}"

if ! entity_exists "vehicles" "$ID"; then
  die "Vehicle '$ID' not found"
fi

rm -rf "$(entity_dir "vehicles" "$ID")"

info "Deleted vehicle: $ID"
echo "{\"deleted\": \"$ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
