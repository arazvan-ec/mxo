#!/usr/bin/env bash
# Mark driver arrived at stop
# Usage: bash tools/routes/stops/arrive.sh <route_id> <stop_id>

source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

ROUTE_ID="${1:?Usage: arrive.sh <route_id> <stop_id>}"
STOP_ID="${2:?Usage: arrive.sh <route_id> <stop_id>}"

STOP_FILE="$PROJECT_ROOT/routes/$ROUTE_ID/stops/$STOP_ID/stop.json"
if [[ ! -f "$STOP_FILE" ]]; then die "Stop '$STOP_ID' not found"; fi

STATUS=$(jq -r '.status' "$STOP_FILE")
if [[ "$STATUS" != "pending" ]]; then die "Stop status is '$STATUS', expected 'pending'"; fi

NOW=$(now_iso)
jq --arg now "$NOW" '.status = "arrived" | .arrived_at = $now | .updated = $now' "$STOP_FILE" > "$STOP_FILE.tmp" && mv "$STOP_FILE.tmp" "$STOP_FILE"

info "Arrived at stop: $STOP_ID"
cat "$STOP_FILE"
