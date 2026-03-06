# mxo-track: Tech Stack Recommendation

## Developer Profile

- **Solo developer**, PHP background, no other language experience
- **AI as co-developer** (Claude, Copilot) — this is the primary "team member"
- **Scale**: 5-20 B2B clients, 500-5000 shipments/day in 12 months
- **Mobile**: PWA first, native app later when background GPS is needed
- **Starting clean**: no PHP legacy to maintain

## What Already Exists

- **Backend**: Hono framework on Node.js with TypeScript (~600 lines across 7 source files)
- **Storage**: Generic file-based CRUD engine (`file_store.ts`) — directories as entities, JSON files as records
- **API Surface**: Full REST API with discovery, CRUD factory, sub-entity support, status transition validation, role-based auth, tenant filtering
- **Operations**: 9 agent operations defined as prompt files (Markdown, not code)
- **ID Generation**: Custom ULID implementation (time-sortable, Crockford Base32)
- **Zero external dependencies** beyond Hono and its Node.js adapter

---

## Why TypeScript, Not PHP

Although PHP/Laravel would be productive from day 1, TypeScript wins for this project:

1. **The backend is already built** in TypeScript/Hono. Rewriting to PHP is moving backward.
2. **One language for everything**: backend, dashboard, PWA, and eventually native mobile. With PHP you still need JavaScript for the frontend.
3. **AI as co-developer**: Claude and Copilot are measurably stronger generating TypeScript than PHP. As a solo developer relying on AI, this multiplies your output.
4. **Learning curve**: ~1-2 weeks with AI assistance. TypeScript syntax resembles modern PHP (types, classes, arrow functions).

---

## Decision 1: Backend Framework

### Recommendation: **Keep Hono**

The existing `crud_factory.ts` + `file_store.ts` + `entities.ts` pattern is a working generic engine. Switching frameworks means rewriting for zero functional gain.

- At 14KB, Hono adds almost nothing. The codebase has 3 dependencies total.
- Hono runs everywhere (Node.js, Cloudflare Workers, Deno, Bun).
- The middleware pattern (auth, tenant filter) is clean and idiomatic.

**Evolve, don't replace:**
- Add Zod for runtime validation
- Add Vitest for tests

| Alternative | Why rejected |
|---|---|
| **Fastify** | Heavier, plugin ecosystem not needed. Full rewrite required. |
| **NestJS** | Over-engineered. Decorators, DI, modules add ceremony contradicting simplicity. |
| **Go (Gin/Chi)** | Breaks full-TypeScript strategy. Performance irrelevant at this scale. |
| **PHP/Laravel** | Familiar but doesn't unify frontend+backend. Worse AI tooling. |

---

## Decision 2: Real-Time Layer

### Recommendation: **SSE first, WebSocket later**

```
                    SSE (one-way)
  Dashboard/Customer ←──────────── Hono API ←── chokidar watching files
  Tracking Page      ←────────────
```

**Start with SSE only** because:
- All current use cases are read-only (dashboard updates, tracking).
- SSE is simpler than WebSocket, works through proxies/CDNs, auto-reconnects.
- Hono supports SSE natively via `hono/streaming`. No additional dependency.
- `chokidar` watches entity directories — when a JSON file changes, push via SSE.

**Endpoints to add:**
- `GET /api/stream/{entity}/{id}` — SSE for specific entity changes
- `GET /api/stream/tracking/{token}` — SSE for public tracking

**When to add WebSocket:** When the native driver app needs bidirectional communication (sending GPS + receiving route updates simultaneously). Not needed for PWA phase.

| Alternative | Why rejected |
|---|---|
| **Socket.io** | 300KB+ client library, unnecessary complexity. |
| **Redis Pub/Sub** | Adds infrastructure. The filesystem IS the event source. |
| **MQTT** | Adds broker dependency. Only justified at thousands of vehicles. |

---

## Decision 3: Storage Strategy

### Recommendation: **Files as source of truth + SQLite as read-only query index**

This is the most critical architectural decision.

**The problem:** `listAll` reads every entity directory and parses every JSON file. At 5,000 shipments/day, within a month you have 150,000 files. Not viable.

**The solution:** SQLite is literally a file — zero infrastructure, philosophically compatible with files-as-universal-interface.

```
Source of truth:  shipments/{id}/shipment.json   (always authoritative)
Query index:      data/index.sqlite               (derived, rebuildable)
```

**How it works:**
1. **Write path**: `file_store.ts` creates/updates JSON AND updates SQLite index row.
2. **Read path**: `getById` reads JSON directly. `listAll` with filters queries SQLite for matching IDs, then reads only those JSON files.
3. **Rebuildable**: A `rebuild-index` command repopulates SQLite from JSON files. If deleted, system falls back to scanning.
4. **Geo queries**: Simple lat/lon bounding box queries become possible.

**Library: `better-sqlite3`** — synchronous, fastest Node.js SQLite binding.

**Why NOT PostgreSQL:** Requires a separate running server process. At 5,000 shipments/day, SQLite handles this trivially. PostgreSQL becomes worth considering only at hundreds of thousands of records with heavy concurrent writes.

| Alternative | Why rejected for solo developer |
|---|---|
| **PostgreSQL/MySQL** | Separate server to manage. Overkill at this scale. |
| **Redis** | In-memory, not a file. Requires separate process. |
| **JSON scanning + cache** | Doesn't scale past a few thousand entities. |

---

## Decision 4: Driver Interface

### Recommendation: **PWA first, React Native + Expo later**

**Phase 1 (now): PWA**
- Part of the same dashboard project — responsive views for mobile
- Service worker for offline caching
- Geolocation API for GPS reporting (foreground only)
- Camera API for barcode scanning (works in modern browsers)
- Zero app store deployment — instant updates

**Phase 2 (when needed): React Native + Expo**
- When you need **background GPS** (driver's phone in pocket while driving)
- When you need **push notifications** that work reliably on iOS
- Expo handles: background location, camera, barcode, signature capture, offline SQLite
- Full TypeScript — shared types with backend

**When to switch:** When customers demand that drivers' positions update even with the screen off. This is the PWA's hard limitation.

| Alternative | Why rejected |
|---|---|
| **Flutter** | Dart breaks full-TypeScript strategy. |
| **Native (Swift + Kotlin)** | Two codebases for a solo developer. Unmanageable. |

---

## Decision 5: Frontend Dashboard

### Recommendation: **Vite + React** (not Next.js)

Next.js is powerful but too complex for a solo developer: App Router, Server Components, caching strategies, deployment quirks. For a B2B internal dashboard:

- **Vite + React** is simple: scaffold, write components, deploy as static files.
- The dashboard is internal — SSR is not needed.
- Public tracking: a simple route in the SPA, or a lightweight SSR endpoint on the Hono API itself.

**Dashboard sections:**

| Section | Role | Key features |
|---|---|---|
| Operations dashboard | operator, admin | Live map, active routes, vehicle positions, alerts |
| Customer portal | customer | Shipment list, tracking, CSV import, billing |
| Route planning | operator | Create/edit routes, drag-and-drop stops, optimize |
| Public tracking | public | Shipment timeline, map position |

**Map component:** Leaflet (free, open source) or `react-map-gl` (Mapbox GL JS).

| Alternative | Why rejected for solo developer |
|---|---|
| **Next.js** | App Router/RSC complexity not justified for internal dashboard. |
| **Angular** | Different paradigm, steeper learning curve. |
| **Vue/Nuxt** | Breaks consistency with React (needed later for React Native). |

**When to consider Next.js:** If the public tracking page becomes a significant marketing/SEO asset and needs SSR with good social sharing previews. Can migrate React components to Next.js since they're the same library.

---

## Decision 6: Message Queue / Event System

### Recommendation: **In-process queue first (`p-queue`), BullMQ later**

At your current scale, Redis + BullMQ is over-engineering.

**Start with `p-queue`** (~2KB npm package):
- Limits concurrency (e.g., max 2 route optimizations at once)
- Processes jobs in order
- Zero infrastructure — runs in the API process

**Use cases (all fast enough in-process):**
- Route optimization
- CSV import
- PDF/delivery note generation
- Notification sending

**When to add BullMQ + Redis:**
- When operations take >30 seconds and you need to show progress
- When you need retry logic for failed jobs
- When you run multiple API instances (need shared queue)
- When you need `bull-board` for queue observability

| Alternative | Why rejected for now |
|---|---|
| **BullMQ + Redis** | Adds Redis dependency. Not needed at current scale. |
| **RabbitMQ** | Way over-engineered. |
| **Kafka** | Absurd at this scale. |

---

## Decision 7: Mapping and Geo

### Recommendation: **OSRM self-hosted for routing + Google Maps API for geocoding**

| Capability | Provider | Why |
|---|---|---|
| Route calculation / distance matrix | Self-hosted OSRM | Free, unlimited. Critical for optimization (30 stops = 900 distance calculations). |
| Geocoding | Google Maps Geocoding API | Best accuracy for Spanish/European addresses. 40K free calls/month. |
| Isochrones | OpenRouteService or Valhalla (self-hosted) | OSRM lacks native isochrone support. |
| Client-side maps | Leaflet (free) or Mapbox GL JS | Dashboard live map and tracking page. |

**Why self-hosted OSRM is essential:**
- Google Distance Matrix: $5 per 1000 elements. 30-stop route optimization = $4.50 per run.
- OSRM: zero per query. Spain OSM extract ~1GB. Thousands of req/sec.
- Runs as a Docker container alongside your API.

**Cost: ~€0/month** for OSRM + €0 for geocoding up to 40K calls.

---

## Decision 8: DevOps

### Recommendation: **Hetzner VPS + Docker Compose + Caddy** (not Kubernetes)

Kubernetes is for teams and complex multi-service deployments. For a solo developer:

**Hosting: Hetzner VPS**
- €10-20/month for 4-8GB RAM in Europe
- Full control, excellent price/performance
- Persistent disk for file-based storage

**Orchestration: Docker Compose**

```yaml
services:
  api:
    build: ./api
    volumes:
      - ./data:/data
    ports: ["3000:3000"]

  dashboard:
    build: ./dashboard
    ports: ["3001:80"]

  osrm:
    image: osrm/osrm-backend
    volumes:
      - ./geo/osrm-data:/data
    ports: ["5000:5000"]
    command: osrm-routed --algorithm mld /data/spain-latest.osrm
```

**Reverse proxy: Caddy**
- Auto-HTTPS (Let's Encrypt) with zero config
- Simpler than nginx for a solo developer
- Reverse proxy to API + dashboard containers

**Deploy pipeline:**
```
git push → GitHub Actions → build Docker images → SSH to VPS → docker compose pull && up -d
```

**When to consider Kubernetes:** When you need 3+ servers, auto-scaling, or multi-region. Years away at your scale.

| Alternative | Why rejected for solo developer |
|---|---|
| **Kubernetes** | Operational overhead not justified for 1 server. |
| **Fly.io / Railway** | Limit volume mount flexibility needed for file-based architecture. |
| **Serverless (Lambda)** | Incompatible with file-based storage (ephemeral filesystem). |

**Critical monitoring:** Set up disk usage alerts (70%, 80%, 90%). In file-based storage, running out of disk is catastrophic. Simple cron job + email alert is sufficient to start.

---

## Decision 9: Language Strategy

### Recommendation: **Full TypeScript everywhere**

| Layer | Technology |
|---|---|
| Backend API | TypeScript + Hono + Node.js |
| Dashboard | TypeScript + Vite + React |
| Driver PWA | TypeScript + React (same project) |
| Future mobile app | TypeScript + React Native + Expo |
| Scripts/tools | TypeScript + tsx |

**Why this matters for a solo developer with AI:**
- AI agents generate TypeScript with higher accuracy than any other language
- One set of tooling: one linter (ESLint), one formatter (Prettier), one test runner (Vitest)
- Shared types between backend and frontend — define once, use everywhere
- Coming from PHP, TypeScript is the closest web-oriented typed language

---

## Summary Matrix

| Decision | Choice | Confidence | Scale-up path |
|---|---|---|---|
| Language | **TypeScript** | Very high | — |
| Backend | **Keep Hono** | Very high | — |
| Storage | **Files + SQLite** | High | → PostgreSQL as index if needed |
| Dashboard | **Vite + React** | High | → Next.js if SSR needed |
| Driver | **PWA** | High | → React Native + Expo |
| Real-time | **SSE** | High | → + WebSocket for native app |
| Queue | **p-queue (in-process)** | High | → BullMQ + Redis |
| Mapping | **OSRM + Google Geocoding** | High | — |
| Hosting | **Hetzner + Docker + Caddy** | High | → Kubernetes |

Every choice has a clear upgrade path. Start simple, scale each piece when you hit its limits.

---

## Implementation Phases

Each phase ends with something deployable:

### Phase 1: SQLite Index Layer
- Add `better-sqlite3` to API
- Modify `file_store.ts` for dual-write (JSON + SQLite)
- Add `rebuild-index` command

### Phase 2: Dashboard MVP
- Scaffold Vite + React in `dashboard/`
- Operator view: shipment list, route list, basic stats
- Customer portal: their shipments, CSV import

### Phase 3: Real-Time + Public Tracking
- SSE endpoints in Hono API
- `chokidar` file watching
- Public tracking page

### Phase 4: Driver PWA
- Responsive driver views in dashboard
- Geolocation reporting
- Delivery confirmation + signature

### Phase 5: OSRM + Route Optimization
- OSRM Docker container with Spain data
- Integrate with `optimize_route` operation
- Replace Haversine with real road distances

### Phase 6: Production Deploy
- Docker Compose with API + dashboard + OSRM
- Hetzner VPS + Caddy
- GitHub Actions CI/CD
- Backup strategy for file storage

---

## Critical Files for Implementation

- `api/src/storage/file_store.ts` — Must be extended with SQLite indexing
- `api/src/index.ts` — Where SSE endpoints will be mounted
- `api/src/routes/entities.ts` — Entity registry; SQLite schema derived from configs
- `api/src/routes/crud_factory.ts` — Pattern to follow for streaming/query endpoints
- `operations/optimize_route/prompt.md` — Integration point for OSRM
