#!/usr/bin/env bash
# Add a package (bulto) to a shipment
# Usage: bash tools/shipments/packages/add.sh <shipment_id> weight_kg=<kg> volume_m3=<m3> [ean=...] [description=...]
# Output: JSON of updated shipment

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

SHIPMENT_ID="${1:?Usage: add.sh <shipment_id> weight_kg=<kg> volume_m3=<m3> [ean=...] [description=...]}"
shift

PKG=$(args_to_json "$@")
validate_required "$PKG" "weight_kg" "volume_m3" || exit 1

if ! entity_exists "shipments" "$SHIPMENT_ID"; then
  die "Shipment '$SHIPMENT_ID' not found"
fi

# Generate package ID
PKG_ID=$(generate_id)
PKG=$(echo "$PKG" | jq --arg id "$PKG_ID" '.id = $id | .status //= "pending"')

FILE="$(entity_file "shipments" "$SHIPMENT_ID")"
NOW=$(now_iso)

# Add package and recalculate totals
RESULT=$(jq --argjson pkg "$PKG" --arg now "$NOW" '
  .packages += [$pkg] |
  .total_packages = (.packages | length) |
  .total_weight_kg = ([.packages[].weight_kg] | add // 0) |
  .total_volume_m3 = ([.packages[].volume_m3] | add // 0) |
  .updated = $now
' "$FILE")

write_json "$FILE" "$RESULT"

info "Added package $PKG_ID to shipment $SHIPMENT_ID (total: $(echo "$RESULT" | jq '.total_packages') packages)"
echo "$RESULT" | jq '.'
