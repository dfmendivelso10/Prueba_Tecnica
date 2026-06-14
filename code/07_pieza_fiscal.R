###############################################################
# Choque petrolero 2022 - 07_pieza_fiscal.R
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Implicaciones fiscales del choque y recomendacion de politica. Toma el
#   efecto ya estimado en 06_modelo.R (beta3 = +1.79 pp del PIB en los
#   exportadores netos) y lo cruza con el espacio fiscal de cada pais para
#   convertir el coeficiente en una recomendacion accionable. No re-estima
#   nada: es post-estimacion. Las variables fiscales del WEO (deuda, balance)
#   se usan aqui, no en el modelo (serian "malos controles": consecuencia del
#   subsidio, no causa).
#
#   Figura 5: matriz de politica. Subsidio explicito (% PIB, eje X) contra
#     deuda publica (% PIB, eje Y), corte 2022; color por grupo de exposicion;
#     tamano = aumento del subsidio en USD bn entre 2021 y 2022. Las medianas
#     parten el plano en cuatro cuadrantes (reforma urgente / gradual / etc.).
#   Tabla 5: respaldo por pais (subsidio, cambio observado, costo atribuible al
#     choque via beta3, deuda, balance fiscal, cuadrante), un panel por grupo.
#
# Input:  data/processed/panel_pais_anio.xlsx  (306 obs)
# Output: outputs/figures/fig5_matriz_fiscal.png  (PNG 300 dpi)
#         outputs/tables/tab5_fiscal.xlsx         (tabla AER)
# N matriz: 26 paises con subsidio explicito > 0.05% del PIB en 2022
#           (7 exportadores netos, 19 importadores)
###############################################################

source(here::here("code/config.R"))

log_file <- iniciar_log("07_pieza_fiscal")

# ---------------------------------------------------------------------------
# 1. Carga, verificacion y parametros
# ---------------------------------------------------------------------------

df <- cargar_panel_anio()
stopifnot(nrow(df) == 306)

# Efecto medio del modelo (06_modelo.R, TWFE explicito): el choque sube el
# subsidio explicito 1.79 pp del PIB en los exportadores netos. Es el efecto
# PROMEDIO, no pais-especifico; aqui se usa solo para dimensionar el costo.
BETA3 <- 0.0179        # proporcion del PIB (1.79 pp)
PISO  <- 0.05          # % del PIB: piso de subsidio para entrar a la figura

# ---------------------------------------------------------------------------
# 2. Datos: corte 2022, subsidio vs espacio fiscal
# ---------------------------------------------------------------------------

# Cambio observado 2021->2022 (bruto, no causal) en pp del PIB y en USD bn,
# y nivel de subsidio, deuda y balance en el ano del choque.
dat <- df |>
  filter(anio %in% c(2021, YEAR_SHOCK)) |>
  group_by(iso, exportador_neto) |>
  summarise(
    subsidio  = expl_pctgdp[anio == YEAR_SHOCK][1] * 100,            # % PIB
    cambio_pp = (expl_pctgdp[anio == YEAR_SHOCK][1] -
                 expl_pctgdp[anio == 2021][1]) * 100,                # pp PIB
    cambio_usd = expl_total[anio == YEAR_SHOCK][1] -
                 expl_total[anio == 2021][1],                        # USD bn
    deuda     = deuda_publica[anio == YEAR_SHOCK][1],                # % PIB
    balance   = balance_fiscal[anio == YEAR_SHOCK][1],               # % PIB
    gdp       = gdp[anio == YEAR_SHOCK][1],                          # USD bn
    .groups = "drop"
  ) |>
  filter(subsidio > PISO) |>
  mutate(
    grupo      = ifelse(exportador_neto, "Exportador neto", "Importador neto"),
    pais       = pais_es(iso),
    # Costo atribuible al choque (1.79% del PIB). Solo para exportadores cuyo
    # subsidio efectivamente SUBIO con el choque: beta3 valora un encarecimiento,
    # asi que aplicarlo a un exportador que redujo su subsidio (Guyana, cambio
    # observado < 0) contradiria su propio dato. NA en ese caso y en importadores.
    costo_beta = ifelse(exportador_neto & cambio_pp > 0, BETA3 * gdp, NA_real_)
  )

# gdp en USD bn (mit.gdp.pre.lvl.1): rango LATAM ~0.7 (DMA) a ~1500 (MEX).
# Si una refresca de datos cambia la escala, costo_beta saldria 1000x mal.
stopifnot(all(dat$gdp > 0.1 & dat$gdp < 5000))
# El tamano del punto es cambio_usd; un NA lo dejaria sin burbuja (invisible).
if (anyNA(dat$cambio_usd))
  warning(sum(is.na(dat$cambio_usd)), " pais(es) sin cambio_usd: punto sin tamano")

# Medianas: cortes de la matriz (relativos a la muestra, no umbrales absolutos)
med_sub <- median(dat$subsidio)
med_deu <- median(dat$deuda)

n_pais <- nrow(dat)
n_exp  <- sum(dat$exportador_neto)
n_imp  <- n_pais - n_exp

cat("Paises en la matriz:", n_pais, "(", n_exp, "exportadores,", n_imp, "importadores)\n")
cat("Cortes: subsidio mediana =", fmt_num(med_sub, 2), "% PIB |",
    "deuda mediana =", fmt_num(med_deu, 1), "% PIB\n")

# Cuadrante de politica de cada pais
dat <- dat |>
  mutate(cuadrante = dplyr::case_when(
    subsidio >= med_sub & deuda >= med_deu ~ "Reforma urgente",
    subsidio >= med_sub & deuda <  med_deu ~ "Reforma gradual",
    subsidio <  med_sub & deuda >= med_deu ~ "Vigilar",
    TRUE                                   ~ "Sin presión"
  ))

cat("\n--- Cuadrante 'Reforma urgente' (subsidio y deuda altos) ---\n")
urg <- dat |> filter(cuadrante == "Reforma urgente") |> arrange(desc(subsidio))
for (i in seq_len(nrow(urg))) cat(sprintf("  %-20s subsidio %.1f | deuda %.1f | balance %+.1f\n",
    urg$pais[i], urg$subsidio[i], urg$deuda[i], urg$balance[i]))

# ---------------------------------------------------------------------------
# 3. Figura 5: matriz de politica (subsidio x deuda)
# ---------------------------------------------------------------------------

# Etiquetas de cuadrante, ancladas a las cuatro esquinas del plano (fuera de la
# nube de puntos): arriba/abajo al techo/piso reales de los datos, derecha al
# extremo y izquierda al borde, para que queden parejas y no choquen con paises.
lim_x  <- max(dat$subsidio) * 1.08
techo  <- max(dat$deuda) * 1.05
piso   <- min(dat$deuda) - (max(dat$deuda) - min(dat$deuda)) * 0.04
borde_izq <- min(dat$subsidio) * 0.5
etq <- tibble::tibble(
  x   = c(lim_x, borde_izq, lim_x, borde_izq),
  y   = c(techo, techo, piso, piso),
  txt = c("Reforma urgente", "Vigilar", "Reforma gradual", "Sin presión"),
  hj  = c(1, 0, 1, 0),
  vj  = c(1, 1, 0, 0)
)

fig <- ggplot(dat, aes(subsidio, deuda)) +
  geom_hline(yintercept = med_deu, colour = WB_SUBTLE,
             linetype = "dashed", linewidth = 0.35) +
  geom_vline(xintercept = med_sub, colour = WB_SUBTLE,
             linetype = "dashed", linewidth = 0.35) +
  geom_text(data = etq, aes(x, y, label = txt, hjust = hj, vjust = vj),
            inherit.aes = FALSE, family = "Times New Roman",
            fontface = "italic", size = 2.8, colour = WB_SUBTLE) +
  geom_point(aes(colour = grupo, size = cambio_usd), alpha = 0.75) +
  ggrepel::geom_text_repel(aes(label = pais, colour = grupo),
                           family = "Times New Roman", size = 2.6,
                           seed = 42, max.overlaps = Inf,
                           force = 4, force_pull = 0.4,
                           box.padding = 0.45, point.padding = 0.25,
                           min.segment.length = 0, segment.size = 0.25,
                           segment.colour = WB_SUBTLE, show.legend = FALSE) +
  scale_x_continuous(breaks = scales::breaks_pretty(6),
                     expand = expansion(mult = c(0.06, 0.10))) +
  scale_y_continuous(breaks = scales::breaks_pretty(6),
                     expand = expansion(mult = c(0.06, 0.08))) +
  scale_colour_manual(values = COLORES_EXPOSICION,
                      guide = guide_legend(reverse = TRUE, order = 1)) +
  scale_size_area(max_size = 6, breaks = c(1, 3, 5, 10),
                  labels = function(b) paste0(b, " mil mill. USD")) +
  labs(x = "Subsidio explícito en 2022 (% del PIB)",
       y = "Deuda pública en 2022 (% del PIB)",
       colour = NULL,
       size = "Aumento del subsidio\nentre 2021 y 2022") +
  tema_wb_base() +
  theme(legend.position = "right",
        legend.box = "vertical",
        panel.grid = element_blank())   # sin grilla: los cuadrantes son la referencia

# ---------------------------------------------------------------------------
# 4. Nota y guardado de la figura
# ---------------------------------------------------------------------------

nota_fig <- paste0(
  "Cada punto es un país con subsidio explícito superior a ", PISO, "% del PIB en 2022 (",
  n_pais, " países: ", n_exp, " exportadores netos y ", n_imp, " importadores). El eje horizontal ",
  "mide el peso del subsidio explícito y el vertical la deuda pública bruta, ambos como porcentaje ",
  "del PIB en 2022 (FMI, World Economic Outlook); el tamaño del punto es el aumento del subsidio en ",
  "dólares (miles de millones) entre 2021 y 2022. Las líneas discontinuas marcan la mediana de subsidio (",
  fmt_num(med_sub, 2), "% del PIB) y de deuda (", fmt_num(med_deu, 1), "% del PIB) de esta muestra, ",
  "que parten el plano en cuatro cuadrantes de política: arriba a la derecha (subsidio alto y deuda ",
  "alta) están los países donde la reforma es más urgente, porque el choque encarece un subsidio que ",
  "ya pesa y el margen fiscal para sostenerlo es estrecho; abajo a la derecha, los que subsidian caro ",
  "pero con deuda baja pueden permitirse una transición gradual. El choque de 2022 elevó el subsidio ",
  "explícito de los exportadores netos en torno a 1.8 puntos del PIB (efecto medio estimado en la ",
  "Tabla 4; robusto en signo y magnitud, en un rango de 1.1 a 2.2 puntos al excluir cualquier país, ",
  "Tabla 6), lo que desplaza a varios de ellos hacia la derecha del plano. La deuda y la posición ",
  "fiscal no entran en el modelo del efecto (serían consecuencia del subsidio, no causa) y se usan ",
  "aquí solo para situar ese efecto en el espacio fiscal de cada país. El nivel del subsidio no es ",
  "exclusivo de los exportadores: importadores como Surinam o Argentina aparecen entre los más ",
  "expuestos, de modo que el choque agravó una presión que ya existía."
)

save_fig_png(fig, "fig5_matriz_fiscal.png", nota = nota_fig,
             fuente = "IMF Fossil Fuel Subsidies Database; FMI, World Economic Outlook.",
             w = 8, h = 6.5, dpi = 300)

# ---------------------------------------------------------------------------
# 5. Tabla 5: respaldo por pais (un panel por grupo)
# ---------------------------------------------------------------------------

# Una fila por pais; "n.a." para el costo beta3 de los importadores (no aplica)
fila_pais <- function(d) {
  data.frame(
    Variable = paste0("  ", d$pais),
    subs     = fmt_num(d$subsidio, 2),
    camb_pp  = paste0(ifelse(d$cambio_pp >= 0, "+", "−"), fmt_num(abs(d$cambio_pp), 2)),
    costo    = ifelse(is.na(d$costo_beta), "n.a.", fmt_num(d$costo_beta, 2)),
    deuda    = fmt_num(d$deuda, 1),
    balance  = paste0(ifelse(d$balance >= 0, "+", "−"), fmt_num(abs(d$balance), 1)),
    cuad     = d$cuadrante,
    stringsAsFactors = FALSE
  )
}

# Fila de etiqueta de panel y fila N (las detecta tabla_aer por su prefijo)
fila_lbl <- function(txt) data.frame(Variable = txt, subs = "", camb_pp = "",
                                     costo = "", deuda = "", balance = "", cuad = "")
fila_n   <- function(d) data.frame(Variable = "  N (países)",
                                   subs = as.character(nrow(d)), camb_pp = "",
                                   costo = "", deuda = "", balance = "", cuad = "")

bloque <- function(etiqueta, d) {
  d <- d[order(-d$subsidio), ]
  do.call(rbind, c(list(fila_lbl(etiqueta)),
                   lapply(seq_len(nrow(d)), function(i) fila_pais(d[i, ])),
                   list(fila_n(d))))
}

tabla5 <- rbind(
  bloque("Panel A. Exportadores netos", dat[dat$exportador_neto, ]),
  bloque("Panel B. Importadores netos", dat[!dat$exportador_neto, ])
)
names(tabla5) <- c("País", "Subsidio\n(% PIB)", "Cambio\n2021-22 (pp)",
                   "Costo choque\n(USD mil mill.)", "Deuda\n(% PIB)",
                   "Balance\n(% PIB)", "Cuadrante")

tab_path <- file.path(PATH$tab, "tab5_fiscal.xlsx")
tabla_aer(
  tabla5,
  name        = "tab5_fiscal.xlsx",
  titulo      = "Tabla 5. Subsidio, costo del choque y espacio fiscal por país (2022)",
  ancho_datos = 13,
  landscape   = TRUE,
  notas = c(
    paste("Situación fiscal de cada país con subsidio explícito relevante en 2022, ordenada",
          "por el peso del subsidio dentro de cada grupo. Sirve de respaldo a la matriz de la",
          "Figura 5: cruza cuánto pesa el subsidio con cuánto margen fiscal hay para sostenerlo."),
    paste("Subsidio: subsidio explícito a combustibles fósiles como porcentaje del PIB en 2022.",
          "Cambio 2021 a 2022: variación observada del subsidio de cada país entre ambos años (puntos",
          "del PIB), una medida bruta, no causal, que sí difiere entre países. Costo del choque: el",
          "efecto medio estimado para el grupo (1.79 puntos del PIB, Tabla 4) aplicado por igual al PIB",
          "de cada exportador, en miles de millones de dólares; es una valoración contrafactual del",
          "costo (cuánto representaría ese efecto promedio para cada economía), no el costo observado",
          "país por país, que es heterogéneo y se lee en la columna de cambio. Solo aplica a los",
          "exportadores netos, que es donde el modelo identifica el efecto diferencial; figura como n.a.",
          "en los importadores y en el único exportador cuyo subsidio no subió con el choque (Guyana),",
          "porque valorar un encarecimiento promedio sobre quien lo redujo contradiría su propio dato.",
          "Deuda: deuda pública bruta (% PIB). Balance: resultado fiscal del gobierno general",
          "(% PIB; signo negativo es déficit)."),
    paste0("Cuadrante: posición en la Figura 5 según las medianas de subsidio (",
           fmt_num(med_sub, 2), "% del PIB) y deuda (", fmt_num(med_deu, 1),
           "% del PIB) de la muestra. Reforma urgente reúne a los países por encima de ambas medianas;",
           " sin presión, a los que están por debajo de ambas."),
    paste("Las variables fiscales (deuda, balance) provienen del WEO del FMI y no entran en el",
          "modelo del efecto: se usan ex post para interpretar, no como controles."),
    "Fuente: IMF Fossil Fuel Subsidies Database; FMI, World Economic Outlook."
  )
)
message("\nTabla guardada: ", tab_path)

# ---------------------------------------------------------------------------
# 6. Verificacion
# ---------------------------------------------------------------------------

fig_path <- file.path(PATH$fig, "fig5_matriz_fiscal.png")
# El costo beta3 de Colombia debe reproducir 0.0179 * su PIB (~6.8 USD bn)
costo_col <- dat$costo_beta[dat$iso == "COL"]
stopifnot(
  file.exists(fig_path), file.info(fig_path)$size > 50000,
  file.exists(tab_path),
  n_pais == 26, n_exp == 7,
  abs(costo_col - 0.0179 * dat$gdp[dat$iso == "COL"]) < 1e-6
)
cat("\n--- Verificacion ---\n")
cat("Figura y tabla generadas: OK\n")
cat("Exportadores en la matriz:", n_exp, "(esperado 7): OK\n")
cat("Costo choque Colombia:", fmt_num(costo_col, 2), "USD bn (= 1.79% x PIB): OK\n")
cat("VERIFICACION PASS\n")

cerrar_log()
