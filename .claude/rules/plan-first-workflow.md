---
# Plan-First Workflow & Context Preservation
---

# Plan-First Workflow

**Applies to ALL tasks.**

## Rule 1: Plan Before You Build

Enter Plan Mode for any task that:
- Creates or modifies more than one file
- Implements a new model or pipeline
- Has multiple steps or unclear approach

### Protocol
1. Enter plan mode
2. Check `MEMORY.md` for relevant `[LEARN]` entries
3. Draft plan → save to `quality_reports/plans/YYYY-MM-DD_description.md`
4. Present to user → wait for approval
5. Exit plan mode → implement via orchestrator

Skip planning for:
- Single-file edits with clear scope
- Running existing skills
- Informational questions

---

## Rule 2: Save Plans to Disk

```
quality_reports/plans/YYYY-MM-DD_short-description.md
```

Format:
```markdown
# Plan: [Short Description]
**Date:** YYYY-MM-DD  **Status:** DRAFT | APPROVED | IN PROGRESS | COMPLETED
**Task:** [What the user asked]

## Approach
1. ...

## Files to Modify
- `path/file` — what changes

## Verification
- [ ] check 1
- [ ] check 2
```

---

## Rule 3: Never /clear

Use auto-compression. Save plans to disk as a safety net.

**Session Recovery:**
1. Read `CLAUDE.md`
2. Read most recent plan in `quality_reports/plans/`
3. Check `git log --oneline -10`
4. Check `git diff` for uncommitted work

---

## Rule 4: [LEARN] Tags

When a mistake is corrected: `[LEARN:category] Wrong assumption → correct fact`

Categories: `python`, `r`, `stata`, `variables`, `econometria`, `workflow`

---

## Rule 5: Session Logging

Logs at `quality_reports/session_logs/YYYY-MM-DD_description.md`

- **5a. Post-plan:** create log immediately after plan approval
- **5b. Incremental:** append when decisions change, problems found, user corrects
- **5c. End-of-session:** wrap up when user signals done
