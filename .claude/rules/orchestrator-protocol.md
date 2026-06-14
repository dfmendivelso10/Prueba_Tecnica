# Orchestrator Protocol

After a plan is approved, the orchestrator implements, verifies, reviews, fixes, and scores autonomously.

## The Loop

```
Plan approved → orchestrator activates
  │
  Step 1: IMPLEMENT — Execute plan steps
  │         Independent subtasks → parallel agents (max 3)
  │
  Step 2: VERIFY — Run script, check outputs exist, check N
  │         Fail → fix → re-verify (max 2 retries)
  │
  Step 3: REVIEW — Select and run review agents
  │
  Step 4: FIX — Apply fixes (Critical → Major → Minor)
  │
  Step 5: RE-VERIFY — Confirm fixes clean
  │
  Step 6: SCORE — Apply quality-gates rubric
  │
  └── Score >= 80? → Present summary
      Score < 80?  → Fix → re-score (max 5 rounds)
```

## Agent Selection

| Files Modified | Agents |
|---------------|--------|
| `.py` / `.R` / `.do` (EDA, cleaning, figures) | code-reviewer |
| `.py` / `.R` / `.do` (regression, causal) | code-reviewer + econometrics-researcher |
| Panel data / time series | econometrics-researcher (mandatory) |

## Fix Priority

1. **Critical** — script fails, wrong estimator, wrong N, hard gate violation
2. **Major** — missing robust SE, no NA handling, hardcoded paths
3. **Minor** — naming, comments, style

Max 5 rounds. After max → present with remaining issues.

## Summary Format

```
## Orchestrator Summary
**Task:** ...
**Quality Score:** N/100
**Review Rounds:** N
### Files Created/Modified
### Issues Found and Fixed
### Remaining Issues (if any)
### Recommended Next Steps
```
