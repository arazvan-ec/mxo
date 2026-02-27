#!/usr/bin/env bash
# Validate a shipment against its service type requirements
# Usage: bash tools/shipments/validate.sh <shipment_id>
# Output: JSON with valid=true/false and issues[]

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

SHIPMENT_ID="${1:?Usage: validate.sh <shipment_id>}"

if ! entity_exists "shipments" "$SHIPMENT_ID"; then die "Shipment '$SHIPMENT_ID' not found"; fi

SHIPMENT=$(read_json "$(entity_file "shipments" "$SHIPMENT_ID")")
SERVICE_TYPE=$(echo "$SHIPMENT" | jq -r '.service_type // "entrega"')

# Load service config
SERVICE_FILE="$PROJECT_ROOT/services/$SERVICE_TYPE/service.json"
ISSUES="[]"

if [[ ! -f "$SERVICE_FILE" ]]; then
  ISSUES=$(echo "$ISSUES" | jq --arg st "$SERVICE_TYPE" '. + ["Unknown service type: " + $st]')
else
  SERVICE=$(cat "$SERVICE_FILE")
  PKG_REQ=$(echo "$SERVICE" | jq '.package_requirements // {}')

  # Check packages exist
  TOTAL_PKG=$(echo "$SHIPMENT" | jq '.total_packages // 0')
  if [[ "$TOTAL_PKG" == "0" ]]; then
    ISSUES=$(echo "$ISSUES" | jq '. + ["Shipment has no packages"]')
  fi

  # Check each package against requirements
  WEIGHT_REQ=$(echo "$PKG_REQ" | jq -r '.weight_required // false')
  VOLUME_REQ=$(echo "$PKG_REQ" | jq -r '.volume_required // false')
  EAN_REQ=$(echo "$PKG_REQ" | jq -r '.ean_required // false')
  DESC_REQ=$(echo "$PKG_REQ" | jq -r '.description_required // false')

  IDX=0
  echo "$SHIPMENT" | jq -c '.packages[]?' | while read -r pkg; do
    IDX=$((IDX + 1))
    if [[ "$WEIGHT_REQ" == "true" ]]; then
      W=$(echo "$pkg" | jq '.weight_kg // 0')
      if [[ "$W" == "0" ]] || [[ "$W" == "null" ]]; then
        echo "Package $IDX: weight_kg is required" >&2
      fi
    fi
    if [[ "$VOLUME_REQ" == "true" ]]; then
      V=$(echo "$pkg" | jq '.volume_m3 // 0')
      if [[ "$V" == "0" ]] || [[ "$V" == "null" ]]; then
        echo "Package $IDX: volume_m3 is required" >&2
      fi
    fi
    if [[ "$EAN_REQ" == "true" ]]; then
      E=$(echo "$pkg" | jq -r '.ean // empty')
      if [[ -z "$E" ]]; then
        echo "Package $IDX: ean is required" >&2
      fi
    fi
    if [[ "$DESC_REQ" == "true" ]]; then
      D=$(echo "$pkg" | jq -r '.description // empty')
      if [[ -z "$D" ]]; then
        echo "Package $IDX: description is required" >&2
      fi
    fi
  done 2>&1 | while read -r issue; do
    ISSUES=$(echo "$ISSUES" | jq --arg i "$issue" '. + [$i]')
    echo "$ISSUES"
  done | tail -1 > /tmp/mxo_validate_issues 2>/dev/null

  if [[ -f /tmp/mxo_validate_issues ]] && [[ -s /tmp/mxo_validate_issues ]]; then
    ISSUES=$(cat /tmp/mxo_validate_issues)
    rm -f /tmp/mxo_validate_issues
  fi
fi

# Check required fields
for field in recipient_name address lat lng; do
  VAL=$(echo "$SHIPMENT" | jq -r --arg f "$field" '.[$f] // empty')
  if [[ -z "$VAL" ]]; then
    ISSUES=$(echo "$ISSUES" | jq --arg i "Missing required field: $field" '. + [$i]')
  fi
done

VALID="true"
ISSUE_COUNT=$(echo "$ISSUES" | jq 'length')
if [[ "$ISSUE_COUNT" -gt 0 ]]; then
  VALID="false"
fi

jq -n --argjson valid "$VALID" --argjson issues "$ISSUES" --arg sid "$SHIPMENT_ID" --arg stype "$SERVICE_TYPE" \
  '{shipment_id: $sid, service_type: $stype, valid: $valid, issues: $issues}'
