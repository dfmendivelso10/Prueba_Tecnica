# Tabla 2 - Subsidio explícito por país, antes y durante el choque
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Desagregado por país del subsidio explícito como % del PIB: nivel pre-choque
#   (media 2015-2021), nivel 2022 y cambio en puntos porcentuales. Dos paneles:
#     Panel A: exportadores netos de hidrocarburos (7)
#     Panel B: importadores netos (27)
#   Ordenado por magnitud del cambio dentro de cada panel.
#
# Input:  data/processed/panel_pais_anio.xlsx
# Output: outputs/tables/tab2_paises.xlsx

source(here::here("code/config.R"))

df <- cargar_panel_anio()

# Subsidio explícito (% PIB) por país: pre-choque, 2022 y cambio en pp
por_pais <- df |>
  group_by(iso, pais, exportador_neto) |>
  summarise(
    pre = 100 * mean(expl_pctgdp[anio <= 2021], na.rm = TRUE),
    y22 = 100 * expl_pctgdp[anio == 2022][1],
    .groups = "drop"
  ) |>
  mutate(cambio = y22 - pre)

# Una fila de la tabla por país
fila_pais <- function(r) {
  tibble(
    Pais     = paste0("  ", r$pais),
    Pre      = fmt_num(r$pre, 2),
    Y2022    = fmt_num(r$y22, 2),
    Cambio   = fmt_num(r$cambio, 2)
  )
}

# Construir un panel (filas ordenadas por cambio descendente)
panel_pais <- function(datos) {
  datos <- datos |> arrange(desc(cambio))
  bind_rows(lapply(seq_len(nrow(datos)), function(i) fila_pais(datos[i, ])))
}

fila_lbl <- function(txt) tibble(Pais = txt, Pre = "", Y2022 = "", Cambio = "")

tabla <- bind_rows(
  fila_lbl("Panel A. Exportadores netos de hidrocarburos"),
  panel_pais(filter(por_pais, exportador_neto)),
  fila_lbl("Panel B. Importadores netos"),
  panel_pais(filter(por_pais, !exportador_neto))
)

names(tabla) <- c("País", "2015-2021", "2022", "Cambio (pp)")

tabla_aer(
  tabla,
  name      = "tab2_paises.xlsx",
  titulo    = "Tabla 2. Subsidio explícito a combustibles fósiles por país (% del PIB)",
  subheader = c("", "(1)", "(2)", "(3)"),
  notas = c(
    paste("Subsidio explícito a los combustibles fósiles como porcentaje del PIB, por país,",
          "antes y durante el choque petrolero de 2022."),
    paste("La columna (1) es el promedio del período pre-choque (2015-2021), (2) el valor de",
          "2022 y (3) el cambio en puntos porcentuales entre ambos."),
    paste("Los países se ordenan por la magnitud del cambio dentro de cada panel. Un valor de",
          "0.00 indica que el país no aplica subsidio explícito (precio al consumidor por",
          "encima del costo de suministro)."),
    "Fuente: IMF Fossil Fuel Subsidies Database."
  )
)
