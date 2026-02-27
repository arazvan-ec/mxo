#!/usr/bin/env bash
# Create a new customer
# Usage: bash tools/customers/create.sh [id=<id>] name=<name> [address=...] [phone=...] [email=...]
# Output: JSON of created customer

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Parse arguments
DATA=$(args_to_json "$@")

# Generate ID if not provided
ID=$(echo "$DATA" | jq -r '.id // empty')
if [[ -z "$ID" ]]; then
  ID=$(generate_id)
  DATA=$(echo "$DATA" | jq --arg id "$ID" '.id = $id')
fi

# Validate required fields
validate_required "$DATA" "name" || exit 1

# Check if already exists
if entity_exists "customers" "$ID"; then
  die "Customer '$ID' already exists"
fi

# Set defaults
NOW=$(now_iso)
DATA=$(echo "$DATA" | jq \
  --arg now "$NOW" \
  --arg status "active" \
  '.created //= $now | .updated = $now | .status //= $status | .locations //= []')

# Create directory and write
create_entity_dir "customers" "$ID" >/dev/null
write_json "$(entity_file "customers" "$ID")" "$DATA"

info "Created customer: $ID"
echo "$DATA" | jq '.'
