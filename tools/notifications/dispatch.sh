#!/usr/bin/env bash
# Dispatch a webhook notification to a customer's webhook URL
# Usage: bash tools/notifications/dispatch.sh <customer_id> event_type=<type> payload=<json>
# Signs payload with HMAC-SHA256 using customer's webhook_secret

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CUSTOMER_ID="${1:?Usage: dispatch.sh <customer_id> event_type=<type> payload=<json>}"
shift

DATA=$(args_to_json "$@")
validate_required "$DATA" "event_type" || exit 1

if ! entity_exists "customers" "$CUSTOMER_ID"; then
  die "Customer '$CUSTOMER_ID' not found"
fi

CUSTOMER=$(read_json "$(entity_file "customers" "$CUSTOMER_ID")")
WEBHOOK_URL=$(echo "$CUSTOMER" | jq -r '.webhook_url // empty')
WEBHOOK_SECRET=$(echo "$CUSTOMER" | jq -r '.webhook_secret // empty')

if [[ -z "$WEBHOOK_URL" ]]; then
  info "No webhook URL configured for customer $CUSTOMER_ID"
  jq -n --arg cid "$CUSTOMER_ID" '{dispatched: false, reason: "No webhook URL configured", customer_id: $cid}'
  exit 0
fi

NOW=$(now_iso)
EVENT_TYPE=$(echo "$DATA" | jq -r '.event_type')
PAYLOAD=$(echo "$DATA" | jq -r '.payload // "{}"')

# Build webhook body
BODY=$(jq -n \
  --arg evt "$EVENT_TYPE" \
  --arg ts "$NOW" \
  --arg cid "$CUSTOMER_ID" \
  --argjson payload "$PAYLOAD" \
  '{event_type: $evt, timestamp: $ts, customer_id: $cid, data: $payload}')

# Calculate HMAC signature
SIGNATURE=""
if [[ -n "$WEBHOOK_SECRET" ]]; then
  SIGNATURE=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -binary | xxd -p -c 256 2>/dev/null || echo "")
fi

# Log dispatch (actual HTTP call would go here in production)
DISPATCH_LOG="$PROJECT_ROOT/notifications/dispatch_log.jsonl"
ENTRY=$(jq -n \
  --arg url "$WEBHOOK_URL" \
  --arg sig "$SIGNATURE" \
  --arg ts "$NOW" \
  --arg evt "$EVENT_TYPE" \
  --arg cid "$CUSTOMER_ID" \
  '{timestamp: $ts, customer_id: $cid, event_type: $evt, webhook_url: $url, signature: $sig, status: "logged"}')
echo "$ENTRY" >> "$DISPATCH_LOG"

info "Dispatched webhook: $EVENT_TYPE to $WEBHOOK_URL"
echo "$ENTRY" | jq '.'
