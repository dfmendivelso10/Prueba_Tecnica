###############################################################
# Choque petrolero 2022 - 04_fig_impacto.R
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Figura 2. Dot plot (Cleveland): impacto fiscal del choque por pais,
#   medido como el cambio en el subsidio explicito a combustibles fosiles
#   entre el promedio pre-choque (2015-2019, periodo "normal" previo a
#   COVID) y el ano del choque (2022), en puntos porcentuales del PIB.
#   Un punto por pais, ordenado de mayor a menor, color por grupo de
#   exposicion fiscal. Sin eje temporal: colapsa cada pais a su impacto,
#   complementando la Figura 1 (dinamica agregada) con el corte
#   transversal del impacto (quien absorbio mas el choque).
#   Se mide en pp del PIB y no en % de cambio: para la discusion fiscal
#   importa el costo presupuestal adicional, no la variacion relativa
#   (que premia bases pre-choque pequenas).
#
# Input:  data/processed/panel_pais_anio.xlsx  (306 obs)
# Output: outputs/figures/fig2_impacto.png     (PNG 300 dpi)
###############################################################

source(here::here("code/config.R"))

log_file <- iniciar_log("04_fig_impacto")

# ---------------------------------------------------------------------------
# 1. Carga y verificacion
# ---------------------------------------------------------------------------

df <- cargar_panel_anio()
stopifnot(nrow(df) == 306)

# ---------------------------------------------------------------------------
# 2. Definiciones (labels) y datos
# ---------------------------------------------------------------------------

labels_vars <- c(
  "Subsidio explicito: brecha entre el precio al consumidor y el costo de suministro, como % del PIB",
  "Impacto del choque: subsidio en 2022 menos el promedio pre-choque (2015-2019), en puntos del PIB",
  "Periodo pre-choque 2015-2019: excluye 2020-2021 (valle y rebote de la pandemia)",
  "Exportador neto: el alza del Brent infla la renta petrolera que financia el subsidio",
  "Importador neto: el alza del Brent encarece el costo de suministro y agrava el gasto"
)

# Cambio del subsidio explicito (pp del PIB): 2022 vs promedio pre-choque.
# Pre = 2015-2019 (periodo "normal", excluye la distorsion COVID 2020-21).
# Se conservan paises con subsidio > 0.05% del PIB en algun ano del periodo.
PISO <- 0.05  # % del PIB

dat <- df |>
  group_by(iso, exportador_neto) |>
  summarise(
    pre  = mean(expl_pctgdp[anio >= 2015 & anio <= 2019] * 100, na.rm = TRUE),
    y22  = expl_pctgdp[anio == 2022][1] * 100,
    maxv = max(expl_pctgdp * 100, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(maxv > PISO) |>
  mutate(
    cambio = y22 - pre,
    grupo  = ifelse(exportador_neto, "Exportador neto", "Importador neto"),
    pais   = pais_es(iso),
    subio  = cambio >= 0
  ) |>
  arrange(cambio) |>
  mutate(pais = factor(pais, levels = pais))

n_pais  <- nrow(dat)
n_exp   <- sum(dat$exportador_neto)
n_imp   <- n_pais - n_exp
n_subio <- sum(dat$subio)
message("Paises (> ", PISO, "% PIB): ", n_pais,
        " | aumentaron: ", n_subio, " | redujeron: ", n_pais - n_subio)
message("Mayor impacto: ",
        paste(utils::head(rev(as.character(dat$pais)), 4), collapse = ", "))

# ---------------------------------------------------------------------------
# 3. Helpers de figura
# ---------------------------------------------------------------------------

# Valor anotado junto a cada punto (pp del PIB, signo explicito).
dat <- dat |>
  mutate(lbl = paste0(ifelse(cambio >= 0, "+", "−"),
                      formatC(abs(cambio), format = "f", digits = 2)),
         hj  = ifelse(cambio >= 0, -0.25, 1.25))

# ---------------------------------------------------------------------------
# 4. Figura (Cleveland dot plot)
# ---------------------------------------------------------------------------

fig <- ggplot(dat, aes(x = cambio, y = pais, colour = grupo)) +
  geom_vline(xintercept = 0, colour = WB_TEXT, linewidth = 0.4) +
  # Tallo del punto a la linea de cero
  geom_segment(aes(x = 0, xend = cambio, y = pais, yend = pais),
               linewidth = 0.35, alpha = 0.5) +
  geom_point(size = 2.4) +
  geom_text(aes(label = lbl, hjust = hj), family = "Times New Roman",
            size = 2.4, colour = WB_TEXT) +
  scale_x_continuous(
    breaks = scales::breaks_pretty(6),
    labels = function(x) paste0(ifelse(x > 0, "+", ""),
                                formatC(x, format = "fg")),
    expand = expansion(mult = c(0.08, 0.10))
  ) +
  scale_colour_manual(values = COLORES_EXPOSICION,
                      guide = guide_legend(reverse = TRUE)) +
  labs(x = "Cambio del subsidio explícito (pp del PIB, 2022 vs. promedio 2015–2019)",
       y = NULL, colour = NULL) +
  tema_wb_ts() +
  theme(
    panel.grid.major.y = element_line(colour = WB_GRID, linewidth = 0.2),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.y        = element_text(size = 7.5, family = "Times New Roman"),
    axis.text.x        = element_text(size = 8),
    legend.position    = "bottom"
  )

# ---------------------------------------------------------------------------
# 5. Nota y guardado
# ---------------------------------------------------------------------------

nota <- paste0(
  "Impacto fiscal del choque por pais: cambio del subsidio explicito a combustibles fosiles ",
  "(puntos porcentuales del PIB) entre el promedio del periodo pre-choque (2015-2019) y el ",
  "ano del choque (2022). Valores positivos indican mayor costo fiscal con el choque ",
  "(", n_subio, " de ", n_pais, " paises), negativos una reduccion. ",
  "El periodo base excluye 2020-2021 para no contaminar la comparacion con el valle y el ",
  "rebote de la pandemia. Se mide en puntos del PIB y no en variacion porcentual, porque ",
  "para la discusion fiscal importa el costo presupuestal adicional y no el cambio relativo, ",
  "que sobreponderaria a paises con un subsidio pre-choque muy pequeno. ",
  "La medida es descriptiva, no una estimacion causal del efecto del choque: cuantifica el ",
  "cambio observado entre ambos momentos, no aisla la contribucion del precio del petroleo ",
  "frente a otros factores. El conjunto de paises de mayor impacto es robusto, aunque el orden ",
  "preciso entre ellos es sensible a la definicion del periodo base. ",
  "Se incluyen los paises con subsidio explicito superior a ", PISO, "% del PIB en algun ano; ",
  "la Tabla 2 reporta el detalle por ano. ",
  "Variables: ", paste(labels_vars, collapse = ". "), ". ",
  "Clasificacion por exposicion fiscal neta: exportadores netos (N = ", n_exp,
  ") e importadores netos (N = ", n_imp, "). N = ", n_pais, " paises."
)

save_fig_png(fig, "fig2_impacto.png", nota = nota,
             fuente = "IMF Fossil Fuel Subsidies Database.",
             w = 7, h = 9, dpi = 300)

# ---------------------------------------------------------------------------
# 6. Verificacion
# ---------------------------------------------------------------------------

out <- file.path(PATH$fig, "fig2_impacto.png")
stopifnot(file.exists(out), file.info(out)$size > 50000)
message("\nVERIFICACION PASS: ", out, " (",
        round(file.info(out)$size / 1024, 1), " KB)")

cerrar_log()
