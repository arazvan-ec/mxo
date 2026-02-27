import { readFile, writeFile, mkdir, readdir, rm, access } from "fs/promises";
import { join } from "path";
import { ulid } from "../lib/ulid.ts";

const DATA_ROOT = join(import.meta.dirname, "..", "..", "..");

export interface EntityConfig {
  /** Directory name under DATA_ROOT (e.g., "customers", "vehicles") */
  entityDir: string;
  /** Main JSON file name (e.g., "customer.json", "vehicle.json") */
  entityFile: string;
  /** Status entity type key in config/statuses.json (e.g., "shipment", "route") */
  statusType?: string;
  /** Fields that should be set on creation */
  defaults?: Record<string, unknown>;
}

async function exists(path: string): Promise<boolean> {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

function entityPath(config: EntityConfig, id: string): string {
  return join(DATA_ROOT, config.entityDir, id);
}

function entityFilePath(config: EntityConfig, id: string): string {
  return join(entityPath(config, id), config.entityFile);
}

/** List all entity IDs */
export async function listIds(config: EntityConfig): Promise<string[]> {
  const dir = join(DATA_ROOT, config.entityDir);
  if (!(await exists(dir))) return [];

  const entries = await readdir(dir, { withFileTypes: true });
  const ids: string[] = [];

  for (const entry of entries) {
    if (entry.isDirectory() && entry.name !== "templates") {
      // Verify the entity file exists
      const filePath = join(dir, entry.name, config.entityFile);
      if (await exists(filePath)) {
        ids.push(entry.name);
      }
    }
  }

  return ids;
}

/** List all entities (full data) */
export async function listAll(config: EntityConfig): Promise<unknown[]> {
  const ids = await listIds(config);
  const entities: unknown[] = [];

  for (const id of ids) {
    const entity = await getById(config, id);
    if (entity) entities.push(entity);
  }

  return entities;
}

/** Get entity by ID */
export async function getById(
  config: EntityConfig,
  id: string
): Promise<Record<string, unknown> | null> {
  const filePath = entityFilePath(config, id);
  if (!(await exists(filePath))) return null;

  const raw = await readFile(filePath, "utf-8");
  return JSON.parse(raw);
}

/** Create a new entity */
export async function create(
  config: EntityConfig,
  data: Record<string, unknown>
): Promise<Record<string, unknown>> {
  const id = (data.id as string) || ulid();
  const now = new Date().toISOString();

  const entity: Record<string, unknown> = {
    ...config.defaults,
    ...data,
    id,
    created_at: now,
    updated_at: now,
  };

  const dir = entityPath(config, id);
  await mkdir(dir, { recursive: true });
  await writeFile(entityFilePath(config, id), JSON.stringify(entity, null, 2) + "\n");

  return entity;
}

/** Update an existing entity (partial update) */
export async function update(
  config: EntityConfig,
  id: string,
  data: Record<string, unknown>
): Promise<Record<string, unknown> | null> {
  const existing = await getById(config, id);
  if (!existing) return null;

  const now = new Date().toISOString();
  const updated: Record<string, unknown> = {
    ...existing,
    ...data,
    id, // ID cannot be changed
    created_at: existing.created_at, // Created timestamp is immutable
    updated_at: now,
  };

  await writeFile(entityFilePath(config, id), JSON.stringify(updated, null, 2) + "\n");

  return updated;
}

/** Delete an entity directory */
export async function remove(config: EntityConfig, id: string): Promise<boolean> {
  const dir = entityPath(config, id);
  if (!(await exists(dir))) return false;

  await rm(dir, { recursive: true });
  return true;
}

/** List sub-entities (e.g., stops within a route, events within a shipment) */
export async function listSubEntities(
  config: EntityConfig,
  parentId: string,
  subDir: string
): Promise<unknown[]> {
  const dir = join(entityPath(config, parentId), subDir);
  if (!(await exists(dir))) return [];

  const files = await readdir(dir);
  const entities: unknown[] = [];

  for (const file of files) {
    if (file.endsWith(".json")) {
      const raw = await readFile(join(dir, file), "utf-8");
      entities.push(JSON.parse(raw));
    }
  }

  return entities;
}

/** Create a sub-entity */
export async function createSubEntity(
  config: EntityConfig,
  parentId: string,
  subDir: string,
  data: Record<string, unknown>
): Promise<Record<string, unknown>> {
  const id = (data.id as string) || ulid();
  const now = new Date().toISOString();

  const entity: Record<string, unknown> = {
    ...data,
    id,
    created_at: data.created_at || now,
    updated_at: now,
  };

  const dir = join(entityPath(config, parentId), subDir);
  await mkdir(dir, { recursive: true });
  await writeFile(join(dir, `${id}.json`), JSON.stringify(entity, null, 2) + "\n");

  return entity;
}

/** Get a sub-entity by ID */
export async function getSubEntity(
  config: EntityConfig,
  parentId: string,
  subDir: string,
  subId: string
): Promise<Record<string, unknown> | null> {
  const filePath = join(entityPath(config, parentId), subDir, `${subId}.json`);
  if (!(await exists(filePath))) return null;

  const raw = await readFile(filePath, "utf-8");
  return JSON.parse(raw);
}

/** Update a sub-entity */
export async function updateSubEntity(
  config: EntityConfig,
  parentId: string,
  subDir: string,
  subId: string,
  data: Record<string, unknown>
): Promise<Record<string, unknown> | null> {
  const existing = await getSubEntity(config, parentId, subDir, subId);
  if (!existing) return null;

  const now = new Date().toISOString();
  const updated: Record<string, unknown> = {
    ...existing,
    ...data,
    id: subId,
    updated_at: now,
  };

  const filePath = join(entityPath(config, parentId), subDir, `${subId}.json`);
  await writeFile(filePath, JSON.stringify(updated, null, 2) + "\n");

  return updated;
}

/** Delete a sub-entity */
export async function removeSubEntity(
  config: EntityConfig,
  parentId: string,
  subDir: string,
  subId: string
): Promise<boolean> {
  const filePath = join(entityPath(config, parentId), subDir, `${subId}.json`);
  if (!(await exists(filePath))) return false;

  await rm(filePath);
  return true;
}
