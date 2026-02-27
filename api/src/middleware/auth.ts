import type { Context, Next } from "hono";

/**
 * Authentication middleware.
 *
 * For now, extracts user context from headers (agent-native: simple, inspectable).
 * In production, this would validate JWT/session tokens.
 *
 * Headers:
 *   X-User-Id: user identifier
 *   X-User-Role: admin | operator | customer | driver | public
 *   X-Customer-Id: customer scope (for customer/driver roles)
 *   X-Driver-Id: driver scope (for driver role)
 */
export interface UserContext {
  userId: string;
  role: string;
  customerId?: string;
  driverId?: string;
}

export async function authMiddleware(c: Context, next: Next) {
  const userId = c.req.header("X-User-Id") || "anonymous";
  const role = c.req.header("X-User-Role") || "public";
  const customerId = c.req.header("X-Customer-Id");
  const driverId = c.req.header("X-Driver-Id");

  const user: UserContext = {
    userId,
    role,
    ...(customerId && { customerId }),
    ...(driverId && { driverId }),
  };

  c.set("user", user);
  await next();
}

/**
 * Role guard — restricts access to specific roles.
 */
export function requireRole(...roles: string[]) {
  return async (c: Context, next: Next) => {
    const user = c.get("user") as UserContext;
    if (!roles.includes(user.role)) {
      return c.json(
        { error: `Access denied. Required roles: ${roles.join(", ")}` },
        403
      );
    }
    await next();
  };
}
