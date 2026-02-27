#!/usr/bin/env bash
# Create an import run record
# Usage: bash tools/imports/create.sh customer_id=<cid> filename=<name>

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
DATA=$(args_to_json "$@")
ID=$(echo "$DATA" | jq -r '.id // empty')
if [[ -z "$ID" ]]; then ID=$(generate_id); DATA=$(echo "$DATA" | jq --arg id "$ID" '.id = $id'); fi
validate_required "$DATA" "customer_id" "filename" || exit 1
if entity_exists "imports" "$ID"; then die "Import '$ID' already exists"; fi
NOW=$(now_iso)
DATA=$(echo "$DATA" | jq --arg now "$NOW" \
  '.created //= $now | .status //= "pending" | .total_rows //= 0 | .created_count //= 0 | .skipped_count //= 0 | .error_count //= 0 | .errors //= [] | .shipment_ids //= []')
create_entity_dir "imports" "$ID" >/dev/null
write_json "$(entity_file "imports" "$ID" "import")" "$DATA"
info "Created import: $ID"
echo "$DATA" | jq '.'
