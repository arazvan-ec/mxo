import { Hono } from "hono";
import { createCrudRoutes } from "./crud_factory.ts";
import type { EntityConfig } from "../storage/file_store.ts";

// Entity configurations — one entry per entity type
// Each config maps to a directory in the data layer

const configs: Record<string, { config: EntityConfig; subEntities?: Array<{ path: string; subDir: string }> }> = {
  customers: {
    config: {
      entityDir: "customers",
      entityFile: "customer.json",
      defaults: { status: "active" },
    },
    subEntities: [
      { path: "locations", subDir: "locations" },
    ],
  },

  vehicles: {
    config: {
      entityDir: "vehicles",
      entityFile: "vehicle.json",
      defaults: { status: "available" },
    },
    subEntities: [
      { path: "positions", subDir: "positions" },
    ],
  },

  drivers: {
    config: {
      entityDir: "drivers",
      entityFile: "driver.json",
      defaults: {
        status: "active",
        productivity_stats: {
          total_deliveries: 0,
          total_exceptions: 0,
          success_rate: 0,
          avg_delivery_time_min: 0,
          last_updated: null,
        },
      },
    },
    subEntities: [
      { path: "actions", subDir: "actions" },
    ],
  },

  services: {
    config: {
      entityDir: "services",
      entityFile: "service.json",
      statusType: "service",
      defaults: { status: "draft", service_type: "delivery" },
    },
  },

  parcels: {
    config: {
      entityDir: "parcels",
      entityFile: "parcel.json",
      statusType: "parcel",
      defaults: { status: "registered" },
    },
  },

  shipments: {
    config: {
      entityDir: "shipments",
      entityFile: "shipment.json",
      statusType: "shipment",
      defaults: { status: "created" },
    },
    subEntities: [
      { path: "events", subDir: "events" },
    ],
  },

  routes: {
    config: {
      entityDir: "routes",
      entityFile: "route.json",
      statusType: "route",
      defaults: { status: "planned", total_stops: 0, completed_stops: 0 },
    },
    subEntities: [
      { path: "stops", subDir: "stops" },
    ],
  },

  tracking: {
    config: {
      entityDir: "tracking",
      entityFile: "tracking.json",
    },
  },

  notifications: {
    config: {
      entityDir: "notifications",
      entityFile: "notification.json",
      defaults: { read: false },
    },
  },

  audit: {
    config: {
      entityDir: "audit",
      entityFile: "audit.json",
    },
  },

  imports: {
    config: {
      entityDir: "imports",
      entityFile: "import.json",
      defaults: {
        status: "pending",
        total_rows: 0,
        created_count: 0,
        skipped_count: 0,
        error_count: 0,
      },
    },
  },
};

/**
 * Create and return a Hono app with all entity routes mounted.
 * Each entity gets standard CRUD at /api/{entity}/
 */
export function createEntityRoutes(): Hono {
  const app = new Hono();

  for (const [name, options] of Object.entries(configs)) {
    const routes = createCrudRoutes(options);
    app.route(`/${name}`, routes);
  }

  return app;
}

/** Export configs for use in other modules */
export { configs };
