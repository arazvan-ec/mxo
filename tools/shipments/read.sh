#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: read.sh <shipment_id>}"
if ! entity_exists "shipments" "$ID"; then die "Shipment '$ID' not found"; fi
read_json "$(entity_file "shipments" "$ID")"
