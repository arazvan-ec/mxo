#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: delete.sh <service_id>}"
if ! entity_exists "services" "$ID"; then die "Service '$ID' not found"; fi
rm -rf "$(entity_dir "services" "$ID")"
info "Deleted service: $ID"
echo "{\"deleted\": \"$ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
