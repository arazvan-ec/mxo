#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: update.sh <route_id> [field=value ...]}"
shift
if ! entity_exists "routes" "$ID"; then die "Route '$ID' not found"; fi
FILE="$(entity_file "routes" "$ID")"
CURRENT=$(read_json "$FILE")
UPDATES=$(args_to_json "$@")
NOW=$(now_iso)
MERGED=$(merge_json "$CURRENT" "$UPDATES" | jq --arg now "$NOW" '.updated = $now')
write_json "$FILE" "$MERGED"
info "Updated route: $ID"
echo "$MERGED" | jq '.'
