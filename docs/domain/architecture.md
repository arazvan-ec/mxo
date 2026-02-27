# mxo-track — Domain Architecture

## What is mxo-track?

A last-mile logistics platform. Companies (customers) need to deliver packages to end recipients. mxo-track manages the entire flow: receiving shipments, planning routes, optimizing deliveries, tracking vehicles in real time, confirming deliveries with proof, and reporting.

## Agent-Native Design

This is not a traditional web application. It is an **agent-native system**:

- **Data lives in files** — JSON for structure, Markdown for human-readable content
- **Agents operate on files** — read, create, update, delete entities by working with the filesystem
- **Features are prompts** — route optimization, ETA calculation, billing are defined as operation prompts that agents execute
- **Humans and agents share the workspace** — no separate APIs, same files

## Entity Map

```
customers/{id}/          ← B2B tenant companies
  customer.json          ← Company data, webhook config
  context.md             ← Working memory for this customer
  locations/             ← Embedded: warehouses/depots of this customer

vehicles/{id}/           ← Fleet vehicles
  vehicle.json           ← Plate, type, capacity (weight/volume)
  positions/             ← GPS position history
  context.md

drivers/{id}/            ← Delivery drivers
  driver.json            ← Name, license, assigned vehicle
  context.md

shipments/{id}/          ← Individual deliveries
  shipment.json          ← Reference, recipient, address, coords, tracking token
  events/                ← Lifecycle events (created → picked_up → in_transit → delivered)
  parcels/               ← Embedded: individual parcels (bultos) with weight/volume/EAN
  context.md

services/{id}/           ← Service requests from customers
  service.json           ← Type, customer, parcels summary, status
  context.md

routes/{id}/             ← Planned delivery routes
  route.json             ← Status, driver, vehicle, customer, origin
  stops/                 ← Ordered delivery stops
  optimization_log.md    ← Optimization history
  context.md

tracking/{token}/        ← Public tracking (TRK-XXXX-XXXX)
  tracking.json          ← Shipment ref, timeline, anonymized position

notifications/{id}/      ← Notification events
  notification.json      ← Type, recipient, message, read status

audit/{id}/              ← Audit trail
  audit.json             ← Who, what, when, data

imports/{id}/            ← CSV import runs
  import.json            ← Stats: created, skipped, errors
  source.csv             ← Original uploaded file
```

## Entity Relationships

```
Customer ─────────┬──── has many ──── Shipment
                  ├──── has many ──── Service (service requests)
                  ├──── has many ──── Location (warehouses/depots)
                  └──── assigned ──── Vehicle (N:M via route)

Vehicle ──────────┬──── has many ──── Position (GPS history)
                  └──── assigned to ─ Route

Driver ───────────┬──── drives ────── Vehicle
                  └──── executes ──── Route

Service ──────────┬──── requested by ── Customer
                  ├──── contains ─────── Parcel (bultos: weight, volume, EAN)
                  └──── generates ────── Shipment(s)

Shipment ─────────┬──── belongs to ─── Customer
                  ├──── has many ────── ShipmentEvent (lifecycle)
                  ├──── has many ────── Parcel (bultos)
                  ├──── has one ─────── Tracking (public token)
                  └──── assigned to ─── RouteStop

Route ────────────┬──── has many ────── RouteStop (ordered)
                  ├──── assigned to ─── Driver
                  ├──── uses ────────── Vehicle
                  └──── belongs to ──── Customer

RouteStop ────────┬──── references ──── Shipment
                  └──── has one ─────── Pod (proof of delivery)
```

## Roles and Access

| Role     | Scope                        | Description                                    |
|----------|------------------------------|------------------------------------------------|
| admin    | Everything                   | Full platform management                       |
| operator | Operations subset            | Route planning, fleet monitoring               |
| customer | Own customer_id data only    | View own shipments, routes, tracking           |
| driver   | Own assigned routes only     | Execute routes, confirm deliveries             |
| public   | Single tracking token only   | Track one shipment by TRK-XXXX-XXXX token      |

Roles are defined in `config/roles.json`. Access filtering is a convention agents follow when reading/writing data.

## Business Flow

```
1. INTAKE       → Customer creates a Service request (API/CSV/manual)
2. PARCELS      → Service specifies parcels: weight, volume, EAN per bulto
3. SHIPMENTS    → System generates Shipments from Service (one per delivery address)
4. PLANNING     → Agent creates Route, assigns driver + vehicle, adds stops
5. VALIDATION   → Agent checks vehicle capacity (total weight/volume vs vehicle limits)
6. OPTIMIZATION → Agent optimizes stop order (farthest-first, nearest-neighbor, isochrones)
7. EXECUTION    → Driver starts route (PLANNED → ACTIVE), follows stop sequence
8. DELIVERY     → Driver confirms each stop with POD (signer name, ID, confirmation)
9. EXCEPTION    → If undeliverable: exception type (absent, wrong address, refused, damaged)
10. TRACKING    → Customer sees real-time progress. Recipient tracks via public token
11. CLOSURE     → Driver finishes route (ACTIVE → DONE)
12. REPORTING   → Agent generates billing summary, driver productivity, delivery stats
```

## Service Types

| Type                 | Code              | Description                               |
|----------------------|-------------------|-------------------------------------------|
| Package delivery     | delivery          | Standard A→B delivery                     |
| Delivery + pickup    | delivery_pickup   | Deliver and collect return at same stop    |
| Return/devolution    | return            | Collect package for return to sender       |

Defined in `config/service_types.json`. Extensible — agents can propose new types.

## Key Agent Operations

Operations live in `operations/{operation_name}/` as prompt files that agents execute:

| Operation                | Input                        | Output                        |
|--------------------------|------------------------------|-------------------------------|
| optimize_route           | Route with stops + coords    | Reordered stops, distance saved|
| calculate_eta            | Vehicle position + stops     | ETA per stop                  |
| generate_delivery_note   | Route + stops + parcels      | Albarán (delivery note) .md   |
| import_csv               | CSV file path + customer_id  | Created shipments, import log |
| check_vehicle_capacity   | Vehicle + assigned parcels   | Fit/no-fit + utilization %    |
| calculate_isochrone      | Origin point + time budget   | Reachable area boundary       |
| analyze_driver_productivity | Driver + date range        | Success rate, avg time, ranking|
| billing_summary          | Customer + date range        | Total shipments, delivered, exceptions, cost |
| auto_assign_routes       | Shipments + available vehicles + drivers | Proposed routes    |

## Statuses

### Service Status
`draft` → `confirmed` → `processing` → `completed` → `cancelled`

### Shipment Status
`created` → `picked_up` → `in_transit` → `out_for_delivery` → `delivered` | `exception`

### Route Status
`planned` → `active` → `done` | `cancelled`

### Route Stop Status
`pending` → `delivered` | `exception` | `skipped`

### Parcel Status
`registered` → `loaded` → `in_transit` → `delivered` | `exception` | `returned`

All defined in `config/statuses.json`.

## Customer Frequency Classification

For route optimization, customers are classified by delivery frequency:

| Class           | Code            | Optimization hint                    |
|-----------------|-----------------|--------------------------------------|
| Not frequent    | not_frequent    | Standard delivery windows            |
| Frequent        | frequent        | Prefer consistent time slots         |
| Very frequent   | very_frequent   | Fixed routes, morning/afternoon pref |
| Super frequent  | super_frequent  | Dedicated vehicle/driver assignment   |

## Vehicle Capacity Model

Each vehicle has:
- `max_weight_kg` — Maximum load weight
- `max_volume_m3` — Maximum load volume
- `max_parcels` — Maximum number of parcels (optional)

Before a route starts, the agent validates that total parcels fit the vehicle.

## RGU / Isochrones

A **RGU** (Ruta Geográfica Unitaria) defines a geographic delivery zone based on travel time from an origin.

An **isochrone** is the boundary of all points reachable within a given time budget from an origin, considering road network and speed.

Used for:
- Grouping deliveries into efficient routes
- Ensuring all stops in a route are within driver's time budget
- Measuring driver productivity per zone

Data needed: origin coordinates, time budget (minutes), average speed.
Output: set of reachable coordinates / polygon boundary.
