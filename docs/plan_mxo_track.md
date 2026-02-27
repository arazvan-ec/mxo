# Plan: mxo-track — Plataforma logística agent-native

## Contexto

Plataforma SaaS de logística de última milla. Gestiona flotas de vehículos, planifica rutas de entrega, tracking GPS y pruebas de entrega. Arquitectura agent-native: archivos como interfaz universal, herramientas atómicas, features como prompts.

## Entidades

| Entidad | Directorio | Descripción |
|---------|-----------|-------------|
| Customer | `customers/{id}/` | Empresa cliente (nombre, dirección, teléfono, webhook) |
| Vehicle | `vehicles/{id}/` | Vehículo de flota (placa, capacidad kg/m3) |
| Driver | `drivers/{id}/` | Conductor (nombre, email, teléfono) |
| Service | `services/{type}/` | Tipo de servicio (entrega, entrega+recogida, devolución) |
| Shipment | `shipments/{id}/` | Envío con paquetes (peso, volumen, EAN) |
| Route | `routes/{id}/` | Ruta con paradas asignadas |
| RouteStop | `routes/{id}/stops/{stop_id}/` | Parada individual |
| ImportRun | `imports/{id}/` | Registro de importación CSV |
| Notification | `notifications/{id}/` | Notificación de estado |
| Zone | `zones/{id}/` | Zona geográfica (RGU/isocrona) |
| Report | `reports/{id}/` | Reporte generado |

## Herramientas

Cada herramienta es un script atómico en `tools/`. Contrato:
- Argumentos: `<entity_id> [campo=valor ...]`
- stdout: JSON
- stderr: errores
- Exit: 0=ok, 1=error

## Fases (47 commits)

1. **Schemas y estructura** (8 commits)
2. **CRUD tools** (10 commits)
3. **Packages y eventos** (3 commits)
4. **CSV import** (3 commits)
5. **Optimización rutas** (5 commits)
6. **Ejecución de ruta** (4 commits)
7. **Tracking y reporting** (7 commits)
8. **Avanzado** (7 commits)
