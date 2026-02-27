#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: update.sh <shipment_id> [field=value ...]}"
shift

if ! entity_exists "shipments" "$ID"; then die "Shipment '$ID' not found"; fi

FILE="$(entity_file "shipments" "$ID")"
CURRENT=$(read_json "$FILE")
UPDATES=$(args_to_json "$@")
NOW=$(now_iso)
MERGED=$(merge_json "$CURRENT" "$UPDATES" | jq --arg now "$NOW" '.updated = $now')

write_json "$FILE" "$MERGED"
info "Updated shipment: $ID"
echo "$MERGED" | jq '.'
