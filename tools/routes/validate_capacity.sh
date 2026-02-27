#!/usr/bin/env bash
# Validate that all packages in a route fit in the assigned vehicle
# Usage: bash tools/routes/validate_capacity.sh <route_id>
# Output: JSON with valid=true/false, details of weight/volume vs capacity

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ROUTE_ID="${1:?Usage: validate_capacity.sh <route_id>}"

if ! entity_exists "routes" "$ROUTE_ID"; then die "Route '$ROUTE_ID' not found"; fi

ROUTE=$(read_json "$(entity_file "routes" "$ROUTE_ID")")
VEHICLE_ID=$(echo "$ROUTE" | jq -r '.vehicle_id // empty')

if [[ -z "$VEHICLE_ID" ]]; then
  jq -n '{valid: false, reason: "No vehicle assigned to route"}'
  exit 0
fi

if ! entity_exists "vehicles" "$VEHICLE_ID"; then
  die "Vehicle '$VEHICLE_ID' not found"
fi

VEHICLE=$(read_json "$(entity_file "vehicles" "$VEHICLE_ID")")
CAP_KG=$(echo "$VEHICLE" | jq '.capacity_kg')
CAP_M3=$(echo "$VEHICLE" | jq '.capacity_m3')

# Calculate actual totals from stops' shipments
TOTAL_KG=0
TOTAL_M3=0
STOPS_DIR="$PROJECT_ROOT/routes/$ROUTE_ID/stops"

if [[ -d "$STOPS_DIR" ]]; then
  for sdir in "$STOPS_DIR"/*/; do
    [[ -d "$sdir" ]] || continue
    SFILE="$sdir/stop.json"
    [[ -f "$SFILE" ]] || continue
    SID=$(jq -r '.shipment_id // empty' "$SFILE")
    if [[ -n "$SID" ]] && entity_exists "shipments" "$SID"; then
      SHIP=$(read_json "$(entity_file "shipments" "$SID")")
      W=$(echo "$SHIP" | jq '.total_weight_kg // 0')
      V=$(echo "$SHIP" | jq '.total_volume_m3 // 0')
      TOTAL_KG=$(echo "$TOTAL_KG + $W" | bc)
      TOTAL_M3=$(echo "$TOTAL_M3 + $V" | bc)
    fi
  done
fi

WEIGHT_OK=$(echo "$TOTAL_KG <= $CAP_KG" | bc)
VOLUME_OK=$(echo "$TOTAL_M3 <= $CAP_M3" | bc)

VALID="true"
ISSUES="[]"

if [[ "$WEIGHT_OK" != "1" ]]; then
  VALID="false"
  ISSUES=$(echo "$ISSUES" | jq --arg msg "Weight exceeds capacity: ${TOTAL_KG}kg > ${CAP_KG}kg" '. + [$msg]')
fi

if [[ "$VOLUME_OK" != "1" ]]; then
  VALID="false"
  ISSUES=$(echo "$ISSUES" | jq --arg msg "Volume exceeds capacity: ${TOTAL_M3}m3 > ${CAP_M3}m3" '. + [$msg]')
fi

jq -n \
  --argjson valid "$VALID" \
  --argjson issues "$ISSUES" \
  --arg route_id "$ROUTE_ID" \
  --arg vehicle_id "$VEHICLE_ID" \
  --argjson total_kg "$TOTAL_KG" \
  --argjson total_m3 "$TOTAL_M3" \
  --argjson cap_kg "$CAP_KG" \
  --argjson cap_m3 "$CAP_M3" \
  '{
    route_id: $route_id,
    vehicle_id: $vehicle_id,
    valid: $valid,
    weight: {total_kg: $total_kg, capacity_kg: $cap_kg, utilization_pct: (($total_kg / $cap_kg * 100) | round)},
    volume: {total_m3: $total_m3, capacity_m3: $cap_m3, utilization_pct: (($total_m3 / $cap_m3 * 100) | round)},
    issues: $issues
  }'
