#!/usr/bin/env bash
# Update a customer
# Usage: bash tools/customers/update.sh <customer_id> [field=value ...]
# Output: JSON of updated customer

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: update.sh <customer_id> [field=value ...]}"
shift

if ! entity_exists "customers" "$ID"; then
  die "Customer '$ID' not found"
fi

FILE="$(entity_file "customers" "$ID")"
CURRENT=$(read_json "$FILE")
UPDATES=$(args_to_json "$@")

# Merge updates, set updated timestamp
NOW=$(now_iso)
MERGED=$(merge_json "$CURRENT" "$UPDATES" | jq --arg now "$NOW" '.updated = $now')

write_json "$FILE" "$MERGED"

info "Updated customer: $ID"
echo "$MERGED" | jq '.'
