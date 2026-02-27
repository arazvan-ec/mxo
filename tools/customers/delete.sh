#!/usr/bin/env bash
# Delete a customer
# Usage: bash tools/customers/delete.sh <customer_id>
# Output: JSON confirmation

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: delete.sh <customer_id>}"

if ! entity_exists "customers" "$ID"; then
  die "Customer '$ID' not found"
fi

DIR="$(entity_dir "customers" "$ID")"
rm -rf "$DIR"

info "Deleted customer: $ID"
echo "{\"deleted\": \"$ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
