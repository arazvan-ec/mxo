#!/usr/bin/env bash
# Read a vehicle by ID
# Usage: bash tools/vehicles/read.sh <vehicle_id>

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: read.sh <vehicle_id>}"

if ! entity_exists "vehicles" "$ID"; then
  die "Vehicle '$ID' not found"
fi

read_json "$(entity_file "vehicles" "$ID")"
