import { Hono } from "hono";
import { logger } from "hono/logger";
import { cors } from "hono/cors";
import { serve } from "@hono/node-server";
import { join } from "path";
import { authMiddleware } from "./middleware/auth.ts";
import { tenantFilter } from "./middleware/tenant.ts";
import { createEntityRoutes } from "./routes/entities.ts";
import operations from "./routes/operations.ts";

const DATA_ROOT = join(process.cwd(), "..");

const app = new Hono();

// Global middleware
app.use("*", logger());
app.use("*", cors());
app.use("/api/*", authMiddleware);
app.use("/api/*", tenantFilter);

// Health check
app.get("/", (c) => {
  return c.json({
    name: "mxo-track-api",
    version: "0.1.0",
    status: "running",
    description: "Agent-native REST API for last-mile logistics",
  });
});

// API discovery
app.get("/api", (c) => {
  return c.json({
    entities: [
      "customers",
      "vehicles",
      "drivers",
      "services",
      "parcels",
      "shipments",
      "routes",
      "tracking",
      "notifications",
      "audit",
      "imports",
    ],
    operations: [
      "optimize_route",
      "calculate_eta",
      "generate_delivery_note",
      "import_csv",
      "check_vehicle_capacity",
      "calculate_isochrone",
      "analyze_driver_productivity",
      "billing_summary",
      "auto_assign_routes",
    ],
    docs: {
      pattern: "GET/POST /api/{entity}, GET/PATCH/DELETE /api/{entity}/{id}",
      auth: "Headers: X-User-Id, X-User-Role, X-Customer-Id, X-Driver-Id",
    },
  });
});

// Entity CRUD routes
app.route("/api", createEntityRoutes());

// Operations routes
app.route("/api/operations", operations);

// Config endpoint (read-only access to platform configuration)
app.get("/api/config/:name", async (c) => {
  const name = c.req.param("name");
  const validConfigs = ["roles", "service_types", "statuses", "vehicle_types"];

  if (!validConfigs.includes(name)) {
    return c.json({ error: `Config "${name}" not found. Valid: ${validConfigs.join(", ")}` }, 404);
  }

  const { readFile } = await import("fs/promises");
  const configPath = join(DATA_ROOT, "config", `${name}.json`);
  const content = await readFile(configPath, "utf-8");

  return c.json({ data: JSON.parse(content) });
});

// Error handler
app.onError((err, c) => {
  console.error("API Error:", err);
  return c.json({ error: err.message }, 500);
});

// 404 handler
app.notFound((c) => {
  return c.json({ error: "Not found" }, 404);
});

const port = parseInt(process.env.PORT || "3000");

console.log(`mxo-track API starting on port ${port}`);
console.log(`  Health: http://localhost:${port}/`);
console.log(`  API:    http://localhost:${port}/api`);

serve({ fetch: app.fetch, port });
