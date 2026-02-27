import { Hono } from "hono";
import { readFile, readdir, access } from "fs/promises";
import { join } from "path";

const DATA_ROOT = join(process.cwd(), "..");
const OPS_DIR = join(DATA_ROOT, "operations");

const app = new Hono();

async function exists(path: string): Promise<boolean> {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

// List all available operations
app.get("/", async (c) => {
  const entries = await readdir(OPS_DIR, { withFileTypes: true });
  const operations = [];

  for (const entry of entries) {
    if (entry.isDirectory()) {
      const promptPath = join(OPS_DIR, entry.name, "prompt.md");
      if (await exists(promptPath)) {
        operations.push({
          name: entry.name,
          prompt_url: `/api/operations/${entry.name}/prompt`,
          context_url: `/api/operations/${entry.name}/context`,
        });
      }
    }
  }

  return c.json({ data: operations, count: operations.length });
});

// Get operation prompt (the agent instruction set)
app.get("/:name/prompt", async (c) => {
  const name = c.req.param("name");
  const promptPath = join(OPS_DIR, name, "prompt.md");

  if (!(await exists(promptPath))) {
    return c.json({ error: `Operation "${name}" not found` }, 404);
  }

  const content = await readFile(promptPath, "utf-8");
  return c.json({ data: { name, prompt: content } });
});

// Get operation context (working memory / lessons learned)
app.get("/:name/context", async (c) => {
  const name = c.req.param("name");
  const contextPath = join(OPS_DIR, name, "context.md");

  if (!(await exists(contextPath))) {
    return c.json({ error: `Context for operation "${name}" not found` }, 404);
  }

  const content = await readFile(contextPath, "utf-8");
  return c.json({ data: { name, context: content } });
});

// Update operation context (persist lessons learned)
app.patch("/:name/context", async (c) => {
  const name = c.req.param("name");
  const contextPath = join(OPS_DIR, name, "context.md");

  if (!(await exists(contextPath))) {
    return c.json({ error: `Operation "${name}" not found` }, 404);
  }

  const { content } = await c.req.json();
  const { writeFile } = await import("fs/promises");
  await writeFile(contextPath, content);

  return c.json({ data: { name, updated: true } });
});

export default app;
