---
paths:
  - "**/*.R"
  - "outputs/tables/**"
---

# Table Standards

## Export Format
- All tables export to Excel (`.xlsx`) using `openxlsx`.
- No LaTeX or HTML table exports unless explicitly requested.

## General Layout (AER-based, with project overrides)
- Columns in vertical (portrait) orientation.
- Maximum 9 columns wide including row headings.
- Number tables consecutively with Arabic numerals.
- Use only horizontal lines and blank space to show structure. No vertical lines.
- No shading.
- Do not abbreviate in column headings.
- Use Panel A, Panel B, etc. to denote sections within a table.
- Place a zero in front of all decimal fractions (e.g., 0.357, not .357).

## Typography
- Font: Times New Roman throughout.
- Title: 13pt, bold.
- Headers: 11pt, bold, centered.
- Subheaders: 10pt, centered.
- Data cells: 10pt, centered.
- Variable names: 10pt, bold, left-aligned.
- Notes: 9pt. First line italic (description), rest normal (methodology).

## Column Structure

### Descriptive Tables (prevalence, scores)
- Columns: Item/Variable | Total | Subgroup A | Subgroup B | Sig (A vs B) | Subgroup C | Subgroup D | Sig (C vs D)
- Subheader row with column numbers: (1), (2), (3), blank, (4), (5), blank.
- Subgroups are defined by the project's stratification variables (e.g., sex, SES, treatment arm). Read `config.R` or the project documentation to identify them.
- Last row: N (sample sizes per group).

### Regression Tables
- Columns: Variable | M1 | M2 | M3 | ...
- One column per model specification. Label columns by model name or specification description.
- Subheader row with column numbers: (1), (2), (3), ...

## Variable Order in Regression Tables
1. Main predictor(s) of interest — always first.
2. Demographic and structural controls.
3. Continuous controls (standardized if applicable).
4. Moderators, protective factors, or interaction terms added in later models.
5. Constant — always last.
6. Below the line (summary statistics): N, R², R² adjusted.

## Cell Formatting

### Descriptive Tables
- Prevalence: `% (DE)` where DE = sqrt(p*(1-p)).
- Scores: `Mean (SD)`.
- Significance column: stars only, no p-value.

### Regression Tables
- Coefficient on its own line.
- Standard error in parentheses on the line below: `(0.123)`.
- Stars attached to the coefficient, not the SE.
- R², R² adjusted, and N reported below the last variable, separated by a line.

## Significance Stars
- **PROJECT RULE (oil-shock project): regression tables REPORT significance stars** based on
  the clustered p-value, with the significance-level line in the footnotes. Descriptive tables
  still report point estimates only (no between-group test exists in this project).
- `***` p < 0.001
- `**` p < 0.01
- `*` p < 0.05
- `†` p < 0.10 (only in regression tables; omit in descriptive tables)

## Statistical Tests for Descriptive Tables
- (Not used in this project — see the override above.)
- Proportions: Chi-squared; Fisher exact test when any expected cell < 5.
- Means: t-test (Student).
- Always state the test used in the footnotes.

## Variable Labels
- All variable labels in the project's language.
- Use clean, readable names, not raw variable codes.
- Define a label mapping function (e.g., `limpiar_var()`); do not hardcode labels inline.

## Footnotes (AER format)
- **PROJECT OVERRIDE — running prose:** all footnotes go in a SINGLE continuous paragraph
  (one merged cell spanning the table width, wrapped text), prefixed `Notas.` — NOT one row
  per numbered point. The order below is the order of sentences within that paragraph.
- For footnotes pertaining to specific table entries, use lowercase letters as keys (a, b, c), not numbers or symbols.
- Order of footnotes:
  1. Brief description of the table content (italic).
  2. Significance levels: `*** p<0.001, ** p<0.01, * p<0.05` (add `† p<0.10` for regression tables).
  3. Statistical test or estimation method used.
  4. Format of reported values (e.g., "Mean (SD)", "SE in parentheses", "Standardized variables (z-score)").
  5. Definition of grouping/stratification variables.
  6. Sample restrictions if applicable.
  7. Source note, if any — always last, after all other notes.
  8. Full citations of sources go in the references, not in the footnote.

## Excel Formatting
- Column widths: variable name column = 22, data columns = 14.
- Borders: headers with solid borders (#888888), data cells with light borders (#CCCCCC). Horizontal only.
- Row heights: title = 22, header = 18.
- Left margin column (column A): width = 2, empty.

## Anti-Patterns
- Never export raw R output without formatting.
- Never use `print()` or `cat()` of model summaries as final output.
- Never mix languages in labels within the same table.
- Never omit the N row in descriptive tables.
- Never omit footnotes.
- Never report coefficients without standard errors in regression tables.
- Never use vertical lines or shading.
- Never abbreviate column headings.
- Never omit the leading zero in decimals (write 0.357, not .357).
- Never use asterisks or numbers as footnote keys for specific entries; use lowercase letters (a, b, c).