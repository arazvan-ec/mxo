#!/usr/bin/env bash
# Read a customer by ID
# Usage: bash tools/customers/read.sh <customer_id>
# Output: JSON of customer

source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ID="${1:?Usage: read.sh <customer_id>}"

if ! entity_exists "customers" "$ID"; then
  die "Customer '$ID' not found"
fi

read_json "$(entity_file "customers" "$ID")"
