# mxo-track: Tech Stack Recommendation

## What Already Exists

The codebase already has a working foundation:

- **Backend**: Hono framework on Node.js with TypeScript (~600 lines across 7 source files)
- **Storage**: Generic file-based CRUD engine (`file_store.ts`) — directories as entities, JSON files as records
- **API Surface**: Full REST API with discovery, CRUD factory, sub-entity support, status transition validation, role-based auth, tenant filtering
- **Operations**: 9 agent operations defined as prompt files (Markdown, not code)
- **ID Generation**: Custom ULID implementation (time-sortable, Crockford Base32)
- **Zero external dependencies** beyond Hono and its Node.js adapter

---

## Decision 1: Backend Framework

### Recommendation: **Keep Hono**

The existing `crud_factory.ts` + `file_store.ts` + `entities.ts` pattern is a working generic engine. Switching frameworks means rewriting for zero functional gain.

- At 14KB, Hono adds almost nothing. The codebase has 3 dependencies total.
- Hono runs everywhere (Node.js, Cloudflare Workers, Deno, Bun).
- The middleware pattern (auth, tenant filter) is clean and idiomatic.

| Alternative | Why rejected |
|---|---|
| **Fastify** | Heavier, plugin ecosystem not needed. Faster JSON serialization irrelevant when bottleneck is filesystem I/O. Full rewrite required. |
| **NestJS** | Over-engineered. Decorators, DI, modules add ceremony contradicting agent-native simplicity. |
| **Go (Gin/Chi)** | Breaks full-TypeScript strategy. Performance advantage irrelevant at 10-50 clients. |
| **Elixir (Phoenix)** | Different runtime/deployment/language. Real-time better added as focused component. |

---

## Decision 2: Real-Time Layer

### Recommendation: **SSE for dashboards/tracking + WebSocket for driver app**

```
                    SSE (one-way)
  Dashboard/Customer ←──────────── Hono API ←── fs.watch on entity dirs
  Tracking Page      ←────────────

                    WebSocket (bidirectional)
  Driver App         ←──────────→ Dedicated WS endpoint ←── fs.watch
```

**SSE for dashboards/tracking** because:
- Tracking is read-only. SSE is simpler, works through proxies/CDNs, auto-reconnects.
- Node.js `chokidar` watches entity directories. When a JSON file changes, the watcher pushes via SSE.
- Hono supports SSE natively via `hono/streaming`. No additional dependency.

**WebSocket for driver app** because:
- Drivers send GPS coordinates AND receive route updates — bidirectional.

**Endpoints to add:**
- `GET /api/stream/{entity}/{id}` — SSE for specific entity
- `GET /api/stream/tracking/{token}` — SSE for public tracking
- `WS /api/ws/driver/{driver_id}` — WebSocket for driver

| Alternative | Why rejected |
|---|---|
| **Socket.io** | 300KB+ client library, unnecessary fallback transports. |
| **Redis Pub/Sub** | Non-file dependency. The filesystem IS the pub/sub. |
| **MQTT** | Adds broker dependency. Only justified at thousands of vehicles. |

---

## Decision 3: Storage Strategy

### Recommendation: **Files as source of truth + SQLite as read-only query index**

This is the most critical architectural decision.

**The problem:** `listAll` reads every entity directory and parses every JSON file. At 10,000+ shipments/day, this is a performance wall.

**The solution:** SQLite is literally a file — philosophically compatible with files-as-universal-interface.

```
Source of truth:  shipments/{id}/shipment.json   (always authoritative)
Query index:      data/index.sqlite               (derived, rebuildable)
```

**How it works:**
1. **Write path**: When `file_store.ts` creates/updates a JSON file, it ALSO updates the SQLite index row.
2. **Read path**: `getById` still reads JSON directly. `listAll` with filters queries SQLite for matching IDs, then reads only those JSON files.
3. **Rebuildable**: A `rebuild-index` operation can repopulate SQLite from JSON files. If deleted, system falls back to scanning.
4. **Geo queries**: Simple lat/lon bounding box queries become possible.

**Index schema sketch:**

```sql
CREATE TABLE shipments_idx (
  id TEXT PRIMARY KEY,
  customer_id TEXT,
  status TEXT,
  recipient_city TEXT,
  latitude REAL,
  longitude REAL,
  created_at TEXT,
  updated_at TEXT
);
CREATE INDEX idx_shipments_customer ON shipments_idx(customer_id);
CREATE INDEX idx_shipments_status ON shipments_idx(status);
```

**Library: `better-sqlite3`** — synchronous, fastest Node.js SQLite binding. Synchronous reads are actually faster for index lookups (no async overhead).

| Alternative | Why rejected |
|---|---|
| **PostgreSQL/MySQL** | Violates files-as-universal-interface. Requires separate server. |
| **Redis** | In-memory, not a file. Not inspectable. |
| **LevelDB/RocksDB** | Binary format, not inspectable. No SQL. |
| **JSON scanning + in-memory cache** | Doesn't scale to tens of thousands of entities. |

**Risk:** Index can become stale if JSON files edited outside the API. Mitigation: periodic reconciliation or `chokidar` watching.

---

## Decision 4: Mobile App (Driver App)

### Recommendation: **React Native with Expo**

1. **Full TypeScript stack** — shared types, validation, business constants with backend.
2. **Expo handles the hard parts:**
   - Background GPS: `expo-location` + `startLocationUpdatesAsync`
   - Camera/barcode: `expo-camera`, `expo-barcode-scanner`
   - Push notifications: `expo-notifications`
   - Signature capture: `react-native-signature-canvas`
   - Offline-first: `expo-file-system` + `expo-sqlite`
3. **EAS** provides cloud builds and OTA updates.
4. **Agent-friendly** — AI agents read/modify TypeScript/JSX with high fluency.

| Alternative | Why rejected |
|---|---|
| **Flutter** | Dart breaks full-TypeScript strategy. Lower agent fluency with Dart. |
| **Native (Swift + Kotlin)** | Two codebases, double maintenance. Not justified for logistics app. |
| **PWA** | Cannot do reliable background GPS on iOS. Limited push notifications. |

**Critical capabilities:**
- Offline queue: local SQLite when offline, sync on connectivity
- Background GPS: `TaskManager` + `expo-location`
- Low battery awareness: reduce GPS frequency

---

## Decision 5: Frontend Dashboard

### Recommendation: **Next.js (App Router) with React**

1. **TypeScript + React** — same component model as mobile app.
2. **SSR for public tracking** — instant load for `track.mxo.com/TRK-XXXX-XXXX`, good for WhatsApp link previews.
3. **API Routes as BFF** — aggregate multiple API calls for complex dashboard views.
4. **React Server Components** — server-side data fetching, streaming to client.

**Dashboard sections:**

| Section | Role | Key features |
|---|---|---|
| Operations dashboard | operator, admin | Live map, active routes, vehicle positions, alerts |
| Customer portal | customer | Shipment list, tracking, CSV import, billing |
| Driver management | operator | Driver list, productivity stats, assignments |
| Route planning | operator | Create/edit routes, drag-and-drop stops, optimize |
| Public tracking | public | Shipment timeline, map position |
| Admin panel | admin | Customer management, config, audit logs |

**Map component:** `react-map-gl` (Mapbox GL JS) or `@vis.gl/react-google-maps`.

| Alternative | Why rejected |
|---|---|
| **Vite + React SPA** | No SSR for tracking pages. More moving parts. |
| **Remix** | Smaller ecosystem and community than Next.js. |
| **Angular** | Different paradigm. RxJS adds complexity. |
| **Vue/Nuxt** | Team already investing in React for mobile. |

**Deployment note:** Use `output: 'standalone'` in `next.config.js` for Docker deployment.

---

## Decision 6: Message Queue / Event System

### Recommendation: **BullMQ (Redis-backed job queue)**

1. **Operations map to jobs:** Route optimization, ETA calculation, billing summary — trigger async, write results to files.
2. **Redis is justified anyway** for: WebSocket session state, rate limiting, temporary caches.
3. **`bull-board`** provides web UI for queue observability.

```
Queue: operations
Jobs:
  - optimize_route      { route_id: "..." }
  - calculate_eta       { route_id: "..." }
  - import_csv          { import_id: "..." }
  - generate_delivery_note { route_id: "..." }
  - send_notification   { notification_id: "..." }

Queue: tracking
Jobs:
  - update_position     { vehicle_id: "...", lat: ..., lon: ... }
  - sync_tracking       { shipment_id: "..." }
```

| Alternative | Why rejected |
|---|---|
| **RabbitMQ** | Over-engineered for this use case. |
| **Kafka** | Operational overhead absurd at 10-50 clients. |
| **File-based queue** | Lacks retry, concurrency control, dead-letter handling. |
| **Temporal/Inngest** | Too much infrastructure complexity. |

**Risk:** Redis requires persistence config (`appendonly yes`). Data is always derived/transient — source of truth remains in files.

---

## Decision 7: Mapping and Geo

### Recommendation: **OSRM self-hosted for routing + Google Maps API for geocoding**

| Capability | Provider | Why |
|---|---|---|
| Route calculation / distance matrix | Self-hosted OSRM | Free, unlimited, offline. Critical for optimization (30-stop route = 900 distance calculations). |
| Geocoding | Google Maps Geocoding API | Best accuracy for Spanish/European addresses. 40K free calls/month. |
| Isochrones | OpenRouteService or Valhalla (self-hosted) | OSRM lacks native isochrone support. |
| Client-side maps | Mapbox GL JS or Google Maps JS | Dashboard live map and tracking page. |
| Driver app map | `react-native-maps` | Native performance on iOS/Android. |

**Why self-hosted OSRM is essential:**
- Google Distance Matrix: $5 per 1000 elements. 30-stop route = $4.50 per optimization.
- OSRM: zero per query. Spain OSM extract ~1GB. Thousands of req/sec.

| Alternative | Why rejected |
|---|---|
| **Google Maps exclusively** | Cost scales linearly. Expensive at volume. |
| **Mapbox Directions** | Pay-per-request. Same cost problem. |
| **HERE API** | Expensive, vendor-locked. |

---

## Decision 8: DevOps

### Recommendation: **Docker Compose (dev) + Kubernetes (prod) + GitHub Actions (CI/CD) + Grafana (monitoring)**

**Docker Compose (development):**

```yaml
services:
  api:
    build: ./api
    volumes:
      - ./:/data
    ports: ["3000:3000"]

  dashboard:
    build: ./dashboard
    ports: ["3001:3000"]

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes

  osrm:
    image: osrm/osrm-backend
    ports: ["5000:5000"]

  worker:
    build: ./api
    command: tsx src/worker.ts
    volumes:
      - ./:/data
```

**Key principle:** API and worker mount the workspace as a volume — same files accessible from host, containers, and agent sessions.

**Monitoring:**

| Component | Tool |
|---|---|
| Metrics | Prometheus + Grafana |
| Logs | Loki or stdout + Docker logs |
| Alerts | Grafana alerting |

**Critical alert:** Disk usage (70%, 80%, 90%). In file-based storage, running out of disk is catastrophic.

| Alternative | Why rejected |
|---|---|
| **Fly.io / Railway** | Limit volume mount flexibility. |
| **Serverless (Lambda)** | Incompatible with file-based storage. |

---

## Decision 9: Full TypeScript Stack

### Recommendation: **TypeScript everywhere. Strongest recommendation in this document.**

| Factor | Full TypeScript | Polyglot |
|---|---|---|
| Agent fluency | AI agents most fluent in TS. Entire codebase readable/modifiable. | Context-switching increases errors. |
| Shared types | Written once, used in API, dashboard, mobile, worker. | Code generation or manual sync required. |
| Team onboarding | One language. Easiest transition from PHP. | Each language is a barrier. |
| Tooling | One linter, formatter, test runner, build system. | Each language has its own ecosystem. |

**The stack:**

```
Backend API:        TypeScript + Hono + Node.js
Background workers: TypeScript + BullMQ + Node.js
Dashboard:          TypeScript + Next.js + React
Mobile app:         TypeScript + React Native + Expo
Shared types:       TypeScript package (monorepo)
Scripts/tools:      TypeScript + tsx
```

**Monorepo evolution** with `npm workspaces` or `turborepo`:

```
mxo/
├── packages/shared/      # Shared types, constants, validation
├── api/                  # Hono API (existing)
├── worker/               # BullMQ workers
├── dashboard/            # Next.js
├── mobile/               # Expo/React Native
├── (existing entity dirs, operations, config, etc.)
```

---

## Summary Matrix

| Decision | Choice | Confidence |
|---|---|---|
| Backend framework | **Keep Hono** | Very high |
| Real-time | **SSE + WebSocket + chokidar** | High |
| Storage | **Files + SQLite index (`better-sqlite3`)** | High |
| Mobile | **React Native + Expo** | High |
| Dashboard | **Next.js (App Router)** | Medium-high |
| Message queue | **BullMQ + Redis** | High |
| Mapping/Geo | **OSRM (self-hosted) + Google Maps API** | High |
| DevOps | **Docker Compose + K8s + GitHub Actions** | High |
| Language strategy | **Full TypeScript** | Very high |

---

## Implementation Sequence

Each phase produces a deployable increment:

1. **Phase 1: SQLite Index Layer** — Add `better-sqlite3`, modify `file_store.ts` to dual-write, add index rebuild command. Unblocks query performance.

2. **Phase 2: Real-Time (SSE)** — Add `chokidar` file watching and SSE endpoints. Enables live tracking.

3. **Phase 3: BullMQ Workers** — Add Redis, create worker process, migrate async operations to job queue.

4. **Phase 4: Dashboard** — Next.js consuming the existing API. Operator dashboard + public tracking page.

5. **Phase 5: Driver Mobile App** — Expo project with GPS, barcode scanning, delivery confirmation.

6. **Phase 6: OSRM Integration** — Self-hosted routing for `optimize_route` and `calculate_isochrone`.

7. **Phase 7: Kubernetes Deployment** — Production infra, monitoring, alerting.

No phase depends on a later phase. Each ends with a working system.

---

## Critical Files for Implementation

- `api/src/storage/file_store.ts` — Must be extended with SQLite indexing
- `api/src/index.ts` — Where SSE/WebSocket endpoints will be mounted
- `api/src/routes/entities.ts` — Entity registry; SQLite schema derived from configs
- `api/src/routes/crud_factory.ts` — Pattern to follow for streaming/query endpoints
- `operations/optimize_route/prompt.md` — Integration point for OSRM
