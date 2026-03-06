# Task 005: Evaluate Tech Stack

## Objective

Evaluate and recommend the complete technology stack for mxo-track, considering the existing Hono + file-based architecture, agent-native principles, and the team's context (transitioning from PHP to TypeScript, 10-50 B2B clients).

## Deliverable

`docs/tech_stack_recommendation.md` — comprehensive document with 9 technology decisions, each with rationale, alternatives analysis, and implementation guidance.

## Key Decisions

1. Backend: Keep Hono
2. Real-time: SSE + WebSocket + chokidar
3. Storage: Files + SQLite index (better-sqlite3)
4. Mobile: React Native + Expo
5. Dashboard: Next.js (App Router)
6. Message queue: BullMQ + Redis
7. Mapping: OSRM (self-hosted) + Google Maps API
8. DevOps: Docker Compose + Kubernetes + GitHub Actions
9. Language: Full TypeScript everywhere
