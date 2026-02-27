#!/usr/bin/env bash
# Create a service type
# Usage: bash tools/services/create.sh id=<type> name=<name> type=<type> [requires_pickup=false] [requires_return=false]

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
DATA=$(args_to_json "$@")
validate_required "$DATA" "id" "name" "type" || exit 1
ID=$(echo "$DATA" | jq -r '.id')
if entity_exists "services" "$ID"; then die "Service '$ID' already exists"; fi
NOW=$(now_iso)
DATA=$(echo "$DATA" | jq --arg now "$NOW" \
  '.created //= $now | .updated = $now | .requires_pickup //= false | .requires_return //= false | .requires_signature //= true | .estimated_stop_time_min //= 2 | .package_requirements //= {"weight_required": true, "volume_required": true, "ean_required": false, "description_required": false}')
create_entity_dir "services" "$ID" >/dev/null
write_json "$(entity_file "services" "$ID")" "$DATA"
info "Created service: $ID"
echo "$DATA" | jq '.'
