#!/usr/bin/env bash
# Seed predefined service types
# Usage: bash seeds/services.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

create_service() {
  local id="$1"
  local name="$2"
  local type="$3"
  local desc="$4"
  local pickup="$5"
  local ret="$6"
  local signature="$7"

  local dir="$PROJECT_ROOT/services/$id"
  mkdir -p "$dir"

  cat > "$dir/service.json" <<ENDJSON
{
  "id": "$id",
  "name": "$name",
  "type": "$type",
  "description": "$desc",
  "requires_pickup": $pickup,
  "requires_return": $ret,
  "requires_signature": $signature,
  "estimated_stop_time_min": 2,
  "package_requirements": {
    "weight_required": true,
    "volume_required": true,
    "ean_required": false,
    "description_required": false
  },
  "created": "$NOW",
  "updated": "$NOW"
}
ENDJSON

  echo "Created service: $id ($name)"
}

create_service "entrega" \
  "Paquetería Entrega" \
  "entrega" \
  "Standard delivery from origin to destination" \
  false false true

create_service "entrega_recogida" \
  "Paquetería Entrega y Recogida" \
  "entrega_recogida" \
  "Deliver packages and pick up items at destination" \
  true false true

create_service "devolucion" \
  "Paquetería Devolución" \
  "devolucion" \
  "Return shipment from destination back to origin" \
  false true true

echo "Done. 3 service types seeded."
