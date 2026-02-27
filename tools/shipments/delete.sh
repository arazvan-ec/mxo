#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: delete.sh <shipment_id>}"
if ! entity_exists "shipments" "$ID"; then die "Shipment '$ID' not found"; fi
rm -rf "$(entity_dir "shipments" "$ID")"
info "Deleted shipment: $ID"
echo "{\"deleted\": \"$ID\", \"timestamp\": \"$(now_iso)\"}" | jq '.'
