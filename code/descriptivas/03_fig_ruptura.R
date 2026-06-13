###############################################################
# Choque petrolero 2022 - 03_fig_ruptura.R
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Figura de la ruptura del choque 2022 en el subsidio explicito a
#   combustibles fosiles en LATAM (2015-2023). Grid 2x2 (a color, paleta
#   World Bank):
#     (a) Total LATAM, USD miles de millones  -> magnitud del choque
#     (b) Por grupo de exposicion, USD bn      -> quien lo causa
#     (c) Total LATAM, % del PIB               -> esfuerzo fiscal agregado
#     (d) Por grupo, % del PIB                 -> esfuerzo fiscal por grupo
#   El ano del choque (2022) va sombreado y los valores 2021-2022 se anotan
#   sobre los puntos. La nota al pie se compone DENTRO del PNG (via magick,
#   estilo AER/PACES) e incluye la definicion de cada variable.
#
#   Patron: helpers de serie y plot definidos arriba; figura inline abajo.
#   Salida en PNG 300 dpi (integrable en LaTeX) con nota pegada al pie.
#
# Input:  data/processed/panel_pais_anio.xlsx  (306 obs = 34 paises x 9 anios)
# Output: outputs/figures/fig1_ruptura.png     (PNG 300 dpi, nota incluida)
###############################################################

source(here::here("code/config.R"))
suppressMessages(library(ggrepel))

log_file <- iniciar_log("03_fig_ruptura")

# ---------------------------------------------------------------------------
# 1. Carga y verificacion
# ---------------------------------------------------------------------------

df <- cargar_panel_anio()
stopifnot(nrow(df) == 306)                       # 34 paises x 9 anios
n_pais <- dplyr::n_distinct(df$iso)
n_exp  <- dplyr::n_distinct(df$iso[df$exportador_neto])
message("N panel: ", nrow(df), " | ", n_pais, " paises (",
        n_exp, " exportadores, ", n_pais - n_exp, " importadores)")

# ---------------------------------------------------------------------------
# 2. Definiciones (labels) y series
# ---------------------------------------------------------------------------

# Definicion completa de cada concepto de la figura (va en la nota al pie)
labels_vars <- c(
  "Subsidio explicito: brecha entre el precio al consumidor y el costo de suministro",
  "USD bn: suma anual del grupo en miles de millones de dolares corrientes",
  "% del PIB: suma del subsidio del grupo sobre la suma del PIB del grupo",
  "Exportador neto: el alza del Brent infla la renta petrolera que financia el subsidio",
  "Importador neto: el alza del Brent encarece el costo de suministro y agrava el gasto"
)
labels_exp <- pais_es(sort(unique(df$iso[df$exportador_neto])))

# Serie agregada (Total LATAM): subsidio explicito en USD bn y % del PIB
serie_total <- function(d) {
  d |> group_by(anio) |>
    summarise(usd = sum(expl_total, na.rm = TRUE),
              pct = 100 * sum(expl_total, na.rm = TRUE) / sum(gdp, na.rm = TRUE),
              .groups = "drop") |>
    mutate(grupo = "Total LATAM")
}

# Serie por grupo de exposicion al choque
serie_grupo <- function(d) {
  d |> mutate(grupo = ifelse(exportador_neto, "Exportador neto", "Importador neto")) |>
    group_by(grupo, anio) |>
    summarise(usd = sum(expl_total, na.rm = TRUE),
              pct = 100 * sum(expl_total, na.rm = TRUE) / sum(gdp, na.rm = TRUE),
              .groups = "drop")
}

agg_total <- serie_total(df)
agg_grupo <- serie_grupo(df)

# Salto del choque (2021 -> 2022, total LATAM) para nota y anotaciones
v21 <- round(agg_total$usd[agg_total$anio == 2021], 1)
v22 <- round(agg_total$usd[agg_total$anio == 2022], 1)
message("Salto total LATAM 2021->2022: ", v21, " -> ", v22, " USD bn (+",
        round(100 * (v22 - v21) / v21), "%)")

# ---------------------------------------------------------------------------
# 3. Helpers de figura (paleta World Bank, color)
# ---------------------------------------------------------------------------

# Marca del choque (2022): linea vertical de referencia, convencion de event
# studies para un evento puntual (mas precisa que una banda, que marca periodos).
linea_2022 <- geom_vline(xintercept = YEAR_SHOCK, linetype = "dashed",
                         colour = WB_SUBTLE, linewidth = 0.4)

# Anota el valor solo en anos clave: inicio (2015), valle COVID (2020),
# pre-choque (2021), choque (2022) y fin (2023). Cuenta la historia sin saturar.
ANIOS_CLAVE <- c(2015, 2020, 2021, 2022, 2023)
capa_valores <- function(datos, y) {
  d <- datos[datos$anio %in% ANIOS_CLAVE, ]
  geom_text_repel(data = d, aes(label = formatC(.data[[y]], format = "f",
                  digits = ifelse(max(datos[[y]]) > 10, 1, 2))),
                  family = "Times New Roman", size = 2.8, seed = 42,
                  segment.color = NA, min.segment.length = 0,
                  nudge_y = diff(range(datos[[y]])) * 0.05, show.legend = FALSE)
}

panel_ts <- function(datos, y, color_map, ylab, leyenda = FALSE) {
  ggplot(datos, aes(anio, .data[[y]], colour = grupo)) +
    linea_2022 +
    geom_line(linewidth = 0.9) +
    geom_point(size = 1.6) +
    capa_valores(datos, y) +
    scale_x_continuous(breaks = YEARS_OBS) +
    scale_colour_manual(values = color_map) +
    labs(x = NULL, y = ylab) +
    tema_wb_ts() +
    theme(panel.grid.major.y = element_blank(),   # sin lineas horizontales
          legend.position = if (leyenda) "bottom" else "none")
}

col_total <- c("Total LATAM" = WB_CAT[6])        # azul oscuro WB

# ---------------------------------------------------------------------------
# 4. Figura (paneles inline) y composicion del PNG
# ---------------------------------------------------------------------------

message("--- Paneles a-d ---")
# Paneles de total (a, c): color fijo, sin aportar a la leyenda colectada.
# Paneles por grupo (b, d): aportan la unica leyenda (Exportador/Importador).
pa <- panel_ts(agg_total, "usd", col_total, "USD miles de millones") +
  guides(colour = "none")
pb <- panel_ts(agg_grupo, "usd", COLORES_EXPOSICION, NULL, leyenda = TRUE)
pc <- panel_ts(agg_total, "pct", col_total, "% del PIB") +
  guides(colour = "none")
pd <- panel_ts(agg_grupo, "pct", COLORES_EXPOSICION, NULL, leyenda = TRUE)

fig <- (pa | pb) / (pc | pd) +
  plot_layout(guides = "collect") +              # una sola leyenda
  plot_annotation(tag_levels = "a", tag_prefix = "(", tag_suffix = ")") &
  theme(plot.tag = element_text(family = "Times New Roman", size = 10,
                                face = "bold"),
        legend.position = "bottom")              # leyenda centrada abajo

# Nota al pie completa: definicion de variables + grupos + N + salto del choque
nota <- paste0(
  "Subsidio explicito a combustibles fosiles, suma anual de cada grupo. ",
  "La linea vertical marca el ano del choque (2022), cuando el total de LATAM ",
  "paso de ", v21, " a ", v22, " USD miles de millones (+",
  round(100 * (v22 - v21) / v21), "%). ",
  "Variables: ", paste(labels_vars, collapse = ". "), ". ",
  "Exportadores netos (", n_exp, "): ", paste(labels_exp, collapse = ", "),
  "; el resto (", n_pais - n_exp, ") son importadores netos. ",
  "N = ", n_pais, " paises, 2015-2023."
)

save_fig_png(fig, "fig1_ruptura.png", nota = nota,
             fuente = "IMF Fossil Fuel Subsidies Database; precio Brent: EIA.",
             w = 9, h = 7, dpi = 300)
message("  Guardado: fig1_ruptura.png")

# ---------------------------------------------------------------------------
# 5. Verificacion
# ---------------------------------------------------------------------------

out <- file.path(PATH$fig, "fig1_ruptura.png")
stopifnot(file.exists(out), file.info(out)$size > 50000)
message("\nVERIFICACION PASS: ", out, " (",
        round(file.info(out)$size / 1024, 1), " KB)")

cerrar_log()
