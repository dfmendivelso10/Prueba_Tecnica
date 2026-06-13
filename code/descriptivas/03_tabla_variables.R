# Tabla 3 - Estadística descriptiva del panel
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Estadística descriptiva de las variables que entran al análisis, por grupo
#   de exposición fiscal (total, exportadores netos, importadores netos).
#   Formato media (DE). Tres bloques temáticos:
#     Panel A: subsidios a combustibles fósiles (% del PIB) - el resultado
#     Panel B: mecanismo de transmisión, brechas precio-costo (USD/litro o /MMBtu)
#     Panel C: choque - precio internacional del Brent (USD/barril), serie global
#   El Brent es común a todos los países cada año (serie internacional), por lo
#   que no se desagrega por grupo: se reporta como contexto del período.
#
# Input:  data/processed/panel_pais_anio.xlsx
# Output: outputs/tables/tab3_variables.xlsx

source(here::here("code/config.R"))

df <- cargar_panel_anio()

# media (DE) de una variable en un subconjunto, con escala opcional (x100 para %)
med_de <- function(x, escala = 1) {
  x <- x[!is.na(x)] * escala
  if (length(x) == 0L) return("")
  paste0(fmt_num(mean(x), 2), " (", fmt_num(sd(x), 2), ")")
}

# Una fila de la tabla: etiqueta + media(DE) en total / exportadores / importadores
fila_var <- function(etq, var, escala = 1) {
  as_tibble(list(
    Variable     = paste0("  ", etq),
    Total        = med_de(df[[var]], escala),
    Exportadores = med_de(df[[var]][df$exportador_neto], escala),
    Importadores = med_de(df[[var]][!df$exportador_neto], escala)
  ))
}

# Fila de etiqueta de panel (vacía en columnas de datos) y fila de N (países)
vacias   <- list(Total = "", Exportadores = "", Importadores = "")
fila_lbl <- function(txt) as_tibble(c(list(Variable = txt), vacias))
fila_n   <- function() as_tibble(list(
  Variable     = "  N (países)",
  Total        = as.character(dplyr::n_distinct(df$iso)),
  Exportadores = as.character(dplyr::n_distinct(df$iso[df$exportador_neto])),
  Importadores = as.character(dplyr::n_distinct(df$iso[!df$exportador_neto]))
))

# Brent: serie global, mismo valor por año -> media (DE) solo en Total
fila_brent <- as_tibble(list(
  Variable     = "  Precio del Brent (USD/barril)",
  Total        = med_de(df$brent_usd),
  Exportadores = "—",
  Importadores = "—"
))

tabla <- bind_rows(
  fila_lbl("Panel A. Subsidios a combustibles fósiles (% del PIB)"),
  fila_var("Subsidio explícito",  "expl_pctgdp", 100),
  fila_var("Subsidio implícito",  "impl_pctgdp", 100),
  fila_var("Subsidio total",      "tot_pctgdp",  100),
  fila_n(),
  fila_lbl("Panel B. Mecanismo de transmisión: brecha precio-costo"),
  fila_var("Brecha gasolina (USD/litro)",       "brecha_gso"),
  fila_var("Brecha diésel (USD/litro)",         "brecha_die"),
  fila_var("Brecha gas natural (USD/MMBtu)",    "brecha_nga"),
  fila_var("Precio gasolina al consumidor (USD/litro)", "precio_gso"),
  fila_var("Costo de suministro gasolina (USD/litro)",  "costo_gso"),
  fila_n(),
  fila_lbl("Panel C. Choque: precio internacional del petróleo"),
  fila_brent
)

names(tabla) <- c("Variable", "Total", "Exportadores netos", "Importadores netos")

tabla_aer(
  tabla,
  name        = "tab3_variables.xlsx",
  titulo      = "Tabla 3. Estadística descriptiva del panel, por grupo de exposición fiscal",
  ancho_datos = 18,
  notas = c(
    paste("Estadística descriptiva de las variables del análisis para el panel de 34 países",
          "de América Latina y el Caribe, 2015-2023. Cada celda reporta la media y, entre",
          "paréntesis, la desviación estándar de las observaciones país-año del grupo."),
    paste("El subsidio explícito es la brecha entre el precio al consumidor y el costo de",
          "suministro; el implícito añade las externalidades no internalizadas y el IVA no",
          "aplicado; el total es la suma de ambos. El subsidio implícito y el total tienen",
          "menor cobertura (no estimados para todos los país-año)."),
    paste("El análisis del choque (Figuras 1 y 2) se concentra en el componente explícito por",
          "ser el más sensible al precio internacional en el corto plazo: reacciona de forma",
          "directa cuando el alza del costo de suministro no se traslada al precio al consumidor.",
          "El implícito depende del volumen consumido y de parámetros de daño ambiental, no del",
          "precio del petróleo, por lo que apenas responde al choque en el corto plazo."),
    paste("Las brechas precio-costo (Panel B) son el canal de transmisión: una brecha negativa",
          "indica precio al consumidor por debajo del costo de suministro, es decir, subsidio."),
    paste("El precio del Brent (Panel C) es la serie internacional, común a todos los países",
          "cada año, por lo que no se desagrega por grupo (se marca con guion)."),
    paste("La clasificación es por exposición fiscal neta al precio del petróleo, no por",
          "producción: en los exportadores netos el alza del Brent infla la renta petrolera",
          "que financia el subsidio, mientras que en los importadores netos encarece el costo",
          "de suministro y agrava el gasto."),
    "Fuente: IMF Fossil Fuel Subsidies Database; precio Brent: EIA."
  )
)
