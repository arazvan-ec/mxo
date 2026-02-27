#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
ID="${1:?Usage: read.sh <service_id>}"
if ! entity_exists "services" "$ID"; then die "Service '$ID' not found"; fi
read_json "$(entity_file "services" "$ID")"
