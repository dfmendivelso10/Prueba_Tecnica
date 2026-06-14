---
name: explore-data
description: Quick exploratory data analysis. Distributions, correlations, stationarity tests, missing data summary. Fast-track quality (60/100).
argument-hint: "[variable | dataset | 'all']"
---

# Exploratory Data Analysis

Fast-track exploration. Goal: learn about the data, not publish results.

## Steps

1. **Load data** via project's standard function (see CLAUDE.md)

2. **Summary statistics**
   - N obs, % missing per variable
   - Mean, SD, min/max, p10/p25/p50/p75/p90

3. **If time series / panel:**
   - Unit root tests (ADF, KPSS) for variables in `$ARGUMENTS`
   - Plot time series with recession shading if relevant
   - Correlation matrix with lags

4. **If cross-section:**
   - Distribution plots (histogram + KDE)
   - Correlation heatmap
   - Scatter matrix for key pairs

5. **Report findings** — interpret patterns, flag anomalies

## Quality Bar

60/100 (exploration). Non-negotiable:
- Script runs without errors
- N is correct
- Results make sense

## Output

Save to `code/explorations/YYYY-MM-DD_[description].R` (or .py)
Print summary to console — no formal table needed.
