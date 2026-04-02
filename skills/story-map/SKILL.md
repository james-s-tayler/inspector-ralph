---
name: story-map
description: Generate an implementation DAG from specification documents — vertical slices, NetworkX verification, Mermaid diagram
user-invocable: true
argument-hint: "[path to spec files or directory]"
---

# Story Map

Generate a dependency-ordered implementation DAG from specification documents. The DAG is structured as vertical feature slices (not waterfall layers), verified with NetworkX, and rendered as a Mermaid diagram.

Read `skills/story-map/references/dag-conventions.md` before proceeding. It contains the structural rules, color palette, and verification protocol that govern every DAG you produce.

## Input

```text
$ARGUMENTS
```

## Step 1: Gather specifications

If `$ARGUMENTS` contains file paths or a directory, read all referenced spec files. If `$ARGUMENTS` is empty or does not point to files, ask the user:

> Which specification files should I use to build the DAG? Provide file paths, a directory, or paste the specs directly.

Read every spec file thoroughly. For each spec, extract:
- Feature name and scope
- Domain entities involved
- Backend requirements (models, repositories, services, endpoints)
- Frontend requirements (pages, components, forms)
- Testing requirements (unit, functional, integration, E2E)
- Infrastructure requirements (jobs, queues, external services)
- Dependencies on other features (explicit and implied)

## Step 2: Interview the user about implementation decisions

Do NOT proceed to DAG generation without asking these questions. Present them all at once and wait for answers.

1. **Build order priority** — Which features are most critical to deliver first? Are there business milestones or demo deadlines that constrain ordering?
2. **Tech stack specifics** — What backend framework, frontend framework, ORM, and API client generation tool are in use? (These affect node granularity — e.g., Kiota regeneration nodes, EF Core migration nodes.)
3. **Testing strategy** — What testing tiers exist (unit, functional/integration, E2E)? What frameworks (xUnit, Playwright, etc.)? Should E2E tests be inline per slice or grouped?
4. **API client generation** — Is there a code-generation step between backend and frontend (e.g., Kiota, NSwag, openapi-generator)? Should it be modeled as explicit nodes after each endpoint group?
5. **Foundation scope** — What belongs in the foundation slice? (Auth, base entities, database setup, shared infrastructure like job schedulers?)
6. **Spec distribution** — Are there repository/query specifications (e.g., Ardalis Specifications) that should be distributed into the slices that need them rather than centralized?

Record all answers. They directly shape the DAG structure.

## Step 3: Design the DAG

Using the specs and the user's answers, design the DAG following the conventions in `references/dag-conventions.md`. For each node, determine:

- **ID** — Short identifier (e.g., F1, B2, P3a, K4, T11b)
- **Label** — Descriptive label with work-type icon prefix
- **Work type** — Backend, Frontend, Kiota/API client, Spec, Test (xUnit), E2E test
- **Slice** — Which vertical slice (subgraph) it belongs to
- **Dependencies** — Which nodes must complete before this one can start

Key structural rules (see `references/dag-conventions.md` for full details):
- Vertical slices, not waterfall layers
- Pages live alongside their backend in the same slice
- Multi-domain pages split into sub-nodes (P1a, P1b) with progressive enhancement chains
- API client regeneration after each endpoint group
- E2E tests inline per slice, chained across slices
- Specs distributed into their primary slice
- Infrastructure folded into Foundation

## Step 4: Generate the NetworkX verification script

Write `dag_verify.py` — a Python script that:

1. Defines all nodes with metadata (id, label, work_type, slice)
2. Defines all edges as (source, target) tuples
3. Builds a `networkx.DiGraph`
4. Verifies `nx.is_directed_acyclic_graph(G)` — exit with error if cycles found
5. Prints topological sort via `nx.topological_sort(G)`
6. Computes critical path via `nx.dag_longest_path(G)` (all edge weights = 1)
7. Computes parallelism levels via `nx.topological_generations(G)`
8. Prints a summary: total nodes, total edges, critical path length, max parallelism

Structure the script so that the node and edge definitions are easy to edit. Use dictionaries for node metadata and a flat list for edges.

## Step 5: Run verification

Execute `python dag_verify.py` and review the output.

- **If cycles are detected:** Fix the edges that create cycles, re-run until the graph is acyclic.
- **If the critical path is unexpectedly long:** Consider whether dependencies can be relaxed to improve parallelism.
- **If parallelism is low:** Look for sequential chains that could be broken by splitting nodes.

Present the verification results to the user:
- Total nodes and edges
- Critical path (list the node IDs)
- Maximum parallelism (widest generation)
- Topological generations (show which nodes can run in parallel at each level)

Ask the user to confirm the DAG structure or request changes. Iterate until approved.

## Step 6: Generate the Mermaid diagram

Write `dag_gen_mermaid.py` — a Python script that:

1. Imports the same node/edge definitions from Step 4 (or shares a common data module)
2. Applies `nx.transitive_reduction(G)` to remove redundant edges
3. Generates a Mermaid `flowchart LR` diagram with:
   - Subgraphs per vertical slice
   - Nodes colored by work type (see color palette in `references/dag-conventions.md`)
   - Icon prefixes on node labels
   - Clean edge routing from the transitive reduction

Write the output to `DAG.mmd`.

## Step 7: Deliver artifacts

Present all three artifacts to the user:

1. **`dag_verify.py`** — NetworkX verification script (nodes, edges, validation, stats)
2. **`dag_gen_mermaid.py`** — Mermaid generation script (transitive reduction, styling)
3. **`DAG.mmd`** — The rendered Mermaid diagram file

Summarize the DAG:
- Number of slices and what each covers
- Number of nodes by work type
- Critical path and estimated parallelism
- Any decision points or trade-offs that were made

If the user wants changes, return to Step 3 and iterate.
