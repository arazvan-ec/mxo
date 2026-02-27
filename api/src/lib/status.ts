import { readFile } from "fs/promises";
import { join } from "path";

const DATA_ROOT = join(process.cwd(), "..");

interface StatusConfig {
  values: string[];
  transitions: Record<string, string[]>;
}

let statusCache: Record<string, StatusConfig> | null = null;

async function loadStatuses(): Promise<Record<string, StatusConfig>> {
  if (statusCache) return statusCache;
  const raw = await readFile(join(DATA_ROOT, "config", "statuses.json"), "utf-8");
  const parsed = JSON.parse(raw);
  // Extract entity status configs (skip non-entity keys like exception_types)
  statusCache = {};
  for (const [key, value] of Object.entries(parsed)) {
    if (typeof value === "object" && value !== null && "transitions" in value) {
      statusCache[key] = value as StatusConfig;
    }
  }
  return statusCache;
}

export async function validateTransition(
  entityType: string,
  currentStatus: string,
  newStatus: string
): Promise<{ valid: boolean; error?: string }> {
  const statuses = await loadStatuses();
  const config = statuses[entityType];
  if (!config) {
    return { valid: true }; // No status config = no validation
  }

  if (!config.values.includes(newStatus)) {
    return {
      valid: false,
      error: `Invalid status "${newStatus}" for ${entityType}. Valid: ${config.values.join(", ")}`,
    };
  }

  const allowed = config.transitions[currentStatus];
  if (!allowed) {
    return {
      valid: false,
      error: `Unknown current status "${currentStatus}" for ${entityType}`,
    };
  }

  if (!allowed.includes(newStatus)) {
    return {
      valid: false,
      error: `Cannot transition ${entityType} from "${currentStatus}" to "${newStatus}". Allowed: ${allowed.join(", ") || "none (terminal state)"}`,
    };
  }

  return { valid: true };
}
