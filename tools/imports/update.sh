#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: update.sh <import_id> [field=value ...]}"
shift
if ! entity_exists "imports" "$ID"; then die "Import '$ID' not found"; fi
FILE="$(entity_dir "imports" "$ID")/import.json"
CURRENT=$(read_json "$FILE")
UPDATES=$(args_to_json "$@")
MERGED=$(merge_json "$CURRENT" "$UPDATES")
write_json "$FILE" "$MERGED"
info "Updated import: $ID"
echo "$MERGED" | jq '.'
