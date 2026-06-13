# Tabla 1 - Estadística descriptiva de subsidios y contexto fiscal
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Tabla descriptiva del panel país-año. Filas = variables (Media (DE)),
#   columnas = subgrupos en dos ejes: exposición (exportador/importador) y
#   tiempo (pre-choque 2015-2021, choque 2022, post 2023). Tres paneles:
#     Panel A: subsidios en USD miles de millones
#     Panel B: subsidios como % del PIB
#     Panel C: choque y contexto fiscal
#
# Input:  data/processed/panel_pais_anio.xlsx
# Output: outputs/tables/tab1_descriptiva.xlsx

source(here::here("code/config.R"))

df <- cargar_panel_anio()

# Subgrupos por columna
SUB <- list(
  exp = df[df$exportador_neto, ],
  imp = df[!df$exportador_neto, ],
  pre = df[df$anio <= 2021, ],
  y22 = df[df$anio == 2022, ],
  y23 = df[df$anio == 2023, ]
)

# Mediana [P25, P75]; esc = factor de escala (100 para pasar fracción de PIB a %).
# Se usa mediana + IQR (no media + DE) por la fuerte asimetría: ~1/3 de los país-año
# tienen subsidio nulo y unos pocos países concentran montos muy altos.
md <- function(x, esc = 1) {
  x <- x[!is.na(x)] * esc
  if (!length(x)) return("-")
  q <- quantile(x, c(.25, .5, .75), names = FALSE)
  paste0(fmt_num(q[2], 2), " [", fmt_num(q[1], 2), ", ", fmt_num(q[3], 2), "]")
}

# Una fila: variable en Total + los cinco subgrupos
fila <- function(label, var, esc = 1) {
  tibble(
    Variable = paste0("  ", label),
    Total    = md(df[[var]], esc),
    Export   = md(SUB$exp[[var]], esc),
    Import   = md(SUB$imp[[var]], esc),
    Pre      = md(SUB$pre[[var]], esc),
    Y2022    = md(SUB$y22[[var]], esc),
    Y2023    = md(SUB$y23[[var]], esc)
  )
}

# Fila de etiqueta de panel (resto vacío)
panel <- function(label) {
  tibble(Variable = label, Total = "", Export = "", Import = "",
         Pre = "", Y2022 = "", Y2023 = "")
}

# Fila N (tamaños de muestra por subgrupo)
fila_n <- function() {
  tibble(Variable = "N (país-año)", Total = as.character(nrow(df)),
         Export = as.character(nrow(SUB$exp)), Import = as.character(nrow(SUB$imp)),
         Pre = as.character(nrow(SUB$pre)), Y2022 = as.character(nrow(SUB$y22)),
         Y2023 = as.character(nrow(SUB$y23)))
}

tabla <- bind_rows(
  panel("Panel A. Subsidios (USD miles de millones)"),
  fila("Explícito",  "expl_total"),
  fila("Implícito",  "impl_total"),
  fila("Total",      "tot_total"),

  panel("Panel B. Subsidios (% del PIB)"),
  fila("Explícito",  "expl_pctgdp", esc = 100),
  fila("Implícito",  "impl_pctgdp", esc = 100),
  fila("Total",      "tot_pctgdp",  esc = 100),

  panel("Panel C. Canal de precios y contexto fiscal"),
  fila("Brecha de precio gasolina",  "brecha_gso"),
  fila("Brecha de precio diésel",    "brecha_die"),
  fila("Balance fiscal (% PIB) (a)", "balance_fiscal"),
  fila("Ingreso público (% PIB) (a)","ingreso_publico"),

  fila_n()
)

# Encabezados legibles para las columnas
names(tabla) <- c("Variable", "Total", "Exportadores", "Importadores",
                  "2015-2021", "2022", "2023")

tabla_aer(
  tabla,
  name      = "tab1_descriptiva.xlsx",
  titulo    = "Tabla 1. Estadística descriptiva de subsidios y contexto fiscal",
  subheader = c("", "(1)", "(2)", "(3)", "(4)", "(5)", "(6)"),
  notas = c(
    paste("Estadística descriptiva del panel país-año de América Latina y el Caribe,",
          "2015-2023."),
    paste("Cada celda reporta la mediana entre países con el rango intercuartílico",
          "[P25, P75] entre corchetes; los subsidios en niveles están en USD miles de",
          "millones. Se usa la mediana por la fuerte asimetría de la distribución (cerca",
          "de un tercio de los país-año no aplican subsidio explícito)."),
    paste("Las columnas desagregan la muestra completa (1) por condición de exportador neto",
          "de hidrocarburos (2)-(3) y por período relativo al choque petrolero de 2022 (4)-(6);",
          "exportadores netos: Bolivia, Colombia, Ecuador, Guyana, México, Trinidad y Tobago y",
          "Venezuela."),
    paste("(a) Cobertura parcial: la fuente no reporta el dato para todos los país-año.",
          "Las brechas de precio son el precio al consumidor menos el costo de suministro."),
    "Fuentes: IMF Fossil Fuel Subsidies Database y World Bank (WDI)."
  )
)
