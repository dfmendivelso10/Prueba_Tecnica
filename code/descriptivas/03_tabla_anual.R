# Tabla 3 - Evolución anual de los subsidios y el choque (2015-2023)
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Serie temporal regional de los subsidios a combustibles fósiles en LATAM,
#   año a año, alrededor del choque petrolero de 2022. Filas = variables
#   (sumas regionales), columnas = años 2015-2023. Tres paneles:
#     Panel A: subsidios en USD miles de millones (suma regional)
#     Panel B: subsidios como % del PIB regional
#     Panel C: precio internacional del petróleo (referencia del choque)
#
# Input:  data/processed/panel_pais_anio.xlsx
# Output: outputs/tables/tab3_anual.xlsx

source(here::here("code/config.R"))

df <- cargar_panel_anio()
anios <- sort(unique(df$anio))

# Suma regional de una variable por año (en su unidad original)
serie_suma <- function(var) {
  sapply(anios, function(a) sum(df[[var]][df$anio == a], na.rm = TRUE))
}
# Subsidio como % del PIB regional = suma subsidio / suma PIB
serie_pctpib <- function(var) {
  sapply(anios, function(a) {
    s <- df$anio == a
    100 * sum(df[[var]][s], na.rm = TRUE) / sum(df$gdp[s], na.rm = TRUE)
  })
}
# Promedio del Brent por año (es común a todos los países)
serie_brent <- sapply(anios, function(a) mean(df$brent_usd[df$anio == a], na.rm = TRUE))

# Construye una fila: etiqueta + un valor por año
fila <- function(label, valores) {
  as_tibble(c(list(Variable = paste0("  ", label)),
              setNames(as.list(fmt_num(valores, 1)), as.character(anios))))
}
fila_lbl <- function(txt) {
  as_tibble(c(list(Variable = txt),
              setNames(as.list(rep("", length(anios))), as.character(anios))))
}

tabla <- bind_rows(
  fila_lbl("Panel A. Subsidios (USD miles de millones, suma regional)"),
  fila("Explícito", serie_suma("expl_total")),
  fila("Implícito", serie_suma("impl_total")),
  fila("Total",     serie_suma("tot_total")),

  fila_lbl("Panel B. Subsidios (% del PIB regional)"),
  fila("Explícito", serie_pctpib("expl_total")),
  fila("Implícito", serie_pctpib("impl_total")),
  fila("Total",     serie_pctpib("tot_total")),

  fila_lbl("Panel C. Precio internacional del petróleo"),
  fila("Brent (USD/barril)", serie_brent)
)

tabla_aer(
  tabla,
  name        = "tab3_anual.xlsx",
  titulo      = "Tabla 3. Evolución anual de los subsidios y el choque petrolero (2015-2023)",
  ancho_datos = 8,
  notas = c(
    paste("Evolución anual de los subsidios a combustibles fósiles en América Latina y el",
          "Caribe (34 países) alrededor del choque petrolero de 2022."),
    paste("Los paneles A y B reportan la suma regional del subsidio en USD miles de millones",
          "y como porcentaje del PIB regional agregado, respectivamente; el Panel C reporta",
          "el precio promedio anual del crudo Brent."),
    "Fuentes: IMF Fossil Fuel Subsidies Database y EIA (Brent)."
  )
)
