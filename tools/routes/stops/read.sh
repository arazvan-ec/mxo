#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
ROUTE_ID="${1:?Usage: read.sh <route_id> <stop_id>}"
STOP_ID="${2:?Usage: read.sh <route_id> <stop_id>}"
STOP_FILE="$PROJECT_ROOT/routes/$ROUTE_ID/stops/$STOP_ID/stop.json"
if [[ ! -f "$STOP_FILE" ]]; then die "Stop '$STOP_ID' not found in route '$ROUTE_ID'"; fi
cat "$STOP_FILE"
