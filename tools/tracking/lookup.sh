#!/usr/bin/env bash
# Look up a shipment by public tracking token
# Usage: bash tools/tracking/lookup.sh <TRK-XXXX-XXXX>
# Output: Public-safe JSON (no internal IDs, anonymized position)

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

TOKEN="${1:?Usage: lookup.sh <TRK-XXXX-XXXX>}"

# Search all shipments for matching token
FOUND=""
for dir in "$PROJECT_ROOT/shipments"/*/; do
  [[ -d "$dir" ]] || continue
  FILE="$dir/shipment.json"
  [[ -f "$FILE" ]] || continue
  T=$(jq -r '.tracking_token // empty' "$FILE")
  if [[ "$T" == "$TOKEN" ]]; then
    FOUND="$dir"
    break
  fi
done

if [[ -z "$FOUND" ]]; then
  die "Tracking token '$TOKEN' not found"
fi

SHIPMENT=$(cat "$FOUND/shipment.json")
EVENTS="[]"
EVENTS_FILE="$FOUND/events.json"
if [[ -f "$EVENTS_FILE" ]]; then
  EVENTS=$(cat "$EVENTS_FILE")
fi

# Build public response (no internal IDs)
jq -n \
  --arg token "$TOKEN" \
  --arg status "$(echo "$SHIPMENT" | jq -r '.status')" \
  --arg recipient "$(echo "$SHIPMENT" | jq -r '.recipient_name')" \
  --arg address "$(echo "$SHIPMENT" | jq -r '.address')" \
  --arg reference "$(echo "$SHIPMENT" | jq -r '.reference')" \
  --arg service "$(echo "$SHIPMENT" | jq -r '.service_type')" \
  --argjson packages "$(echo "$SHIPMENT" | jq '.total_packages')" \
  --arg dw_start "$(echo "$SHIPMENT" | jq -r '.delivery_window_start // "N/A"')" \
  --arg dw_end "$(echo "$SHIPMENT" | jq -r '.delivery_window_end // "N/A"')" \
  --arg est_delivery "$(echo "$SHIPMENT" | jq -r '.estimated_delivery_date // "N/A"')" \
  --argjson events "$EVENTS" \
  '{
    tracking_token: $token,
    reference: $reference,
    status: $status,
    recipient_name: $recipient,
    address: $address,
    service_type: $service,
    total_packages: $packages,
    delivery_window: {start: $dw_start, end: $dw_end},
    estimated_delivery: $est_delivery,
    timeline: [$events[] | {type, timestamp, description}]
  }'
