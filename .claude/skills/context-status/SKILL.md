---
name: context-status
description: Show current project status — active plan, recent git activity, pending outputs.
---

# Context Status

Show a snapshot of where we are:

1. **Active plan:** read most recent non-COMPLETED file in `quality_reports/plans/`
2. **Git status:** `git log --oneline -5` + `git status --short`
3. **Pending outputs:** check `outputs/` for recently modified files
4. **Session log:** print last 10 lines of most recent log in `quality_reports/session_logs/`
5. **MEMORY.md:** print last 5 `[LEARN]` entries

Output as a compact summary.
