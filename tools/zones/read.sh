#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: read.sh <zone_id>}"
if ! entity_exists "zones" "$ID"; then die "Zone '$ID' not found"; fi
read_json "$(entity_file "zones" "$ID")"
