#!/usr/bin/env bash
# Common library for mxo-track tools
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

set -euo pipefail

# Project root (two levels up from tools/lib/)
TOOLS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "$TOOLS_LIB_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$TOOLS_DIR/.." && pwd)"

# ── ID Generation ──────────────────────────────────────────────────────────

generate_id() {
  # Generate a short unique ID: timestamp hex + random hex (12 chars)
  local ts
  ts=$(printf '%08x' "$(date +%s)")
  local rand
  rand=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')
  echo "${ts}${rand}"
}

generate_tracking_token() {
  # Generate TRK-XXXX-XXXX format token
  local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local part1="" part2=""
  for _ in $(seq 1 4); do
    part1+="${chars:$((RANDOM % ${#chars})):1}"
    part2+="${chars:$((RANDOM % ${#chars})):1}"
  done
  echo "TRK-${part1}-${part2}"
}

# ── Timestamps ─────────────────────────────────────────────────────────────

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ── JSON Helpers (require jq) ──────────────────────────────────────────────

check_jq() {
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
  fi
}

# Parse key=value arguments into a JSON object
# Usage: args_to_json "name=Acme" "phone=+34600"
args_to_json() {
  check_jq
  local json="{}"
  for arg in "$@"; do
    local key="${arg%%=*}"
    local val="${arg#*=}"
    # Only parse as native JSON for: pure numbers (no +prefix), booleans, null, arrays, objects
    if [[ "$val" =~ ^-?[0-9]+\.?[0-9]*$ ]] || [[ "$val" == "true" ]] || [[ "$val" == "false" ]] || [[ "$val" == "null" ]] || [[ "$val" == \[* ]] || [[ "$val" == \{* ]]; then
      json=$(echo "$json" | jq --arg k "$key" --argjson v "$val" '.[$k] = $v' 2>/dev/null) || \
      json=$(echo "$json" | jq --arg k "$key" --arg v "$val" '.[$k] = $v')
    else
      json=$(echo "$json" | jq --arg k "$key" --arg v "$val" '.[$k] = $v')
    fi
  done
  echo "$json"
}

# Read a JSON file, exit with error if not found
read_json() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file" >&2
    return 1
  fi
  cat "$file"
}

# Write JSON to file (pretty-printed)
write_json() {
  local file="$1"
  local json="$2"
  check_jq
  echo "$json" | jq '.' > "$file"
}

# Merge JSON: base + overlay
merge_json() {
  local base="$1"
  local overlay="$2"
  check_jq
  echo "$base" | jq --argjson o "$overlay" '. * $o'
}

# ── Entity Helpers ─────────────────────────────────────────────────────────

# Get entity directory path
entity_dir() {
  local entity_type="$1"
  local entity_id="$2"
  echo "$PROJECT_ROOT/$entity_type/$entity_id"
}

# Get entity JSON file path
entity_file() {
  local entity_type="$1"
  local entity_id="$2"
  local filename="${3:-$(basename "$entity_type" | sed 's/s$//')}.json"
  echo "$(entity_dir "$entity_type" "$entity_id")/$filename"
}

# Check if entity exists
entity_exists() {
  local entity_type="$1"
  local entity_id="$2"
  [[ -d "$(entity_dir "$entity_type" "$entity_id")" ]]
}

# Create entity directory
create_entity_dir() {
  local entity_type="$1"
  local entity_id="$2"
  local dir
  dir="$(entity_dir "$entity_type" "$entity_id")"
  mkdir -p "$dir"
  echo "$dir"
}

# List all entity IDs for a type
list_entity_ids() {
  local entity_type="$1"
  local base_dir="$PROJECT_ROOT/$entity_type"
  if [[ ! -d "$base_dir" ]]; then
    echo "[]"
    return
  fi
  local ids=()
  for dir in "$base_dir"/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"
    # Skip context.md and other non-entity files
    [[ "$name" == "context.md" ]] && continue
    ids+=("$name")
  done
  printf '%s\n' "${ids[@]}" | jq -R '.' | jq -s '.'
}

# ── Validation ─────────────────────────────────────────────────────────────

# Check required fields in JSON
validate_required() {
  local json="$1"
  shift
  check_jq
  for field in "$@"; do
    local val
    val=$(echo "$json" | jq -r --arg f "$field" '.[$f] // empty')
    if [[ -z "$val" ]]; then
      echo "Error: required field '$field' is missing" >&2
      return 1
    fi
  done
}

# ── Output Helpers ─────────────────────────────────────────────────────────

# Print error to stderr and exit
die() {
  echo "Error: $*" >&2
  exit 1
}

# Print info to stderr (non-JSON output)
info() {
  echo "$*" >&2
}
