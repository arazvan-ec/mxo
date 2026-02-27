#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: delete.sh <route_id>}"
if ! entity_exists "routes" "$ID"; then die "Route '$ID' not found"; fi
rm -rf "$(entity_dir "routes" "$ID")"
info "Deleted route: $ID"
echo "{\"deleted\": \"$ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
