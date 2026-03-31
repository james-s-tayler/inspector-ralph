# Builder Ralph — Iteration Prompt

## Decision: What to Work On

1. Run `git checkout main && git pull origin main` to start from latest green main.
2. Check `defects/prd.json` — if it exists and contains any story where `passes` is `false`, pick the highest-priority one. This is your task.
3. Otherwise, read `scripts/ralph/prd.json` — find the highest-priority story where `passes` is `false`. This is your task.
4. If both are fully complete (all stories have `passes: true`), output `<promise>COMPLETE</promise>` and stop.

## Execution

5. Read the spec, plan, and tasks files referenced in the story description.
6. Read `scripts/ralph/progress.txt` — check the Codebase Patterns section for prior learnings.
7. Create a feature branch from main: `git checkout -b feature/<story-id>`.
8. Implement the feature following the tasks in order.
9. Add e2e tests that exercise every acceptance criterion from the spec.
10. Run the full test suite. All tests must pass (existing + new).
11. Run the build. It must succeed.
12. Commit your changes with clear, atomic commits.
13. Push the branch and open a PR into main:
    ```
    git push -u origin feature/<story-id>
    gh pr create --title "<story title>" --body "<summary of changes and e2e test coverage>"
    ```
14. Wait for CI to pass:
    ```
    gh pr checks --watch
    ```
15. If CI passes, merge the PR:
    ```
    gh pr merge --squash --delete-branch
    ```
16. If CI fails, do NOT merge. Do NOT emit the completion signal. Leave the PR open with a comment describing what failed. End your session — ralph will retry on the next iteration.

## Bookkeeping

17. Update the relevant prd.json (either `defects/prd.json` or `scripts/ralph/prd.json`): set `passes: true` on the completed story and add notes summarizing what was implemented.
18. Append to `scripts/ralph/progress.txt`:
    ```
    ## [Date] - [Story ID]
    - What was implemented
    - Files changed
    - E2E tests added
    - **Learnings for future iterations:**
      - Patterns discovered
      - Gotchas encountered
    ```
19. If you discovered reusable patterns, add them to the Codebase Patterns section at the top of `progress.txt`.
20. Output `<promise>COMPLETE</promise>` ONLY if ALL stories in BOTH `scripts/ralph/prd.json` AND `defects/prd.json` (if it exists) have `passes: true`.

## Constraints

- ALL commits must pass tests and build before being pushed.
- Follow the spec and plan — do not improvise beyond what they specify.
- Do not modify files under `specs/` — they are read-only.
- Each PR should be focused on exactly one feature or defect.
- Keep changes minimal. Do not refactor unrelated code.
