# Tabla 1 - Evolución anual de los subsidios por grupo (2015-2023)
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Tabla descriptiva principal, en orientación horizontal (landscape).
#   Años en columnas (2015-2023), subsidios en filas, en tres paneles por
#   grupo de exposición al choque:
#     Panel A: Total LATAM
#     Panel B: Exportadores netos de hidrocarburos
#     Panel C: Importadores netos
#   Cada panel reporta el subsidio explícito y total (suma regional USD bn
#   y % del PIB del grupo). Muestra a la vez la trayectoria del choque y la
#   heterogeneidad entre exportadores e importadores.
#
# Input:  data/processed/panel_pais_anio.xlsx
# Output: outputs/tables/tab1_descriptiva.xlsx

source(here::here("code/config.R"))

df <- cargar_panel_anio()
anios <- sort(unique(df$anio))

# Suma de una variable por año dentro de un subconjunto de filas
serie_suma <- function(d, var) {
  sapply(anios, function(a) sum(d[[var]][d$anio == a], na.rm = TRUE))
}
# Subsidio como % del PIB del grupo = suma subsidio / suma PIB, por año
serie_pctpib <- function(d, var) {
  sapply(anios, function(a) {
    s <- d$anio == a
    100 * sum(d[[var]][s], na.rm = TRUE) / sum(d$gdp[s], na.rm = TRUE)
  })
}

# Una fila: etiqueta + un valor por año
fila <- function(label, valores, dec = 1) {
  as_tibble(c(list(Variable = paste0("  ", label)),
              setNames(as.list(fmt_num(valores, dec)), as.character(anios))))
}
fila_lbl <- function(txt) {
  as_tibble(c(list(Variable = txt),
              setNames(as.list(rep("", length(anios))), as.character(anios))))
}

# Bloque de cuatro filas (explícito y total, en USD bn y %PIB) para un grupo
bloque <- function(etiqueta, d) {
  bind_rows(
    fila_lbl(etiqueta),
    fila("Explícito (USD bn)", serie_suma(d, "expl_total")),
    fila("Total (USD bn)",     serie_suma(d, "tot_total")),
    fila("Explícito (% PIB)",  serie_pctpib(d, "expl_total"), dec = 2),
    fila("Total (% PIB)",      serie_pctpib(d, "tot_total"),  dec = 2)
  )
}

tabla <- bind_rows(
  bloque("Panel A. Total LATAM", df),
  bloque("Panel B. Exportadores netos de hidrocarburos", filter(df, exportador_neto)),
  bloque("Panel C. Importadores netos", filter(df, !exportador_neto))
)

tabla_aer(
  tabla,
  name        = "tab1_descriptiva.xlsx",
  titulo      = "Tabla 1. Evolución anual de los subsidios a combustibles fósiles (2015-2023)",
  ancho_datos = 8,
  landscape   = TRUE,
  notas = c(
    paste("Subsidios a combustibles fósiles en América Latina y el Caribe (34 países),",
          "por año y grupo de exposición, alrededor del choque petrolero de 2022."),
    paste("Cada celda es la suma del grupo en el año: en USD miles de millones (USD bn) y",
          "como porcentaje del PIB agregado del grupo. Exportadores netos: Bolivia, Colombia,",
          "Ecuador, Guyana, México, Trinidad y Tobago y Venezuela; el resto son importadores",
          "netos."),
    "Fuente: IMF Fossil Fuel Subsidies Database."
  )
)
