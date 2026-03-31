# Builder Ralph — Iteration Prompt

## Pre-flight Check

1. Run `git checkout main && git pull origin main` to start from latest green main.
2. Run the full test suite and build. If main is broken, do NOT proceed. File a defect in `defects/prd.json` describing the failure ("main is broken: <error details>"), with priority 1. Output nothing else and end your session.

## Decision: What to Work On

3. Check `defects/prd.json` — if it exists and contains any story where `passes` is `false`, pick the highest-priority one. This is your task.
4. Otherwise, read `scripts/ralph/prd.json` — find the highest-priority story where `passes` is `false`. This is your task.
5. If both are fully complete (all stories have `passes: true`), output `<promise>COMPLETE</promise>` and stop.

## Retry Budget

6. Read the `notes` field on the story you picked. If it contains 3 or more entries starting with `"CI FAILURE:"`, this story has exhausted its retry budget. Do NOT attempt it again. Instead:
   a. Close any open PR for this story with a comment explaining repeated CI failures.
   b. File a defect in `defects/prd.json`: `"Could not implement <story-id> after 3 CI failures. See PRs for details."` with priority 1.
   c. Set `passes: true` on the original story with a note `"SKIPPED: retry budget exhausted, defect filed."`.
   d. End your session.

## Execution

7. Read the spec, plan, and tasks files referenced in the story description.
8. Read `scripts/ralph/progress.txt` — check the Codebase Patterns section for prior learnings.
9. Create a feature branch from main: `git checkout -b feature/<story-id>`.
10. Implement the feature following the tasks in order.
11. Add e2e tests that exercise every acceptance criterion from the spec.
12. Run the full test suite. All tests must pass (existing + new).
13. Run the build. It must succeed.
14. Commit your changes with clear, atomic commits.
15. Push the branch and open a PR into main:
    ```
    git push -u origin feature/<story-id>
    gh pr create --title "<story title>" --body "<summary of changes and e2e test coverage>"
    ```
16. Wait for CI to pass:
    ```
    gh pr checks --watch
    ```
17. If CI passes, merge the PR:
    ```
    gh pr merge --squash --delete-branch
    ```
18. If CI fails, do NOT merge. Do NOT emit the completion signal. Append `"CI FAILURE: <date> - <summary of what failed>"` to the story's `notes` field in the relevant prd.json. Leave the PR open with a comment describing what failed. End your session — ralph will retry on the next iteration.

## Bookkeeping

19. Update the relevant prd.json (either `defects/prd.json` or `scripts/ralph/prd.json`): set `passes: true` on the completed story and add notes summarizing what was implemented.
20. Append to `scripts/ralph/progress.txt`:
    ```
    ## [Date] - [Story ID]
    - What was implemented
    - Files changed
    - E2E tests added
    - **Learnings for future iterations:**
      - Patterns discovered
      - Gotchas encountered
    ```
21. If you discovered reusable patterns, add them to the Codebase Patterns section at the top of `progress.txt`.
22. Output `<promise>COMPLETE</promise>` ONLY if ALL stories in BOTH `scripts/ralph/prd.json` AND `defects/prd.json` (if it exists) have `passes: true`.

## Constraints

- ALL commits must pass tests and build before being pushed.
- Follow the spec and plan — do not improvise beyond what they specify.
- Do not modify files under `specs/` — they are read-only.
- Each PR should be focused on exactly one feature or defect.
- Keep changes minimal. Do not refactor unrelated code.
