import { Hono } from "hono";
import { logger } from "hono/logger";
import { cors } from "hono/cors";
import { serve } from "@hono/node-server";

const app = new Hono();

// Middleware
app.use("*", logger());
app.use("*", cors());

// Health check
app.get("/", (c) => {
  return c.json({
    name: "mxo-track-api",
    version: "0.1.0",
    status: "running",
    description: "Agent-native REST API for last-mile logistics",
  });
});

// API root
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
  });
});

const port = parseInt(process.env.PORT || "3000");

console.log(`mxo-track API starting on port ${port}`);

serve({ fetch: app.fetch, port });
