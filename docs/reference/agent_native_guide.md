# Agent-Native Architectures: How to Build Apps After Code Ends

> Source: https://every.to/guides/agent-native
> Authors: Dan Shipper and Claude
> Saved: 2026-02-27

## Overview

This guide establishes that "software agents work reliably now" and introduces a paradigm shift: applications designed around agent capabilities rather than traditional code. The architecture applies principles proven in Claude Code (an LLM with bash and file access operating in loops) to broader software categories.

Claude Code demonstrated that a large language model with access to bash and file tools, operating in a loop until an objective is achieved, can accomplish complex multi-step tasks autonomously. The surprising discovery: a really good coding agent is actually a really good general-purpose agent. The same architecture that lets Claude Code refactor a codebase can let an agent organize your files, manage your reading list, or automate your workflows.

---

## Five Core Principles

### 1. Parity

Whatever users accomplish through UI, agents must achieve via tools. This is the foundational principle. Without it, nothing else matters. Ensure the agent has tools that can accomplish anything the UI can do.

### 2. Granularity

Tools should be atomic primitives, not bundled logic. Features emerge when agents operate in loops pursuing described outcomes, not executing pre-choreographed sequences.

- "Less granular" bundles decision logic into tools (agent executes your code)
- "More granular" provides primitives; agents make decisions via prompts ("agent pursues outcomes with judgment")
- A tool is a primitive capability. A feature is an outcome described in a prompt, achieved by an agent with tools, operating in a loop until the outcome is reached.

### 3. Composability

With atomic tools and parity, new features exist as prompts describing outcomes. A "weekly review" becomes a prompt leveraging existing tools without code changes. To change behavior, you edit a prompt, not refactor code.

### 4. Emergent Capability

Agents accomplish unanticipated tasks by composing tools creatively. This reveals latent user demand and drives iterative improvement. Design so agents can accomplish tasks you did not explicitly plan for.

### 5. Improvement Over Time

Applications enhance through accumulated context (persistent state across sessions) and prompt refinement at developer and user levels, without shipping code.

---

## Files as Universal Interface

Agents are naturally good at files. Claude Code works because bash + filesystem is the most battle-tested agent interface.

### Why Files

- **File Fluency**: Agents already know cat, grep, mv, mkdir. File operations are the primitives they're most fluent with.
- **Transparency & User Ownership**: Users can see what the agent created, edit it, move it, delete it. No black box. Export is trivial. Backup is trivial. Users own their data.
- **Cross-device Sync**: On mobile with iCloud, all devices share the same file system. Agent's work appears everywhere without building a server.
- **Self-documentation**: File structures that make sense to humans make sense to agents.

### Design Principle

Design for what agents can reason about. The best proxy for that is what would make sense to a human. If a human can look at your file structure and understand what's going on, an agent probably can too.

### Files vs Databases

- **Files for**: User-readable content, configuration benefiting from version control, agent-generated materials, transparency
- **Databases for**: High-volume structured data, complex queries, ephemeral state
- The principle: Files for legibility, databases for structure.

---

## File System Architecture

### Entity-Scoped Directories

Organize as `{entityType}/{entityId}/` containing primary content, metadata, and related materials.

### Naming Conventions

Use lowercase with underscores:
- Entity data: `{entity}.json`
- Human-readable content: `{content_type}.md`
- Agent reasoning: `agent_log.md`

### Context.md Pattern

Agents maintain portable working memory:
- User profile
- Available resources
- Recent activity
- Guidelines
- Current state

This file enables context accumulation across sessions without code changes.

---

## From Primitives to Domain Tools

Begin with pure primitives (bash, file operations). As patterns emerge, deliberately add domain-specific tools for vocabulary, guardrails, or efficiency. But ensure primitives remain available for edge cases.

---

## Agent Execution Patterns

### Completion Signals

Distinguish completion from success/failure. Tools return structured results indicating whether loops should continue.

### Model Tier Selection

Match task complexity to capability levels:
- Research agents use balanced tiers
- Quick classification uses fast tiers

### Partial Completion Tracking

Track multi-step task progress, enabling resumption after interruptions. Status fields indicate: pending, in-progress, completed, failed, or skipped.

### Context Limits

Design assuming context windows eventually fill. Agents need iterative refinement tools rather than all-or-nothing approaches.

---

## Implementation Patterns

### Shared Workspace

Agents and users occupy identical data spaces, enabling inspection, modification, and transparency. Sandboxing occurs only when specific needs arise.

### Context Injection

System prompts include available resources, capabilities, and recent activity so agents understand their environment.

### Agent-to-UI Communication

Events stream continuously: thinking indicators, tool calls, results, and status changes appear immediately, building trust through visibility.

---

## Product Implications

### Progressive Disclosure

Simple entry points scale with capability. Excel demonstrates this: grocery lists or financial models use identical tools.

### Latent Demand Discovery

Build capable foundations, observe what users request, formalize emerging patterns. This discovers rather than guesses user needs.

### Approval and User Agency

Stakes and reversibility determine autonomy levels:
- Low-stakes, easily reversible actions auto-apply
- High-stakes, hard-to-reverse actions require explicit approval

---

## Advanced Patterns

### Dynamic Capability Discovery

Build two tools handling everything rather than 50 static tools:
- `list_available_types()` discovers what's available
- `read_data(type)` accesses any discovered capability
- Future-proofs against API changes

### CRUD Completeness

Audit every entity for full create, read, update, delete capability. Missing update or delete operations cripple agent usefulness.

---

## Mobile Architecture (iOS)

Agents are long-running, but apps background after seconds. Solutions:

- **iCloud-first storage** with local fallback provides automatic cross-device sync
- **Checkpoint and resume**: Save agent state on backgrounding, resume within validity windows (typically one hour)
- **Background execution**: Use limited iOS time to complete current tool calls and transition to backgrounded state
- **Cloud file states**: Ensure availability before reading iCloud-resident files

---

## Anti-Patterns to Avoid

1. **Agent-as-router**: Uses agent intelligence only for routing, missing compositional potential
2. **Building traditionally, then adding agents**: Limits capabilities to pre-built features
3. **Request/response thinking**: Skips loops handling unexpected situations
4. **Defensive tool design**: Over-constrains inputs, preventing unanticipated compositions
5. **Happy-path code execution**: Places edge-case logic in code rather than agent judgment

---

## Success Criteria

### Architecture Succeeds When

- Agents achieve anything users can through UI
- Tools remain atomic primitives
- Features exist as prompts
- Agents accomplish unanticipated tasks
- Behavior changes require prompt edits, not refactoring

### Implementation Succeeds Through

- System prompts including resources
- Shared data spaces
- Immediate UI reflection
- Full CRUD capability
- Dynamic discovery where appropriate
- Explicit completion signals

### Product Succeeds When

- Simple requests work immediately
- Power users find unexpected capabilities
- Emergent patterns reveal actual user needs
- Approval requirements match stakes

### The Ultimate Test

Describe an outcome within your domain (but not explicitly built) and verify the agent accomplishes it through loop iteration.
