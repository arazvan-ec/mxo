#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
ROUTE_ID="${1:?Usage: update.sh <route_id> <stop_id> [field=value ...]}"
STOP_ID="${2:?Usage: update.sh <route_id> <stop_id> [field=value ...]}"
shift 2
STOP_FILE="$PROJECT_ROOT/routes/$ROUTE_ID/stops/$STOP_ID/stop.json"
if [[ ! -f "$STOP_FILE" ]]; then die "Stop '$STOP_ID' not found in route '$ROUTE_ID'"; fi
CURRENT=$(cat "$STOP_FILE")
UPDATES=$(args_to_json "$@")
NOW=$(now_iso)
MERGED=$(merge_json "$CURRENT" "$UPDATES" | jq --arg now "$NOW" '.updated = $now')
write_json "$STOP_FILE" "$MERGED"
info "Updated stop: $STOP_ID"
echo "$MERGED" | jq '.'
