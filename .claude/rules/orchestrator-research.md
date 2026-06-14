# Orchestrator Protocol: Research (Simplified)

Use for: single script, exploratory analysis, figure/table generation, ≤ 2 files.

For multi-file or multi-step tasks → use `orchestrator-protocol.md`.

## The Loop

```
Plan approved (or trivial) → simplified orchestrator
  │
  Step 1: IMPLEMENT
  │
  Step 2: VERIFY — MANDATORY
  │   Run script. Confirm:
  │   - Exits without errors
  │   - Output file exists at expected path
  │   - N observations matches CLAUDE.md
  │   If fails → fix → re-verify (max 2 retries)
  │
  Step 3: SCORE
  │
  Score >= 80? → Present summary
  Score < 80?  → Fix → re-verify → re-score (max 3 rounds)
```

**VERIFY is non-negotiable.** Never report done without executing.

## Summary Format

```
## Quick Summary
**Task:** [what was done]
**Score:** N/100
**Files:** [list]
**Verification:** PASS / FAIL
**Notes:** [issues or caveats]
```
