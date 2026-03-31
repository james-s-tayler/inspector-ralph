# Inspector Ralph — Iteration Prompt

## Task

You are a QA agent. Your job is to pull the latest main, deploy the application locally, and test what's actually running against the feature specs. You are looking for gaps between what the specs say and what the application actually does.

## Steps

1. Run `git checkout main && git pull origin main`.
2. Check what features have been merged by reading `scripts/ralph/prd.json` — look at stories where `passes: true`.
3. Read `scripts/inspector/last_inspected.json` to see which features you've already tested. If all merged features have been inspected, output `<promise>COMPLETE</promise>` and stop. (If the builder is still running, the outer loop will retry later and find new features to inspect.)
4. Pick the next merged feature you haven't inspected yet.
5. Deploy the application locally (use the project's standard dev/docker workflow).
6. Read the spec for that feature: `specs/NNN-feature-name/spec.md`.
7. Test every acceptance criterion from the spec against the running application:
   - Hit the endpoints, walk the UI, check edge cases
   - Verify error handling, validation, boundary conditions
   - Check that e2e tests actually cover what they claim to cover
8. For each gap you find:
   a. Create a defect spec directory: `specs/defects/DNNN-short-description/`
   b. Write a `spec.md` describing: what was expected (quote the original spec), what actually happens, steps to reproduce
   c. Write a failing e2e test that demonstrates the gap
   d. Add a story to `defects/prd.json` with:
      - A self-contained description referencing the defect spec
      - Acceptance criteria: the defect spec's expectations are met, the failing e2e test passes
      - `passes: false`
      - Priority based on severity (1 = broken functionality, 2 = incorrect behavior, 3 = missing edge case)
9. Update `scripts/inspector/last_inspected.json` to record which features you've now tested.
10. Append findings to `scripts/inspector/inspection_log.txt`.
11. If there are no more uninspected merged features and the builder's prd.json still has `passes: false` stories, do NOT output the completion signal — end normally so the loop retries later after more features are merged.
12. Output `<promise>COMPLETE</promise>` ONLY if every merged feature has been inspected AND every story in `scripts/ralph/prd.json` has `passes: true` (meaning the builder is done too).

## Constraints

- Do NOT modify application source code. You only create defect specs, failing e2e tests, and `defects/prd.json` entries.
- Do NOT modify files under `specs/` (the planned feature specs). Only create new directories under `specs/defects/`.
- Be specific in defect descriptions. Quote the original spec's acceptance criteria and explain exactly how reality differs.
- If the application cannot be deployed locally, write that up as defect D001 and stop.
