# Exploration Fast-Track Protocol

For experimental/exploratory analysis. Lower quality bar (60/100 vs 80).

## When to Use

- "What if we try lag = 2?"
- "Check if X variable is stationary"
- "Quick model with these controls"
- Goal is learning, not publication

## When NOT to Use

- Final models for papers / briefs
- Any output for external audiences (BID, IMF, etc.)
- Pipeline changes that modify `data/` files

## Workflow

1. **Value check** — will this answer a meaningful question?
2. **Implement** — write script directly, no plan-mode
3. **Execute & verify** — runs, N correct, results plausible
4. **Report** — findings + interpretation to user
5. **Decide:**
   - Continue exploring
   - Graduate to production (move to `scripts/`, full quality)
   - Archive (document what was tried and why abandoned)

## Where Explorations Live

- `explorations/` directory
- Temporary scripts (deleted after discussion)

## Kill Switch

Abandon at any time. Note what was tried. Uncertainty is the point.
