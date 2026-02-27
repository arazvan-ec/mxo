#!/usr/bin/env bash
# Get route progress summary
# Usage: bash tools/routes/progress.sh <route_id>
# Output: JSON with completion stats, stop statuses, and ETA info

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ROUTE_ID="${1:?Usage: progress.sh <route_id>}"
if ! entity_exists "routes" "$ROUTE_ID"; then die "Route '$ROUTE_ID' not found"; fi

ROUTE=$(read_json "$(entity_file "routes" "$ROUTE_ID")")
STOPS_DIR="$PROJECT_ROOT/routes/$ROUTE_ID/stops"

# Count statuses
TOTAL=0 PENDING=0 ARRIVED=0 DELIVERED=0 EXCEPTION=0 SKIPPED=0
NEXT_STOP="null"

if [[ -d "$STOPS_DIR" ]]; then
  for sdir in "$STOPS_DIR"/*/; do
    [[ -d "$sdir" ]] || continue
    SFILE="$sdir/stop.json"
    [[ -f "$SFILE" ]] || continue
    TOTAL=$((TOTAL + 1))
    ST=$(jq -r '.status' "$SFILE")
    case "$ST" in
      pending) PENDING=$((PENDING + 1))
        if [[ "$NEXT_STOP" == "null" ]]; then
          NEXT_STOP=$(jq '{id, sequence, recipient_name, address}' "$SFILE")
        fi
        ;;
      arrived) ARRIVED=$((ARRIVED + 1)) ;;
      delivered) DELIVERED=$((DELIVERED + 1)) ;;
      exception) EXCEPTION=$((EXCEPTION + 1)) ;;
      skipped) SKIPPED=$((SKIPPED + 1)) ;;
    esac
  done
fi

COMPLETED=$((DELIVERED + EXCEPTION + SKIPPED))
if [[ $TOTAL -gt 0 ]]; then
  PCT=$(echo "scale=1; $COMPLETED * 100 / $TOTAL" | bc)
else
  PCT="0"
fi

jq -n \
  --arg rid "$ROUTE_ID" \
  --arg status "$(echo "$ROUTE" | jq -r '.status')" \
  --argjson total "$TOTAL" \
  --argjson pending "$PENDING" \
  --argjson arrived "$ARRIVED" \
  --argjson delivered "$DELIVERED" \
  --argjson exception "$EXCEPTION" \
  --argjson skipped "$SKIPPED" \
  --argjson completed "$COMPLETED" \
  --arg pct "$PCT" \
  --argjson next_stop "$NEXT_STOP" \
  '{
    route_id: $rid,
    status: $status,
    total_stops: $total,
    completed: $completed,
    completion_pct: ($pct | tonumber),
    breakdown: {pending: $pending, arrived: $arrived, delivered: $delivered, exception: $exception, skipped: $skipped},
    next_stop: $next_stop
  }'
