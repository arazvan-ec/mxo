#!/usr/bin/env bash
# List events for a shipment
# Usage: bash tools/shipments/events/list.sh <shipment_id>

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

SHIPMENT_ID="${1:?Usage: list.sh <shipment_id>}"
if ! entity_exists "shipments" "$SHIPMENT_ID"; then die "Shipment '$SHIPMENT_ID' not found"; fi

EVENTS_FILE="$(entity_dir "shipments" "$SHIPMENT_ID")/events.json"
if [[ ! -f "$EVENTS_FILE" ]]; then
  echo "[]"
else
  cat "$EVENTS_FILE"
fi
