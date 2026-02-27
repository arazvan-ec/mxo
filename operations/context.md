# Operations — Context

## Purpose

Operations are the **agent-native feature layer**. Instead of hardcoded business logic, each capability is defined as a prompt that agents execute by reading input data, applying reasoning, and writing output data.

This is the key to **composability**: new features emerge from prompt descriptions, not code changes. An agent reads the operation prompt, understands the inputs and expected outputs, and performs the work using the file system.

## Directory Structure

```
operations/{operation_name}/
├── prompt.md             # The operation definition (what, why, how, inputs, outputs)
├── examples/             # Example inputs and outputs for the agent to learn from
│   ├── example_01_input.json
│   └── example_01_output.json
└── context.md            # Working memory (refinements, lessons learned)
```

## How Operations Work

1. An agent (or human) identifies a need (e.g., "optimize this route")
2. Agent reads `operations/optimize_route/prompt.md`
3. Agent reads the input data from entity files
4. Agent executes the operation following the prompt instructions
5. Agent writes the output data back to entity files
6. Agent logs the operation in relevant `agent_log.md` or `context.md` files

## Design Principles

- **Prompts, not code** — The operation logic lives in natural language, not in functions
- **Composable** — Operations can call other operations (e.g., auto_assign_routes calls optimize_route and check_vehicle_capacity)
- **Improvable** — When an operation produces suboptimal results, refine the prompt, don't rewrite code
- **Emergent** — Agents can combine operations in ways not explicitly planned
- **Documented** — Each operation prompt clearly states inputs, outputs, and constraints

## Available Operations

| Operation                  | Description                                       |
|----------------------------|---------------------------------------------------|
| optimize_route             | Reorder route stops to minimize distance           |
| calculate_eta              | Calculate ETAs for pending stops                   |
| generate_delivery_note     | Create albarán document for a route               |
| import_csv                 | Process CSV upload into services/shipments         |
| check_vehicle_capacity     | Validate parcels fit in assigned vehicle           |
| calculate_isochrone        | Compute reachable area from origin within time     |
| analyze_driver_productivity| Generate driver performance report                |
| billing_summary            | Generate billing report for a customer             |
| auto_assign_routes         | Create routes from unassigned shipments            |

## Improvement Over Time

After each operation execution, agents should:
1. Note what worked well and what didn't in `operations/{name}/context.md`
2. If the prompt produced suboptimal results, suggest refinements
3. Add new examples to `examples/` from real executions
