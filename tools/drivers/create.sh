#!/usr/bin/env bash
# Create a new driver
# Usage: bash tools/drivers/create.sh [id=<id>] name=<name> [email=...] [phone=...] [customer_id=...]

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

DATA=$(args_to_json "$@")

ID=$(echo "$DATA" | jq -r '.id // empty')
if [[ -z "$ID" ]]; then
  ID=$(generate_id)
  DATA=$(echo "$DATA" | jq --arg id "$ID" '.id = $id')
fi

validate_required "$DATA" "name" || exit 1

if entity_exists "drivers" "$ID"; then
  die "Driver '$ID' already exists"
fi

NOW=$(now_iso)
DATA=$(echo "$DATA" | jq \
  --arg now "$NOW" \
  '.created //= $now | .updated = $now | .status //= "active"')

create_entity_dir "drivers" "$ID" >/dev/null
write_json "$(entity_file "drivers" "$ID")" "$DATA"

info "Created driver: $ID"
echo "$DATA" | jq '.'
