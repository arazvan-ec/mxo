# Task 002: Implement mxo-track logistics platform

## Overview

Build the complete mxo-track last-mile logistics platform using agent-native architecture:
- **Data**: File-based entity directories (JSON + Markdown)
- **Tools**: Atomic bash+jq scripts for CRUD, Python for calculations
- **Features**: Composable through prompts, not hardcoded workflows

## Phases

1. Schemas and base structure (8 commits)
2. CRUD tools for all entities (10 commits)
3. Package and shipment event management (3 commits)
4. CSV import (3 commits)
5. Route optimization with capacity (5 commits)
6. Route execution workflow (4 commits)
7. Tracking, notifications, reporting (7 commits)
8. Advanced features: zones, frequency, costs (7 commits)

## Key Decisions

- **Flexible event types**: Shipment events not enforced as rigid enum (emergent capability)
- **Stack**: bash + jq + Python (serves agent-native best)
- **No database**: Files as universal interface
- **Tool contract**: args as key=value, stdout=JSON, stderr=errors, exit 0/1
