# Operation: Generate Delivery Note (Albarán)

## Objective

Create a human-readable delivery note document for a route, listing all stops, parcels, recipient information, and totals. This document is what the driver carries (printed or digital) during execution.

## When to Use

- After route planning is complete and before route starts
- When driver needs a printed manifest
- When customer requests a delivery summary

## Inputs

1. Read `routes/{route_id}/route.json` for route details
2. Read all stops from `routes/{route_id}/stops/`
3. For each stop, read the linked shipment from `shipments/{shipment_id}/shipment.json`
4. For each shipment, read parcels from `parcels/` that match `parcel_ids`
5. Read driver from `drivers/{driver_id}/driver.json`
6. Read vehicle from `vehicles/{vehicle_id}/vehicle.json`
7. Read customer from `customers/{customer_id}/customer.json`

## Output Format

Write to `routes/{route_id}/delivery_note.md`:

```markdown
# Albarán de Entrega

**Ruta**: {route.name}
**Fecha**: {route.planned_date}
**Cliente**: {customer.name}
**Conductor**: {driver.name}
**Vehículo**: {vehicle.name} ({vehicle.plate})
**Origen**: {route.origin_address}

---

## Resumen

| Concepto       | Valor              |
|----------------|--------------------|
| Total paradas  | {total_stops}      |
| Total bultos   | {total_parcels}    |
| Peso total     | {total_weight} kg  |
| Volumen total  | {total_volume} m³  |
| Capacidad peso | {weight_util}%     |
| Capacidad vol. | {volume_util}%     |
| Distancia est. | {distance} km      |

---

## Paradas

### Parada {n}: {recipient_name}
- **Dirección**: {address}
- **Referencia**: {shipment.reference}
- **Bultos**: {parcel_count}
  - {parcel.sequence}: {weight}kg, {volume}m³ {ean if present}
- **Ventana**: {delivery_window if set}
- **ETA**: {eta if calculated}
- **Notas**: {notes if any}
- **Estado**: [ ] Entregado  [ ] Excepción  [ ] Omitido

---

## Firma

Conductor: ________________  Fecha: ________________
```

## Constraints

- Include ALL stops in route order (by sequence)
- Show parcel details for each stop
- Calculate totals (weight, volume, parcel count)
- Include capacity utilization percentages

## Success Criteria

- `delivery_note.md` created with all stops and parcels
- Totals are mathematically correct
- Document is immediately usable by a driver
