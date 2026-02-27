#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: update.sh <zone_id> [field=value ...]}"
shift
if ! entity_exists "zones" "$ID"; then die "Zone '$ID' not found"; fi
FILE="$(entity_file "zones" "$ID")"
CURRENT=$(read_json "$FILE")
UPDATES=$(args_to_json "$@")
MERGED=$(merge_json "$CURRENT" "$UPDATES" | jq --arg now "$(now_iso)" '.updated = $now')
write_json "$FILE" "$MERGED"
info "Updated zone: $ID"
echo "$MERGED" | jq '.'
