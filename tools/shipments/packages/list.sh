#!/usr/bin/env bash
# List packages in a shipment
# Usage: bash tools/shipments/packages/list.sh <shipment_id>

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

SHIPMENT_ID="${1:?Usage: list.sh <shipment_id>}"
if ! entity_exists "shipments" "$SHIPMENT_ID"; then die "Shipment '$SHIPMENT_ID' not found"; fi

jq '.packages // []' "$(entity_file "shipments" "$SHIPMENT_ID")"
