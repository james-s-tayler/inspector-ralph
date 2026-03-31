# Inspector Ralph

A spec-driven development pipeline for Claude Code that takes raw requirements, builds a dependency-ordered plan, implements features one at a time via ralph loops, and continuously QA's the result against the specs.

Two ralph loops run in parallel:

- **Builder Ralph** — implements features in dependency order, PRs each into main, waits for CI, merges, exits. The next iteration picks up the next feature from a known-green main.
- **Inspector Ralph** — watches main for new merges, deploys locally, does exploratory testing against the specs, and writes defect specs for any gaps it finds.

Defects take priority: when builder ralph wakes up, it checks `defects/prd.json` first. If there's an unfinished defect story, it fixes that before picking up the next planned feature.

## Repo Contents

```
prompts/
  SETUP.md              # Paste into Claude Code to scaffold the pipeline + ingest requirements
  BUILDER_RALPH.md      # The prompt that drives each builder iteration
  INSPECTOR_RALPH.md    # The prompt that drives each inspector iteration

scripts/
  ralph.sh              # Generic ralph loop — runs any prompt in a retry loop
```

## Dependencies

- [Claude Code](https://claude.com/claude-code)
- [GitHub CLI](https://cli.github.com/) (`gh`)
- [SpecKit](https://github.com/github/spec-kit)
- [NetworkX](https://networkx.org/) (Python 3.9+)
- CI configured on the target repo (GitHub Actions, etc.)

## Usage

### Step 1: Set up the pipeline + ingest requirements

Place your raw requirements (PDFs, diagrams, markdown, images, etc.) in `requirements/` in your target repo. Then copy the contents of `prompts/SETUP.md` and paste it into Claude Code.

Claude will:
1. Scaffold all scripts, directories, and config files
2. Study your requirements and ask clarifying questions
3. Extract features and dependencies, build a DAG using NetworkX
4. Generate SpecKit specs in dependency order
5. Generate the `prd.json` story queue for builder ralph

### Step 2: Build + Inspect (autonomous)

Copy `scripts/ralph.sh` into your target repo, then run both loops:

In one terminal (builder):

```bash
scripts/ralph.sh --prompt scripts/ralph/CLAUDE.md --tool claude 50
```

In a second terminal (inspector):

```bash
scripts/ralph.sh --prompt scripts/inspector/CLAUDE.md --tool claude 100
```

Builder implements features in DAG order, PRs each into main, waits for CI, merges. Inspector tests merged features against specs, files defects. Builder prioritizes defects over new features.

### Step 3: Review

When both loops exit, review:

- `scripts/ralph/progress.txt` — what was built
- `scripts/inspector/inspection_log.txt` — what was tested
- `defects/prd.json` — any remaining open defects
- PR history on main — full audit trail

## Architecture

```
 Raw Requirements
       |
  [You + Claude — interactive setup]
       |
  requirements/features.json
       |
  [NetworkX — dag_sort.py]
       |
  requirements/build_order.json
       |
  [generate_prd.py]
       |
  scripts/ralph/prd.json
       |
       +---------------------------+
       |                           |
  Builder Ralph              Inspector Ralph
  (scripts/ralph/)           (scripts/inspector/)
       |                           |
  Implements features        Watches main
  in DAG order               Deploys locally
       |                     Tests against specs
  PR → CI → Merge                 |
       |                     Finds gaps
  main moves forward              |
       |                     Writes defect specs
       +<--- defects/prd.json <---+
       |
  Builder checks defects
  first on each wakeup
       |
  Fixes defect before
  next planned feature
       |
       +---------------------------+
       |                           |
  All features built         All features inspected
  All defects fixed          Gaps documented
       |                           |
       +---------------------------+
                   |
              Done. Green main.
              Full PR audit trail.
```
