#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: read.sh <route_id>}"
if ! entity_exists "routes" "$ID"; then die "Route '$ID' not found"; fi
read_json "$(entity_file "routes" "$ID")"
