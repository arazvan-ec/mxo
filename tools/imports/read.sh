#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: read.sh <import_id>}"
if ! entity_exists "imports" "$ID"; then die "Import '$ID' not found"; fi
read_json "$(entity_dir "imports" "$ID")/import.json"
