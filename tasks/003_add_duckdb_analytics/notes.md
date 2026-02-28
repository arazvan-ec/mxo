# 003 — Add DuckDB Analytics Layer

## Why DuckDB over SQLite

| Criterio | DuckDB | SQLite |
|----------|--------|--------|
| Queries analíticas (GROUP BY, SUM, AVG) | Optimizado (columnar) | Lento en datasets grandes |
| Lee JSON directamente | `read_json('shipments/*/shipment.json')` | Requiere importar datos |
| Infraestructura | Zero — embedded | Zero — embedded |
| Python | `import duckdb` nativo | Necesita sqlite3 + schema |
| Agent-native fit | Alto — JSON sigue siendo fuente de verdad | Medio — duplica datos |

## Architecture

```
┌─────────────────────────────────────────────┐
│               Agent / User                   │
├──────────────┬──────────────────────────────┤
│  CRUD ops    │  Analytics / Reports          │
│  (JSON files)│  (DuckDB over JSON)           │
├──────────────┼──────────────────────────────┤
│  shipments/  │  tools/db/query.py            │
│  drivers/    │  tools/db/views.sql           │
│  zones/      │                               │
│  routes/     │  SELECT * FROM                │
│  (filesystem)│  read_json('entity/*/e.json') │
└──────────────┴──────────────────────────────┘
```

## Plan (micro-steps)

### Step 1 — DuckDB query wrapper
- `tools/db/query.py`: función `query(sql: str) -> list[dict]`
- Usa DuckDB in-memory, lee JSON con `read_json_auto`
- Commit + push

### Step 2 — Predefined views
- `tools/db/views.sql`: vistas SQL para queries comunes
  - `shipment_stats` — conteo por estado, zona, fecha
  - `driver_performance` — entregas por conductor, tasa éxito
  - `cost_analysis` — costo promedio por zona, tipo
  - `daily_trends` — volumen y éxito por día
- Commit + push

### Step 3 — Refactor reports
- Migrar reportes existentes de recorrido manual de ficheros a DuckDB queries
- Verificar que resultados sean idénticos
- Commit + push

### Step 4 — Documentation
- Actualizar `tasks/context.md`
- Crear `agent_log.md` con decisiones
- Commit + push
