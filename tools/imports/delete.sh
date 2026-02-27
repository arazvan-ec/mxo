#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: delete.sh <import_id>}"
if ! entity_exists "imports" "$ID"; then die "Import '$ID' not found"; fi
rm -rf "$(entity_dir "imports" "$ID")"
info "Deleted import: $ID"
echo "{\"deleted\": \"$ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
