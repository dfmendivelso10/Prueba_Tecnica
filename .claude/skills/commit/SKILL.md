---
name: commit
description: Stage and commit all analysis changes with a descriptive message.
---

# Commit Analysis Changes

1. Run `git status` to see what changed
2. Run `git diff` to review changes
3. Stage relevant files (scripts, outputs, quality_reports)
   - Skip: `data/raw/`, `.env`, any credentials
4. Draft commit message following project convention:
   - Format: `[scope] brief description`
   - Examples: `[timeseries] add VAR(2) with Cholesky decomposition`
   - Examples: `[panel] add DiD with callaway-santanna estimator`
5. Commit with Co-Authored-By line
6. Confirm with `git status`

Do NOT push unless user explicitly asks.
