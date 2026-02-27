#!/usr/bin/env bash
# Generate a Markdown report for an import run
# Usage: bash tools/imports/report.sh <import_id>
# Output: Markdown report to stdout

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: report.sh <import_id>}"

if ! entity_exists "imports" "$ID"; then die "Import '$ID' not found"; fi

IMPORT=$(cat "$(entity_dir "imports" "$ID")/import.json")

CID=$(echo "$IMPORT" | jq -r '.customer_id')
FNAME=$(echo "$IMPORT" | jq -r '.filename')
STATUS=$(echo "$IMPORT" | jq -r '.status')
TOTAL=$(echo "$IMPORT" | jq '.total_rows')
CREATED=$(echo "$IMPORT" | jq '.created_count')
SKIPPED=$(echo "$IMPORT" | jq '.skipped_count')
ERRORS=$(echo "$IMPORT" | jq '.error_count')
CREATED_AT=$(echo "$IMPORT" | jq -r '.created')
COMPLETED_AT=$(echo "$IMPORT" | jq -r '.completed_at // "N/A"')

cat <<EOF
# Import Report: $ID

| Field | Value |
|-------|-------|
| Customer | $CID |
| File | $FNAME |
| Status | $STATUS |
| Started | $CREATED_AT |
| Completed | $COMPLETED_AT |

## Summary

| Metric | Count |
|--------|-------|
| Total rows | $TOTAL |
| Created | $CREATED |
| Skipped (duplicates) | $SKIPPED |
| Errors | $ERRORS |

**Success rate**: $(echo "scale=1; $CREATED * 100 / ($TOTAL + 1)" | bc 2>/dev/null || echo "N/A")%
EOF

# List errors if any
if [[ "$ERRORS" -gt 0 ]]; then
  echo ""
  echo "## Errors"
  echo ""
  echo "| Row | Field | Message |"
  echo "|-----|-------|---------|"
  echo "$IMPORT" | jq -r '.errors[]? | "| \(.row) | \(.field) | \(.message) |"'
fi

# List created shipment IDs
SHIP_COUNT=$(echo "$IMPORT" | jq '.shipment_ids | length')
if [[ "$SHIP_COUNT" -gt 0 ]]; then
  echo ""
  echo "## Created Shipments ($SHIP_COUNT)"
  echo ""
  echo "$IMPORT" | jq -r '.shipment_ids[]' | while read -r sid; do
    echo "- \`$sid\`"
  done
fi
