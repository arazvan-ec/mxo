import type { Context, Next } from "hono";
import type { UserContext } from "./auth.ts";

// Entity paths that need tenant filtering
const ENTITY_PATHS = [
  "/customers",
  "/vehicles",
  "/drivers",
  "/services",
  "/parcels",
  "/shipments",
  "/routes",
  "/tracking",
  "/notifications",
  "/audit",
  "/imports",
];

/**
 * Multi-tenancy middleware.
 *
 * Filters list responses based on user role scope.
 * Only applies to entity endpoints, not operations/config/discovery.
 */
export async function tenantFilter(c: Context, next: Next) {
  await next();

  const user = c.get("user") as UserContext | undefined;
  if (!user) return;

  // Admin and operator see everything
  if (user.role === "admin" || user.role === "operator") return;

  // Only filter entity list endpoints
  const path = c.req.path;
  const isEntityPath = ENTITY_PATHS.some((ep) => path.startsWith(`/api${ep}`));
  if (!isEntityPath) return;

  // Only filter list responses (arrays in data field)
  let body: { data?: unknown[]; count?: number } | null = null;
  try {
    body = await c.res.clone().json();
  } catch {
    return;
  }
  if (!body || !body.data || !Array.isArray(body.data)) return;

  let filtered = body.data;

  if (user.role === "customer" && user.customerId) {
    filtered = body.data.filter(
      (entity: Record<string, unknown>) => entity.customer_id === user.customerId
    );
  } else if (user.role === "driver" && user.driverId) {
    filtered = body.data.filter(
      (entity: Record<string, unknown>) =>
        entity.driver_id === user.driverId || entity.customer_id === user.customerId
    );
  } else if (user.role === "public") {
    filtered = []; // Public users use /api/tracking/:token directly
  }

  c.res = new Response(
    JSON.stringify({ data: filtered, count: filtered.length }),
    {
      status: c.res.status,
      headers: { "Content-Type": "application/json" },
    }
  );
}
