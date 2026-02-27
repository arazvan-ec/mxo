#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: update.sh <driver_id> [field=value ...]}"
shift

if ! entity_exists "drivers" "$ID"; then die "Driver '$ID' not found"; fi

FILE="$(entity_file "drivers" "$ID")"
CURRENT=$(read_json "$FILE")
UPDATES=$(args_to_json "$@")
NOW=$(now_iso)
MERGED=$(merge_json "$CURRENT" "$UPDATES" | jq --arg now "$NOW" '.updated = $now')

write_json "$FILE" "$MERGED"
info "Updated driver: $ID"
echo "$MERGED" | jq '.'
