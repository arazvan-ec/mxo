#!/usr/bin/env bash
# Complete a route (ACTIVE → DONE)
# Usage: bash tools/routes/complete.sh <route_id>

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ROUTE_ID="${1:?Usage: complete.sh <route_id>}"

if ! entity_exists "routes" "$ROUTE_ID"; then die "Route '$ROUTE_ID' not found"; fi

ROUTE_FILE="$(entity_file "routes" "$ROUTE_ID")"
ROUTE=$(read_json "$ROUTE_FILE")
STATUS=$(echo "$ROUTE" | jq -r '.status')

if [[ "$STATUS" != "active" ]]; then
  die "Cannot complete route with status '$STATUS' (must be active)"
fi

NOW=$(now_iso)

# Recalculate final counts
bash "$(dirname "${BASH_SOURCE[0]}")/recalculate.sh" "$ROUTE_ID" >/dev/null 2>&1

ROUTE=$(read_json "$ROUTE_FILE")
ROUTE=$(echo "$ROUTE" | jq --arg now "$NOW" '.status = "done" | .completed_at = $now | .updated = $now')
write_json "$ROUTE_FILE" "$ROUTE"

# Log
LOG_FILE="$PROJECT_ROOT/routes/$ROUTE_ID/execution_log.md"
DELIVERED=$(echo "$ROUTE" | jq '.stops_delivered // 0')
EXCEPTIONS=$(echo "$ROUTE" | jq '.stops_exception // 0')
echo -e "\n## $NOW — Route Completed\n\nStatus: ACTIVE → DONE\nDelivered: $DELIVERED | Exceptions: $EXCEPTIONS\n" >> "$LOG_FILE"

info "Completed route: $ROUTE_ID (delivered: $DELIVERED, exceptions: $EXCEPTIONS)"
echo "$ROUTE" | jq '.'
