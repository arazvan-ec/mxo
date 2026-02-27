#!/usr/bin/env bash
# Remove a package from a shipment
# Usage: bash tools/shipments/packages/remove.sh <shipment_id> <package_id>

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

SHIPMENT_ID="${1:?Usage: remove.sh <shipment_id> <package_id>}"
PKG_ID="${2:?Usage: remove.sh <shipment_id> <package_id>}"

if ! entity_exists "shipments" "$SHIPMENT_ID"; then die "Shipment '$SHIPMENT_ID' not found"; fi

FILE="$(entity_file "shipments" "$SHIPMENT_ID")"
NOW=$(now_iso)

# Check package exists
EXISTS=$(jq --arg pid "$PKG_ID" '[.packages[] | select(.id == $pid)] | length' "$FILE")
if [[ "$EXISTS" == "0" ]]; then die "Package '$PKG_ID' not found in shipment"; fi

RESULT=$(jq --arg pid "$PKG_ID" --arg now "$NOW" '
  .packages = [.packages[] | select(.id != $pid)] |
  .total_packages = (.packages | length) |
  .total_weight_kg = ([.packages[].weight_kg] | add // 0) |
  .total_volume_m3 = ([.packages[].volume_m3] | add // 0) |
  .updated = $now
' "$FILE")

write_json "$FILE" "$RESULT"

info "Removed package $PKG_ID from shipment $SHIPMENT_ID"
echo "$RESULT" | jq '.'
