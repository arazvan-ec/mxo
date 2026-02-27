#!/usr/bin/env bash
# Record exception at stop
# Usage: bash tools/routes/stops/exception.sh <route_id> <stop_id> type=<exception_type> [reason=...]
# Exception types: ausente, direccion_incorrecta, rechazado, danado, otro

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

ROUTE_ID="${1:?Usage: exception.sh <route_id> <stop_id> type=<type> [reason=...]}"
STOP_ID="${2:?Usage: exception.sh <route_id> <stop_id> type=<type> [reason=...]}"
shift 2

EXC_DATA=$(args_to_json "$@")
validate_required "$EXC_DATA" "type" || exit 1

STOP_FILE="$PROJECT_ROOT/routes/$ROUTE_ID/stops/$STOP_ID/stop.json"
if [[ ! -f "$STOP_FILE" ]]; then die "Stop '$STOP_ID' not found"; fi

STATUS=$(jq -r '.status' "$STOP_FILE")
if [[ "$STATUS" != "pending" && "$STATUS" != "arrived" ]]; then
  die "Stop status is '$STATUS', expected 'pending' or 'arrived'"
fi

NOW=$(now_iso)
EXC=$(echo "$EXC_DATA" | jq --arg ts "$NOW" '. + {timestamp: $ts}')

jq --argjson exc "$EXC" --arg now "$NOW" \
  '.status = "exception" | .exception = $exc | .completed_at = $now | .updated = $now' \
  "$STOP_FILE" > "$STOP_FILE.tmp" && mv "$STOP_FILE.tmp" "$STOP_FILE"

# Update shipment event
SID=$(jq -r '.shipment_id // empty' "$STOP_FILE")
EXC_TYPE=$(echo "$EXC_DATA" | jq -r '.type')
if [[ -n "$SID" ]] && entity_exists "shipments" "$SID"; then
  bash "$(dirname "${BASH_SOURCE[0]}")/../../shipments/events/add.sh" "$SID" type=EXCEPTION "description=Exception: $EXC_TYPE at stop $STOP_ID" >/dev/null 2>&1
fi

# Update route counts
ROUTE_FILE="$(entity_file "routes" "$ROUTE_ID")"
jq --arg now "$NOW" '.stops_exception += 1 | .stops_pending -= 1 | .updated = $now' \
  "$ROUTE_FILE" > "$ROUTE_FILE.tmp" && mv "$ROUTE_FILE.tmp" "$ROUTE_FILE"

# Log
LOG="$PROJECT_ROOT/routes/$ROUTE_ID/execution_log.md"
REASON=$(echo "$EXC_DATA" | jq -r '.reason // "N/A"')
echo -e "\n## $NOW — Exception: $STOP_ID\n\nType: $EXC_TYPE\nReason: $REASON\n" >> "$LOG"

info "Exception at stop: $STOP_ID ($EXC_TYPE)"
cat "$STOP_FILE"
