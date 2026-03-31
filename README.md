# Inspector Ralph

A spec-driven development pipeline for Claude Code that takes raw requirements, builds a dependency-ordered plan, implements features one at a time via ralph loops, and continuously QA's the result against the specs.

Two ralph loops run in parallel:

- **Builder Ralph** — implements features in dependency order, PRs each into main, waits for CI, merges, exits. The next iteration picks up the next feature from a known-green main.
- **Inspector Ralph** — watches main for new merges, deploys locally, does exploratory testing against the specs, and writes defect specs for any gaps it finds.

Defects take priority: when builder ralph wakes up, it checks `defects/prd.json` first. If there's an unfinished defect story, it fixes that before picking up the next planned feature.

## Dependencies

- [Claude Code](https://claude.com/claude-code)
- [GitHub CLI](https://cli.github.com/) (`gh`)
- [SpecKit](https://github.com/github/spec-kit)
- [NetworkX](https://networkx.org/) (Python 3.9+)
- CI configured on the target repo (GitHub Actions, etc.)

## Usage

### Step 1: Set up the pipeline

Copy the contents of `PROMPT.md` and paste it into Claude Code in your target repo. Claude will scaffold all the scripts, directories, and config files.

### Step 2: Bootstrap (interactive)

Place your raw requirements (PDFs, diagrams, markdown, images, etc.) in `requirements/`, then:

```bash
claude < scripts/bootstrap.md
```

Claude will study the requirements, ask you clarifying questions, extract features and dependencies, build a DAG using NetworkX, and generate SpecKit specs in dependency order. Review the build order and specs when prompted.

### Step 3: Build + Inspect (autonomous)

In one terminal:

```bash
scripts/ralph/ralph.sh --tool claude 50
```

In a second terminal:

```bash
scripts/inspector/inspector.sh --tool claude 100
```

Builder implements features in DAG order, PRs each into main, waits for CI, merges. Inspector tests merged features against specs, files defects. Builder prioritizes defects over new features.

### Step 4: Review

When both loops exit, review:

- `scripts/ralph/progress.txt` — what was built
- `scripts/inspector/inspection_log.txt` — what was tested
- `defects/prd.json` — any remaining open defects
- PR history on main — full audit trail

## Architecture

```
 Raw Requirements
       |
  [You + Claude — interactive bootstrap]
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
