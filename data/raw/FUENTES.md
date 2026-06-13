# Fuentes de datos crudos

## imffossilfuelsubsidiesdata.xlsb
- **Fuente:** IMF - Fossil Fuel Subsidies Database (Fiscal Affairs Department)
- **Contenido:** subsidios explícitos e implícitos a combustibles fósiles por país, año,
  combustible y uso final. Escenario baseline (U1).
- **Uso:** fuente principal (obligatoria) del análisis.

## brent_anual.csv
- **Fuente:** U.S. Energy Information Administration (EIA), Europe Brent Spot Price FOB,
  promedio anual en USD por barril. Descargado vía datahub.io/core/oil-prices
  (serie "brent-year", basada en datos EIA).
- **URL:** https://datahub.io/core/oil-prices/r/brent-year.csv
- **Período:** 2015-2023.
- **Uso:** variable del choque de precios internacional. El IMF no incluye el precio
  del barril, por lo que se añade como fuente complementaria.

## fiscal_wb.csv
- **Fuente:** World Bank Open Data (API), tres indicadores fiscales en % del PIB:
  - balance fiscal — GC.NLD.TOTL.GD.ZS
  - deuda pública (gobierno central) — GC.DOD.TOTL.GD.ZS
  - ingreso público — GC.REV.XGRT.GD.ZS
- **Descarga:** reproducible con `python3 code/00b_descargar_fiscal.py`
- **Período / cobertura:** 2015-2023, 34 países de LATAM.
- **Uso:** contextualizar el costo fiscal de los subsidios frente al déficit, la
  deuda y los ingresos públicos. El IMF solo trae ingresos fiscales energéticos.

## riesgo_pais.csv
- **Fuente:** Banco Central de Reserva del Perú (BCRP), serie EMBIG (Diferencial de
  Rendimientos del Índice de Bonos de Mercados Emergentes), spread soberano en
  puntos base. Valores mensuales promediados a anuales.
- **Descarga:** reproducible con `python3 code/00d_descargar_riesgo.py`
- **Cobertura:** 8 países LATAM que emiten deuda en USD (ARG, BRA, CHL, COL, ECU,
  MEX, PER, VEN), 2015-2023. Las islas pequeñas del Caribe no tienen EMBI.
- **Uso:** proxy del costo de financiamiento soberano; permite ver si el choque
  encareció el acceso al crédito de los países.
