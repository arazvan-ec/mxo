#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: delete.sh <driver_id>}"
if ! entity_exists "drivers" "$ID"; then die "Driver '$ID' not found"; fi
rm -rf "$(entity_dir "drivers" "$ID")"
info "Deleted driver: $ID"
echo "{\"deleted\": \"$ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
