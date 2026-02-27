#!/usr/bin/env bash
# Skip a stop
# Usage: bash tools/routes/stops/skip.sh <route_id> <stop_id> [reason=...]

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

ROUTE_ID="${1:?Usage: skip.sh <route_id> <stop_id> [reason=...]}"
STOP_ID="${2:?Usage: skip.sh <route_id> <stop_id> [reason=...]}"
shift 2

REASON=""
for arg in "$@"; do
  case "$arg" in reason=*) REASON="${arg#*=}" ;; esac
done

STOP_FILE="$PROJECT_ROOT/routes/$ROUTE_ID/stops/$STOP_ID/stop.json"
if [[ ! -f "$STOP_FILE" ]]; then die "Stop '$STOP_ID' not found"; fi

NOW=$(now_iso)
jq --arg now "$NOW" --arg r "$REASON" \
  '.status = "skipped" | .completed_at = $now | .updated = $now | .notes = ((.notes // "") + " Skipped: " + $r)' \
  "$STOP_FILE" > "$STOP_FILE.tmp" && mv "$STOP_FILE.tmp" "$STOP_FILE"

# Update route
ROUTE_FILE="$(entity_file "routes" "$ROUTE_ID")"
jq --arg now "$NOW" '.stops_pending -= 1 | .updated = $now' \
  "$ROUTE_FILE" > "$ROUTE_FILE.tmp" && mv "$ROUTE_FILE.tmp" "$ROUTE_FILE"

info "Skipped stop: $STOP_ID"
cat "$STOP_FILE"
