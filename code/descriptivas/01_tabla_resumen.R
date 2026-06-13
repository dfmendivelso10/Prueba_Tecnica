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
#   Cada panel reporta el subsidio explícito, implícito y total (suma regional
#   USD bn y % del PIB del grupo). Muestra a la vez la trayectoria del choque y
#   la heterogeneidad entre exportadores e importadores.
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

# Fila de N (países del grupo), mismo valor en cada columna de año
fila_n <- function(d) {
  n <- n_distinct(d$iso)
  as_tibble(c(list(Variable = "  N (países)"),
              setNames(as.list(rep(as.character(n), length(anios))),
                       as.character(anios))))
}

# Bloque de un grupo: etiqueta + explícito/implícito/total (USD bn y %PIB) +
# N de países. Orden por sección: los dos componentes y luego su suma.
bloque <- function(etiqueta, d) {
  bind_rows(
    fila_lbl(etiqueta),
    fila("Explícito (USD bn)", serie_suma(d, "expl_total")),
    fila("Implícito (USD bn)", serie_suma(d, "impl_total")),
    fila("Total (USD bn)",     serie_suma(d, "tot_total")),
    fila("Explícito (% PIB)",  serie_pctpib(d, "expl_total"), dec = 2),
    fila("Implícito (% PIB)",  serie_pctpib(d, "impl_total"), dec = 2),
    fila("Total (% PIB)",      serie_pctpib(d, "tot_total"),  dec = 2),
    fila_n(d)
  )
}

tabla <- bind_rows(
  bloque("Panel A. Total LATAM", df),
  bloque("Panel B. Exportadores netos de hidrocarburos", filter(df, exportador_neto)),
  bloque("Panel C. Importadores netos", filter(df, !exportador_neto))
)

# N de países por panel (para las notas)
n_tot <- n_distinct(df$iso)
n_exp <- n_distinct(df$iso[df$exportador_neto])
n_imp <- n_distinct(df$iso[!df$exportador_neto])

tabla_aer(
  tabla,
  name        = "tab1_descriptiva.xlsx",
  titulo      = "Tabla 1. Evolución anual de los subsidios a combustibles fósiles (2015-2023)",
  ancho_datos = 8,
  landscape   = TRUE,
  notas = c(
    paste("Subsidios a combustibles fósiles en América Latina y el Caribe,",
          "por año y grupo de exposición, alrededor del choque petrolero de 2022."),
    paste("Cada celda es la suma del grupo en el año: en USD miles de millones (USD bn) y",
          "como porcentaje del PIB agregado del grupo."),
    paste("El subsidio explícito mide la brecha entre el precio al consumidor y el costo de",
          "suministro; el implícito recoge las externalidades no internalizadas y el IVA no",
          "aplicado; el total es la suma de ambos. El explícito es el componente que reacciona",
          "al choque en el corto plazo; el implícito depende del volumen consumido y de",
          "parámetros de daño ambiental, no del precio internacional. El implícito (y, por",
          "tanto, el total) no está estimado para todos los país-año."),
    paste("La clasificación es por exposición fiscal neta al precio del petróleo, no",
          "por producción: en los exportadores netos el alza del Brent infla la renta",
          "petrolera que financia el subsidio, mientras que en los importadores netos",
          "encarece el costo de suministro y agrava el gasto en subsidios. Argentina",
          "(importador neto de energía en el período) y Brasil (importa los derivados",
          "refinados que se subsidian) se clasifican como importadores."),
    paste0("Panel A, Total LATAM (N = ", n_tot, " países). ",
           "Panel B, exportadores netos de hidrocarburos (N = ", n_exp, "): ",
           "Bolivia, Colombia, Ecuador, Guyana, México, Trinidad y Tobago y Venezuela. ",
           "Panel C, importadores netos (N = ", n_imp, "): ",
           paste(sort(pais_es(unique(df$iso[!df$exportador_neto]))),
                 collapse = ", "), "."),
    "Fuente: IMF Fossil Fuel Subsidies Database."
  )
)
