# Tabla 1 - Composición y cobertura del panel
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Tabla descriptiva de entrada: Panel A con la estructura del panel
#   (países, años, observaciones, exportadores/importadores) y Panel B con
#   la cobertura (observaciones no faltantes) de cada variable por fuente.
#
# Input:  data/processed/panel_pais_anio.xlsx
# Output: outputs/tables/tab1_resumen_panel.xlsx

source(here::here("code/config.R"))

df <- cargar_panel_anio()
N <- nrow(df)

# Panel A: estructura del panel
panel_a <- tribble(
  ~Concepto,                      ~Valor,                                       ~Fuente,
  "Países (LATAM y Caribe)",      as.character(n_distinct(df$iso)),             "IMF FFS",
  "Período",                      paste0(min(df$anio), "-", max(df$anio)),      "IMF FFS",
  "Observaciones (país-año)",     as.character(N),                              "",
  "Exportadores netos de petróleo", as.character(n_distinct(df$iso[df$exportador_neto])), "Clasificación propia",
  "Importadores netos",           as.character(n_distinct(df$iso[!df$exportador_neto])),  "Clasificación propia"
)

# Panel B: cobertura por variable (obs no faltantes y % sobre N)
cobertura <- tribble(
  ~Concepto,                ~var,             ~Fuente,
  "Subsidio explícito",     "expl_total",     "IMF FFS",
  "Subsidio implícito",     "impl_total",     "IMF FFS",
  "Subsidio total",         "tot_total",      "IMF FFS",
  "Subsidio explícito (% PIB)", "expl_pctgdp","IMF FFS",
  "Precio Brent",           "brent_usd",      "EIA",
  "Brecha de precio (gasolina)", "brecha_gso","IMF FFS",
  "Balance fiscal (% PIB)", "balance_fiscal", "World Bank",
  "Ingreso público (% PIB)","ingreso_publico","World Bank"
) |>
  mutate(
    obs   = map_int(var, ~ sum(!is.na(df[[.x]]))),
    Valor = paste0(obs, "/", N, " (", round(100 * obs / N), "%)")
  ) |>
  select(Concepto, Valor, Fuente)

# Filas de etiqueta de panel como filas propias (celdas vacías salvo el Concepto),
# para que no pisen datos; tabla_aer las pone en negrita.
fila_lbl <- function(txt) tibble(Concepto = txt, Valor = "", Fuente = "")
cuerpo <- bind_rows(
  fila_lbl("Panel A. Estructura"), panel_a,
  fila_lbl("Panel B. Cobertura por variable (observaciones disponibles)"), cobertura
)
filas_panel <- c(1L, nrow(panel_a) + 2L)  # filas de las dos etiquetas dentro del cuerpo

tabla_aer(
  cuerpo,
  name    = "tab1_resumen_panel.xlsx",
  titulo  = "Tabla 1. Composición y cobertura del panel",
  paneles = setNames(filas_panel, cuerpo$Concepto[filas_panel]),
  notas = c(
    "Panel país-año de subsidios a combustibles fósiles en América Latina y el Caribe.",
    "La deuda pública (World Bank) se excluye por baja cobertura (64/306).",
    "Fuentes: IMF Fossil Fuel Subsidies Database; EIA (Brent); World Bank (WDI)."
  )
)
