---
name: run-analysis
description: Run the full econometric analysis pipeline. Validates environment, executes scripts, and audits results.
argument-hint: "[filename | 'all' | 'regressions' | 'descriptives' | 'timeseries']"
---

# Econometric Analysis Pipeline

## Steps

1. **Validate Environment**
   - Python: `python --version && python -c "import pandas, numpy, statsmodels"`
   - R: `which Rscript && Rscript -e "stopifnot(requireNamespace('here'))"`
   - Verify config file exists (see CLAUDE.md for name)

2. **Identify Scope**
   - Specific file: run that file only
   - `descriptives`: scripts in `code/` with `eda`, `descriptive`, or `00_`/`01_` prefix
   - `regressions`: scripts with `regression`, `estimation`, `model`, `02_`/`03_` prefix
   - `timeseries`: scripts with `ts`, `var`, `arima`, `lp`, `did`, `event` in name
   - `all`: discover and run all scripts in `code/` in order (by numeric prefix)
   - Unknown argument: stop and ask user to clarify

3. **Execute Scripts**
   - Run each via appropriate interpreter, capture logs
   - Config must be imported/sourced — verify this
   - **If any script fails: stop immediately, report full error**

4. **Audit with `econometrics-researcher`**
   - Pass script outputs and logs
   - Agent validates: N, SE type, identification strategy, diagnostics

5. **Code review with `code-reviewer`**
   - Checks paths, variable names, reproducibility

6. **Final Output**
   - Audit report saved to `quality_reports/`
   - Summary to user: pass/fail on Hard Gates, critical issues

## Rules
- Do NOT modify scripts unless user asks after reviewing report
- If step 3 fails, stop — do not audit failed output
