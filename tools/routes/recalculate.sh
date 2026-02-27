#!/usr/bin/env bash
# Recalculate route totals (weight, volume, stop counts) from actual stop data
# Usage: bash tools/routes/recalculate.sh <route_id>

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ROUTE_ID="${1:?Usage: recalculate.sh <route_id>}"
if ! entity_exists "routes" "$ROUTE_ID"; then die "Route '$ROUTE_ID' not found"; fi

ROUTE_FILE="$(entity_file "routes" "$ROUTE_ID")"
STOPS_DIR="$PROJECT_ROOT/routes/$ROUTE_ID/stops"

TOTAL_STOPS=0 TOTAL_KG=0 TOTAL_M3=0
PENDING=0 DELIVERED=0 EXCEPTION=0

if [[ -d "$STOPS_DIR" ]]; then
  for sdir in "$STOPS_DIR"/*/; do
    [[ -d "$sdir" ]] || continue
    SFILE="$sdir/stop.json"
    [[ -f "$SFILE" ]] || continue

    TOTAL_STOPS=$((TOTAL_STOPS + 1))
    STATUS=$(jq -r '.status // "pending"' "$SFILE")
    case "$STATUS" in
      pending|arrived) PENDING=$((PENDING + 1)) ;;
      delivered) DELIVERED=$((DELIVERED + 1)) ;;
      exception) EXCEPTION=$((EXCEPTION + 1)) ;;
    esac

    SID=$(jq -r '.shipment_id // empty' "$SFILE")
    if [[ -n "$SID" ]] && entity_exists "shipments" "$SID"; then
      W=$(jq '.total_weight_kg // 0' "$(entity_file "shipments" "$SID")")
      V=$(jq '.total_volume_m3 // 0' "$(entity_file "shipments" "$SID")")
      TOTAL_KG=$(echo "$TOTAL_KG + $W" | bc)
      TOTAL_M3=$(echo "$TOTAL_M3 + $V" | bc)
    fi
  done
fi

NOW=$(now_iso)
jq --argjson ts "$TOTAL_STOPS" \
   --argjson tk "$TOTAL_KG" \
   --argjson tv "$TOTAL_M3" \
   --argjson sp "$PENDING" \
   --argjson sd "$DELIVERED" \
   --argjson se "$EXCEPTION" \
   --arg now "$NOW" \
   '.total_stops = $ts | .total_weight_kg = $tk | .total_volume_m3 = $tv | .stops_pending = $sp | .stops_delivered = $sd | .stops_exception = $se | .updated = $now' \
   "$ROUTE_FILE" > "$ROUTE_FILE.tmp" && mv "$ROUTE_FILE.tmp" "$ROUTE_FILE"

info "Recalculated route $ROUTE_ID: $TOTAL_STOPS stops, ${TOTAL_KG}kg, ${TOTAL_M3}m3"
cat "$ROUTE_FILE"
