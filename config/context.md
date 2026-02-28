# Config — Context

## Purpose

Configuration files define the platform's reference data: roles, service types, statuses, vehicle types. These are not entity instances — they are schemas and definitions that entities reference.

## Files

| File               | Purpose                                            |
|--------------------|----------------------------------------------------|
| roles.json         | Role definitions and access scopes                 |
| service_types.json | Types of logistics services (delivery, return, etc)|
| statuses.json      | All status values and valid transitions per entity  |
| vehicle_types.json | Vehicle type templates with capacity defaults       |
| optimization.json  | Route optimization strategies, RGU params, defaults |

## Design Decisions

- **Statuses include transitions** — agents can validate that a status change is legal by checking the transitions map
- **Vehicle types are templates** — individual vehicles reference a type but can override capacity values
- **Roles define scope** — agents filter data access based on scope field (global, customer_id, driver_id, tracking_token)
- **Service types are extensible** — new types can be added without code changes

## How Agents Use Config

1. Read `config/statuses.json` before changing any entity status to validate the transition
2. Read `config/roles.json` to determine what data a user/agent can access
3. Read `config/vehicle_types.json` when creating a vehicle to apply default capacity
4. Read `config/service_types.json` when creating a service to validate the type
5. Read `config/optimization.json` for route optimization strategy defaults, RGU parameters, and auto-selection rules
