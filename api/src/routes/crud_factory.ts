import { Hono } from "hono";
import {
  type EntityConfig,
  listAll,
  getById,
  create,
  update,
  remove,
  listSubEntities,
  createSubEntity,
  getSubEntity,
  updateSubEntity,
  removeSubEntity,
} from "../storage/file_store.ts";
import { validateTransition } from "../lib/status.ts";

interface CrudOptions {
  config: EntityConfig;
  /** Sub-entity routes (e.g., stops within routes, events within shipments) */
  subEntities?: Array<{
    path: string; // URL path segment (e.g., "stops")
    subDir: string; // Directory name within parent entity
  }>;
}

/**
 * Creates standard CRUD routes for any entity type.
 *
 * Generates:
 *   GET    /              → list all
 *   POST   /              → create
 *   GET    /:id           → get by id
 *   PATCH  /:id           → update
 *   DELETE /:id           → delete
 *
 * For sub-entities:
 *   GET    /:id/{sub}     → list sub-entities
 *   POST   /:id/{sub}     → create sub-entity
 *   GET    /:id/{sub}/:subId → get sub-entity
 *   PATCH  /:id/{sub}/:subId → update sub-entity
 *   DELETE /:id/{sub}/:subId → delete sub-entity
 */
export function createCrudRoutes(options: CrudOptions): Hono {
  const app = new Hono();
  const { config, subEntities } = options;

  // LIST all entities
  app.get("/", async (c) => {
    const entities = await listAll(config);
    return c.json({ data: entities, count: entities.length });
  });

  // CREATE entity
  app.post("/", async (c) => {
    const body = await c.req.json();
    const entity = await create(config, body);
    return c.json({ data: entity }, 201);
  });

  // GET entity by ID
  app.get("/:id", async (c) => {
    const id = c.req.param("id");
    const entity = await getById(config, id);
    if (!entity) {
      return c.json({ error: `${config.entityDir} "${id}" not found` }, 404);
    }
    return c.json({ data: entity });
  });

  // UPDATE entity
  app.patch("/:id", async (c) => {
    const id = c.req.param("id");
    const body = await c.req.json();

    // Validate status transition if status is being changed
    if (body.status && config.statusType) {
      const existing = await getById(config, id);
      if (existing && existing.status !== body.status) {
        const result = await validateTransition(
          config.statusType,
          existing.status as string,
          body.status
        );
        if (!result.valid) {
          return c.json({ error: result.error }, 400);
        }
      }
    }

    const entity = await update(config, id, body);
    if (!entity) {
      return c.json({ error: `${config.entityDir} "${id}" not found` }, 404);
    }
    return c.json({ data: entity });
  });

  // DELETE entity
  app.delete("/:id", async (c) => {
    const id = c.req.param("id");
    const deleted = await remove(config, id);
    if (!deleted) {
      return c.json({ error: `${config.entityDir} "${id}" not found` }, 404);
    }
    return c.json({ deleted: true });
  });

  // Sub-entity routes
  if (subEntities) {
    for (const sub of subEntities) {
      // LIST sub-entities
      app.get(`/:id/${sub.path}`, async (c) => {
        const parentId = c.req.param("id");
        const entities = await listSubEntities(config, parentId, sub.subDir);
        return c.json({ data: entities, count: entities.length });
      });

      // CREATE sub-entity
      app.post(`/:id/${sub.path}`, async (c) => {
        const parentId = c.req.param("id");
        const body = await c.req.json();
        const entity = await createSubEntity(config, parentId, sub.subDir, body);
        return c.json({ data: entity }, 201);
      });

      // GET sub-entity
      app.get(`/:id/${sub.path}/:subId`, async (c) => {
        const parentId = c.req.param("id");
        const subId = c.req.param("subId");
        const entity = await getSubEntity(config, parentId, sub.subDir, subId);
        if (!entity) {
          return c.json({ error: `${sub.path} "${subId}" not found` }, 404);
        }
        return c.json({ data: entity });
      });

      // UPDATE sub-entity
      app.patch(`/:id/${sub.path}/:subId`, async (c) => {
        const parentId = c.req.param("id");
        const subId = c.req.param("subId");
        const body = await c.req.json();
        const entity = await updateSubEntity(config, parentId, sub.subDir, subId, body);
        if (!entity) {
          return c.json({ error: `${sub.path} "${subId}" not found` }, 404);
        }
        return c.json({ data: entity });
      });

      // DELETE sub-entity
      app.delete(`/:id/${sub.path}/:subId`, async (c) => {
        const parentId = c.req.param("id");
        const subId = c.req.param("subId");
        const deleted = await removeSubEntity(config, parentId, sub.subDir, subId);
        if (!deleted) {
          return c.json({ error: `${sub.path} "${subId}" not found` }, 404);
        }
        return c.json({ deleted: true });
      });
    }
  }

  return app;
}
