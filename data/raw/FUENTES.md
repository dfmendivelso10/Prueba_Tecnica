# Fuentes de datos crudos

Las fuentes marcadas **[en el panel]** se integran al panel de análisis
(`data/processed/panel_pais_anio.xlsx`). Las marcadas **[descargada, no integrada]**
se descargan de forma reproducible y quedan en el repo por trazabilidad, pero no
entran al panel principal (se documenta el motivo en cada caso).

## imffossilfuelsubsidiesdata.xlsb  [en el panel]
- **Fuente:** IMF - Fossil Fuel Subsidies Database (Fiscal Affairs Department)
- **Contenido:** subsidios explícitos e implícitos a combustibles fósiles por país, año,
  combustible y uso final. Escenario baseline (U1).
- **Uso:** fuente principal (obligatoria) del análisis.

## brent_anual.csv  [en el panel]
- **Fuente:** U.S. Energy Information Administration (EIA), Europe Brent Spot Price FOB,
  promedio anual en USD por barril. Descargado vía datahub.io/core/oil-prices
  (serie "brent-year", basada en datos EIA).
- **URL:** https://datahub.io/core/oil-prices/r/brent-year.csv
- **Período:** 2015-2023.
- **Uso:** variable del choque de precios internacional. El IMF no incluye el precio
  del barril, por lo que se añade como fuente complementaria.

## fiscal_wb.csv  [en el panel]
- **Fuente:** World Bank Open Data (API), tres indicadores fiscales en % del PIB:
  - balance fiscal — GC.NLD.TOTL.GD.ZS
  - deuda pública (gobierno central) — GC.DOD.TOTL.GD.ZS
  - ingreso público — GC.REV.XGRT.GD.ZS
- **Descarga:** reproducible con `python3 code/00b_descargar_fiscal.py`
- **Período / cobertura:** 2015-2023, 34 países de LATAM.
- **Uso:** contextualizar el costo fiscal de los subsidios frente al déficit, la
  deuda y los ingresos públicos. El IMF solo trae ingresos fiscales energéticos.

## riesgo_pais.csv  [descargada, no integrada]
- **Fuente:** Banco Central de Reserva del Perú (BCRP), serie EMBIG (Diferencial de
  Rendimientos del Índice de Bonos de Mercados Emergentes), spread soberano en
  puntos base. Valores mensuales promediados a anuales.
- **Descarga:** reproducible con `python3 code/00d_descargar_riesgo.py`
- **Cobertura:** 8 países LATAM que emiten deuda en USD (ARG, BRA, CHL, COL, ECU,
  MEX, PER, VEN), 2015-2023. Las islas pequeñas del Caribe no tienen EMBI.
- **Uso:** proxy del costo de financiamiento soberano. **No se integra al panel:**
  su cobertura (8 de 34 países, 70/306 observaciones) sesgaría la muestra hacia las
  economías grandes. Se conserva como referencia complementaria.

## reservas_wb.csv  [descargada, no integrada]
- **Fuente:** World Bank Open Data (API), reservas internacionales:
  - reservas totales (incl. oro), USD corrientes — FI.RES.TOTL.CD
  - reservas en meses de importaciones — FI.RES.TOTL.MO
- **Descarga:** reproducible con `python3 code/00e_descargar_reservas.py`
- **Período / cobertura:** 2015-2023, 34 países de LATAM (291/284 observaciones).
- **Uso:** dimensión de balanza de pagos (holgura externa). **No se integra al panel.**
  Se conserva como referencia por si se retoma el ángulo externo.
