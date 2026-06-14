###############################################################
# Choque petrolero 2022 - 04_fig_brent.R
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Figura 2. Co-movimiento entre el precio internacional del petroleo (Brent,
#   variable de tratamiento) y el subsidio explicito agregado de LATAM
#   (variable de resultado), 2015-2023. Doble eje: Brent (USD/barril) a la
#   izquierda, subsidio explicito (% del PIB regional) a la derecha. La linea
#   vertical marca el choque (2022). Presenta el tratamiento, lo cruza con el
#   resultado y motiva visualmente la pregunta causal: las dos series se mueven
#   juntas (corr = 0.75), y el modelo cuantifica esa relacion por grupo.
#
# Input:  data/processed/panel_pais_anio.xlsx  (306 obs)
# Output: outputs/figures/fig2_brent.png       (PNG 300 dpi)
###############################################################

source(here::here("code/config.R"))

log_file <- iniciar_log("04_fig_brent")

# ---------------------------------------------------------------------------
# 1. Carga y verificacion
# ---------------------------------------------------------------------------

df <- cargar_panel_anio()
stopifnot(nrow(df) == 306)

# ---------------------------------------------------------------------------
# 2. Definiciones (labels) y series agregadas
# ---------------------------------------------------------------------------

labels_vars <- c(
  "Brent: precio internacional del petroleo (USD por barril), promedio anual; es la variable de tratamiento",
  "Subsidio explicito: brecha entre el precio al consumidor y el costo de suministro, suma de LATAM como % del PIB",
  "Co-movimiento: las dos series se mueven juntas (correlacion 0.75); el modelo lo cuantifica por grupo"
)

agg <- df |>
  group_by(anio) |>
  summarise(
    brent   = mean(brent_usd, na.rm = TRUE),
    sub_pct = 100 * sum(expl_total, na.rm = TRUE) / sum(gdp, na.rm = TRUE),
    .groups = "drop"
  )

corr <- round(cor(agg$brent, agg$sub_pct), 2)
message("Correlacion Brent vs subsidio (% PIB): ", corr)

# ---------------------------------------------------------------------------
# 3. Escalado del eje secundario
# ---------------------------------------------------------------------------

# Mapear el subsidio (% PIB) al rango del eje del Brent para superponerlos.
# rescala: sub_pct -> escala Brent ; el eje derecho deshace la transformacion.
r_brent <- range(agg$brent)
r_sub   <- range(agg$sub_pct)
a <- diff(r_brent) / diff(r_sub)
b <- r_brent[1] - a * r_sub[1]
to_brent <- function(x) a * x + b      # subsidio -> escala Brent
to_sub   <- function(y) (y - b) / a    # escala Brent -> subsidio (eje derecho)

agg <- agg |> mutate(sub_en_brent = to_brent(sub_pct))

# ---------------------------------------------------------------------------
# 4. Figura
# ---------------------------------------------------------------------------

col_brent <- WB_CAT[6]        # azul oscuro WB: tratamiento
col_sub   <- WB_CAT[2]        # naranja WB: resultado

fig <- ggplot(agg, aes(x = anio)) +
  geom_vline(xintercept = YEAR_SHOCK, linetype = "dashed",
             colour = WB_SUBTLE, linewidth = 0.4) +
  geom_line(aes(y = brent, colour = "Brent"), linewidth = 0.9) +
  geom_point(aes(y = brent, colour = "Brent"), size = 1.8) +
  geom_line(aes(y = sub_en_brent, colour = "Subsidio"), linewidth = 0.9) +
  geom_point(aes(y = sub_en_brent, colour = "Subsidio"), size = 1.8) +
  scale_colour_manual(
    values = c("Brent" = col_brent, "Subsidio" = col_sub),
    labels = c("Brent" = "Precio del Brent",
               "Subsidio" = "Subsidio explícito"),
    breaks = c("Brent", "Subsidio")
  ) +
  scale_x_continuous(breaks = YEARS_OBS) +
  scale_y_continuous(
    name     = "Precio del Brent (USD por barril)",
    sec.axis = sec_axis(~ to_sub(.), name = "Subsidio explícito (% del PIB)")
  ) +
  labs(x = NULL, colour = NULL) +
  tema_wb_ts() +
  theme(
    panel.grid.major     = element_blank(),   # sin grilla de fondo
    panel.grid.minor     = element_blank(),
    axis.title.y.left    = element_text(colour = col_brent),
    axis.title.y.right   = element_text(colour = col_sub),
    axis.text.y.right    = element_text(colour = col_sub),
    axis.text.y.left     = element_text(colour = col_brent),
    legend.position      = "bottom"
  )

# ---------------------------------------------------------------------------
# 5. Nota y guardado
# ---------------------------------------------------------------------------

nota <- paste0(
  "Co-movimiento entre el precio internacional del petroleo (Brent, linea azul, eje izquierdo) ",
  "y el subsidio explicito a combustibles fosiles agregado de America Latina y el Caribe ",
  "(linea naranja, eje derecho), 2015-2023. La linea vertical marca el ano del choque (2022). ",
  "La correlacion entre ambas series es de ", corr, ". El subsidio explicito reacciona al precio ",
  "internacional porque el alza del costo de suministro, si no se traslada al precio al consumidor, ",
  "amplia el subsidio. El doble eje superpone dos escalas distintas; la lectura es del co-movimiento ",
  "(direccion y giros comunes), no de niveles comparables entre las dos series. ",
  "Variables: ", paste(labels_vars, collapse = ". "), "."
)

save_fig_png(fig, "fig2_brent.png", nota = nota,
             fuente = "IMF Fossil Fuel Subsidies Database; precio Brent: EIA.",
             w = 9, h = 6, dpi = 300)

# ---------------------------------------------------------------------------
# 6. Verificacion
# ---------------------------------------------------------------------------

out <- file.path(PATH$fig, "fig2_brent.png")
stopifnot(file.exists(out), file.info(out)$size > 50000)
message("\nVERIFICACION PASS: ", out, " (",
        round(file.info(out)$size / 1024, 1), " KB)")

cerrar_log()
