# Plan: Estadísticas descriptivas (03_eda.R)
**Date:** 2026-06-13  **Status:** DRAFT
**Task:** Estadística descriptiva y EDA del choque petrolero 2022 sobre subsidios fósiles LATAM.

## Objetivo
Caracterizar (descriptivamente, sin inferencia) el efecto del choque Brent 2022 sobre los
subsidios a combustibles fósiles en LATAM y su peso fiscal, dejando lista la intuición para
el modelo posterior. Insumo del entregable 4 (comunicación).

## Decisiones (confirmadas con el usuario)
- Fiscal WB: incluir balance_fiscal e ingreso_publico (reportar N); deuda_publica fuera de
  tablas principales (cobertura 64/306), se menciona como limitación.
- Escala: USD bn (magnitud agregada) + % del PIB (comparabilidad y peso fiscal).
- Distribuciones sesgadas (subsidios, Venezuela domina) -> reportar mediana + IQR junto a media ± DE.
- Eje de heterogeneidad: exportador_neto (7 exportadores vs 27 importadores).
- Ventana: 2015-2023; pre-choque "normal" YEARS_PRE = 2015-2019; choque = 2022.

## Approach
Script único `code/03_eda.R`, sourcing config.R. Estructura: setup -> carga -> tablas -> figuras.

### Tablas (outputs/tables/, vía guardar_tabla)
1. **tab1_resumen_panel.xlsx** — cobertura: N países, años, # exp/imp, no-nulos por variable.
2. **tab2_descriptiva.xlsx** — por variable (subsidios USD bn y %PIB, brechas, Brent, fiscal):
   media, DE, mediana, P25, P75, mín, máx, N. Marca variables sesgadas.
3. **tab3_prepost.xlsx** — 2021 / 2022 / 2023 × {exportador, importador}: subsidio explícito,
   implícito, total (USD bn y %PIB), cambio % 2021->2022 y 2022->2023.

### Figuras (outputs/figures/, PDF cairo, 2022 sombreado, temas AER de config.R)
- **fig1_serie_subsidio_brent.pdf** — subsidio explícito LATAM (barras/línea) + Brent (eje sec.),
  tema_aer_ts. Muestra el co-movimiento choque-subsidio.
- **fig2_expl_vs_impl.pdf** — explícito vs implícito agregado en el tiempo (COLORES_COMPONENTE):
  evidencia de que el explícito es el que reacciona.
- **fig3_cambio_pais.pdf** — cambio % expl_total 2021->2022 por país, barras horizontales
  ordenadas, coloreadas por exportador/importador (COLORES_EXPOSICION), tema_aer_barras.
- **fig4_brecha_tipo.pdf** — brecha de precio gasolina y diésel (precio - costo) promedio por
  tipo de país alrededor de 2022; el canal del subsidio explícito unitario.

## Files to Modify
- `code/03_eda.R` — NUEVO (único archivo de código).
- `outputs/tables/tab1..3_*.xlsx` — NUEVOS.
- `outputs/figures/fig1..4_*.pdf` — NUEVOS.

## Verification
- [ ] `Rscript code/03_eda.R` corre sin errores.
- [ ] 3 tablas + 4 figuras existen en outputs/.
- [ ] N = 306 filas, 34 países, 9 años; 7 exportadores / 27 importadores.
- [ ] Sanity: expl_total LATAM 2022 ~ 79.3 bn; Brent 2022 = 100.9.
- [ ] %PIB convertido a porcentaje (×100) al reportar.
- [ ] Tablas reportan N por variable (cobertura parcial visible).
