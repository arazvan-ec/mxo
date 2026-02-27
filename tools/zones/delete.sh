#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: delete.sh <zone_id>}"
if ! entity_exists "zones" "$ID"; then die "Zone '$ID' not found"; fi
rm -rf "$(entity_dir "zones" "$ID")"
info "Deleted zone: $ID"
echo "{\"deleted\": \"$ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
