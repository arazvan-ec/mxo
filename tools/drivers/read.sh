#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: read.sh <driver_id>}"
if ! entity_exists "drivers" "$ID"; then die "Driver '$ID' not found"; fi
read_json "$(entity_file "drivers" "$ID")"
