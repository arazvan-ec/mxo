#!/usr/bin/env bash
# Update a package in a shipment
# Usage: bash tools/shipments/packages/update.sh <shipment_id> <package_id> [weight_kg=...] [volume_m3=...] [status=...]

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

SHIPMENT_ID="${1:?Usage: update.sh <shipment_id> <package_id> [field=value ...]}"
PKG_ID="${2:?Usage: update.sh <shipment_id> <package_id> [field=value ...]}"
shift 2

if ! entity_exists "shipments" "$SHIPMENT_ID"; then die "Shipment '$SHIPMENT_ID' not found"; fi

UPDATES=$(args_to_json "$@")
FILE="$(entity_file "shipments" "$SHIPMENT_ID")"
NOW=$(now_iso)

EXISTS=$(jq --arg pid "$PKG_ID" '[.packages[] | select(.id == $pid)] | length' "$FILE")
if [[ "$EXISTS" == "0" ]]; then die "Package '$PKG_ID' not found in shipment"; fi

RESULT=$(jq --arg pid "$PKG_ID" --argjson upd "$UPDATES" --arg now "$NOW" '
  .packages = [.packages[] | if .id == $pid then . * $upd else . end] |
  .total_weight_kg = ([.packages[].weight_kg] | add // 0) |
  .total_volume_m3 = ([.packages[].volume_m3] | add // 0) |
  .updated = $now
' "$FILE")

write_json "$FILE" "$RESULT"

info "Updated package $PKG_ID in shipment $SHIPMENT_ID"
echo "$RESULT" | jq '.'
