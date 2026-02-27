#!/usr/bin/env bash
# Create a notification
# Usage: bash tools/notifications/notify.sh customer_id=<cid> type=<type> title=<title> message=<msg>

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

DATA=$(args_to_json "$@")
validate_required "$DATA" "customer_id" "type" "title" "message" || exit 1

ID=$(generate_id)
NOW=$(now_iso)
DATA=$(echo "$DATA" | jq --arg id "$ID" --arg now "$NOW" \
  '.id = $id | .created = $now | .read = false')

create_entity_dir "notifications" "$ID" >/dev/null
write_json "$PROJECT_ROOT/notifications/$ID/notification.json" "$DATA"

info "Created notification: $ID"
echo "$DATA" | jq '.'
