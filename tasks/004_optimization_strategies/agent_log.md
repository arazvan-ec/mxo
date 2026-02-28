# Agent Log — 004_optimization_strategies

## 2026-02-28

### Analysis

Current optimization prompts have several gaps:
- `optimize_route` uses farthest-first only, no circular guarantee, no RGU awareness
- `calculate_isochrone` uses simple circle approximation, not linked to route strategies
- `auto_assign_routes` mentions isochrone grouping but doesn't enforce RGU-based optimization
- No return-to-origin in distance calculations

### User requirements
- 4 named strategies: pétalo (circular clusters), zigzag (linear sweep), nearest-neighbor, farthest-first improved
- Return to origin: configurable (default circular, allow open routes)
- RGU-based grouping must feed into route optimization

### Plan
1. Rewrite optimize_route/prompt.md — comprehensive with all 4 strategies
2. Strengthen calculate_isochrone/prompt.md — RGU as first-class concept
3. Update auto_assign_routes/prompt.md — strategy selection + RGU pipeline
4. Add config/optimization.json — strategy parameters
5. Update architecture docs
