#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: update.sh <service_id> [field=value ...]}"
shift
if ! entity_exists "services" "$ID"; then die "Service '$ID' not found"; fi
FILE="$(entity_file "services" "$ID")"
CURRENT=$(read_json "$FILE")
UPDATES=$(args_to_json "$@")
MERGED=$(merge_json "$CURRENT" "$UPDATES" | jq --arg now "$(now_iso)" '.updated = $now')
write_json "$FILE" "$MERGED"
info "Updated service: $ID"
echo "$MERGED" | jq '.'
