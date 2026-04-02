# DAG Conventions Reference

This document defines the structural rules, color palette, and verification protocol for implementation DAGs produced by the story-map skill. These conventions were derived from iterative refinement on real projects and encode lessons learned about what makes a DAG useful for driving implementation.

## Structural Rules

### 1. Vertical slices, not waterfall

Each feature slice is end-to-end: backend models/repos/services, endpoints, API client generation, frontend pages, and tests. Do NOT create horizontal layers ("all backend", "all frontend", "all tests").

**Wrong:**
```
subgraph Backend
  B1[Users] --> B2[Lessons] --> B3[Subscriptions]
end
subgraph Frontend
  P1[Dashboard] --> P2[Lesson Page]
end
```

**Right:**
```
subgraph Slice: User Management
  B1[Users model] --> E1[Users endpoints] --> K1[Kiota regen] --> P1[Users page]
end
subgraph Slice: Lessons
  B2[Lessons model] --> E2[Lessons endpoints] --> K2[Kiota regen] --> P2[Lesson page]
end
```

### 2. Pages alongside their backend

Frontend pages live in the same subgraph as the backend slice they primarily depend on. A page is never in a monolithic "Frontend Pages" box.

### 3. Multi-domain pages split into sub-nodes

When a page touches multiple domains (e.g., a Dashboard showing student summaries AND upcoming lessons), split it into sub-nodes:
- `P1a` — "Student summary widget" (depends on Student slice)
- `P1b` — "Upcoming lessons widget" (depends on Lessons slice)

Each sub-node lives in the slice of its primary data source.

### 4. Progressive enhancement

Split pages show dependency chains for progressive enhancement:
- `P4a` — "Basic tutor form" (core functionality)
- `P4b` — "Tutor form with subscription panel" (enhanced, depends on P4a + Subscription slice)

### 5. Incremental API client generation

When using a code-generation tool (Kiota, NSwag, openapi-generator), model it as explicit nodes after each endpoint group — not batched at the end. Each Kiota node depends on the endpoints it regenerates from, and the frontend nodes that consume the generated client depend on the Kiota node.

```
E2[Lesson endpoints] --> K2[Kiota regen] --> P2[Lesson page]
```

### 6. E2E tests inline per slice

Each slice gets its own E2E test node that runs as soon as all slice dependencies are met. E2E tests also chain across slices to verify integration:

```
T11a[E2E: Auth flows] --> T11b[E2E: Student CRUD] --> T11c[E2E: Lesson booking]
```

Do NOT create a monolithic "E2E Tests" node at the end.

### 7. Specs distributed into slices

Repository specifications, query specifications, or any domain-specific spec objects (e.g., Ardalis Specifications) belong in the slice that primarily needs them. Do NOT create a separate "Infrastructure" or "Specifications" subgraph.

### 8. Infrastructure folded into Foundation

Core infrastructure (database setup, auth, job scheduler setup like Hangfire, shared middleware, base entities) belongs in the Foundation slice. Do NOT create separate "Infrastructure" or "Setup" subgraphs.

### 9. No monolithic boxes

Never create mega-groups named "Frontend Pages", "Infrastructure", "Testing", "Specifications", or similar. Everything is distributed into vertical slices. The only exception is Foundation, which contains genuinely shared setup that has no single owning slice.

## Mermaid Conventions

### Layout

Use `flowchart LR` (left-to-right). This reads naturally as a timeline: Foundation on the left, final integration/E2E on the right.

Do NOT use `flowchart TD` (top-down) — it wastes vertical space and makes wide DAGs hard to read.

### Subgraphs

One subgraph per vertical slice. Naming convention:
```
subgraph Foundation
subgraph Slice: Student Management
subgraph Slice: Lesson Booking
subgraph Slice: Subscriptions
subgraph Jobs & Background Tasks
```

### Color Palette (by work type)

Color nodes by WORK TYPE, not by functional group. The subgraph boxes already provide functional grouping.

| Work Type | Color | Hex | Icon |
|-----------|-------|-----|------|
| Backend dev (models, repos, services, endpoints) | Blue | `#4a90d9` | gear |
| Frontend dev (pages, components) | Cyan | `#50c878` | monitor |
| API client generation (Kiota, NSwag) | Orange | `#f5a623` | arrows-rotate |
| Specifications (Ardalis, query specs) | Purple | `#9b59b6` | clipboard |
| Unit/functional/integration tests (xUnit) | Green | `#27ae60` | flask |
| E2E tests (Playwright) | Red | `#e74c3c` | masks-theater |

### Node Labels

Prepend the work-type icon to every node label for quick visual scanning:

```
B1["⚙️ User entity + repo"]
E1["⚙️ User CRUD endpoints"]
K1["🔄 Kiota regen: Users"]
P1["🖥️ User management page"]
S1["📋 UsersByRole spec"]
T1["🧪 User unit tests"]
T11a["🎭 E2E: Auth flows"]
```

### Node ID Conventions

| Prefix | Meaning | Example |
|--------|---------|---------|
| F | Foundation node | F1, F2 |
| B | Backend (model, repo, service) | B1, B2 |
| E | Endpoint | E1, E2 |
| K | Kiota/API client regen | K1, K2 |
| P | Frontend page | P1, P1a, P1b |
| S | Specification | S1, S2 |
| T | Test (xUnit) | T1, T2 |
| T11+ | E2E test (Playwright) | T11a, T11b |
| J | Background job | J1, J2 |

Sub-nodes use letter suffixes: `P1a`, `P1b`, `T11a`, `T11b`.

### Style Definitions

Place style definitions at the end of the Mermaid file:

```mermaid
style B1 fill:#4a90d9,stroke:#333,color:#fff
style P1 fill:#50c878,stroke:#333,color:#fff
style K1 fill:#f5a623,stroke:#333,color:#000
style S1 fill:#9b59b6,stroke:#333,color:#fff
style T1 fill:#27ae60,stroke:#333,color:#fff
style T11a fill:#e74c3c,stroke:#333,color:#fff
```

### Transitive Reduction

Always apply `nx.transitive_reduction(G)` before generating Mermaid edges. This removes redundant edges (e.g., if A->B->C and A->C, remove A->C) and produces a cleaner diagram. The transitive reduction preserves reachability while minimizing visual clutter.

## NetworkX Verification Protocol

### Required Checks

Every DAG must pass these checks before being presented to the user:

1. **Acyclicity** — `nx.is_directed_acyclic_graph(G)` must return `True`. If cycles exist, print them with `nx.find_cycle(G)` and fix before proceeding.

2. **Topological sort** — `list(nx.topological_sort(G))` produces the build order. Present this as the implementation sequence.

3. **Critical path** — `nx.dag_longest_path(G)` with uniform edge weights of 1. This is the longest chain of sequential dependencies and represents the minimum number of sequential steps to complete the project.

4. **Parallelism levels** — `list(nx.topological_generations(G))` shows which nodes can execute concurrently at each level. The widest generation indicates maximum parallelism.

### Summary Statistics

Report these to the user after verification:

- Total nodes
- Total edges (before and after transitive reduction)
- Critical path length and node sequence
- Maximum parallelism (widest generation width)
- Number of slices
- Nodes per work type
