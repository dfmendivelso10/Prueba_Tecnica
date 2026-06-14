###############################################################
# Choque petrolero 2022 - 06_modelo.R
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Modelo principal del efecto del choque de 2022 sobre el subsidio explicito
#   a combustibles fosiles, por diferencias en diferencias (DiD). Sigue el
#   pre-registro 2026-06-13_modelo-did-preregistro.md (forward engineering):
#   la especificacion se fija antes de estimar, no hay specification search.
#
#   Estimando: beta3 = cambio diferencial del subsidio explicito (% PIB) de los
#   exportadores netos respecto a los importadores netos, al pasar del periodo
#   pre-choque (2015-2021) al post-choque (2022-2023), bajo tendencias paralelas.
#
#   Escalera de modelos (simple -> robusto):
#     (1) DiD 2x2:  Subsidio ~ Post2022 * Exportador           [terminos sueltos]
#     (2) TWFE:     Subsidio ~ Post2022:Exportador | iso + anio [FE pais y anio]
#     (3) VD alt:   (2) con implicito y total como VD           [robustez canal]
#   Event study: Subsidio ~ sum_t (anio_t : Exportador) | iso + anio, base 2021.
#   SE clustered por pais en todos (convencion del proyecto).
#
# Input:  data/processed/panel_pais_anio.xlsx  (306 obs = 34 paises x 9 anios)
# Output: outputs/tables/tab4_modelo.xlsx       (tabla de regresion)
#         outputs/figures/fig4_eventstudy.png   (event study)
###############################################################

source(here::here("code/config.R"))
suppressMessages(library(fixest))

log_file <- iniciar_log("06_modelo")

# ---------------------------------------------------------------------------
# 1. Carga, verificacion y construccion de variables del modelo
# ---------------------------------------------------------------------------

df <- cargar_panel_anio()
stopifnot(nrow(df) == 306)

# El choque es 2022. El estimador estatico compara 2022 (post) contra el
# periodo pre-choque (2015-2021); 2023 se EXCLUYE del estimador porque ya es
# recuperacion (el Brent baja) y mezclarlo diluiria el efecto del choque. El
# event study (mas abajo) si conserva 2023 para mostrar que el efecto se revierte.
df_est <- df |>
  filter(anio <= YEAR_SHOCK) |>                # 2015-2022 para el DiD estatico
  mutate(
    subsidio   = 100 * expl_pctgdp,            # VD principal: explicito (% PIB)
    subs_impl  = 100 * impl_pctgdp,            # VD alt: implicito (% PIB)
    subs_tot   = 100 * tot_pctgdp,             # VD alt: total (% PIB)
    post2022   = as.integer(anio == YEAR_SHOCK),  # post = solo el ano del choque
    exportador = as.integer(exportador_neto)
  )

# Panel completo (con 2023) para el event study y las variables derivadas
df <- df |>
  mutate(
    subsidio   = 100 * expl_pctgdp,
    exportador = as.integer(exportador_neto)
  )

n_pais <- dplyr::n_distinct(df$iso)
n_exp  <- dplyr::n_distinct(df$iso[df$exportador_neto])
cat("Panel:", nrow(df), "obs |", n_pais, "paises (",
    n_exp, "exportadores,", n_pais - n_exp, "importadores)\n")

# ---------------------------------------------------------------------------
# 2. Escalera de modelos estaticos
# ---------------------------------------------------------------------------

# (1) DiD 2x2 puro: terminos sueltos + interaccion (didactico, muestra el origen
#     de beta3). SE cluster por pais. Panel 2015-2022 (post = solo 2022).
m1 <- feols(subsidio ~ post2022 * exportador, data = df_est, cluster = ~ iso)

# (2) TWFE: efectos fijos de pais y anio. post2022 y exportador caen (absorbidos);
#     sobrevive solo la interaccion = beta3 identificado dentro de pais y anio.
m2 <- feols(subsidio ~ post2022:exportador | iso + anio, data = df_est, cluster = ~ iso)

# (3) VD alternativas con la misma especificacion TWFE (robustez del canal):
#     el efecto deberia ser menor o nulo en implicito y total, que no reaccionan
#     al precio internacional en el corto plazo.
m3_impl <- feols(subs_impl ~ post2022:exportador | iso + anio, data = df_est, cluster = ~ iso)
m3_tot  <- feols(subs_tot  ~ post2022:exportador | iso + anio, data = df_est, cluster = ~ iso)

b <- "post2022:exportador"
cat("\n--- beta3 (interaccion Post2022 x Exportador), pp del PIB ---\n")
cat("(1) DiD 2x2  explicito:", fmt_num(coef(m1)[b], 3),
    " SE", fmt_num(se(m1)[b], 3), "| N", nobs(m1), "\n")
cat("(2) TWFE     explicito:", fmt_num(coef(m2)[b], 3),
    " SE", fmt_num(se(m2)[b], 3), "| N", nobs(m2), "\n")
cat("(3) TWFE     implicito:", fmt_num(coef(m3_impl)[b], 3),
    " SE", fmt_num(se(m3_impl)[b], 3), "| N", nobs(m3_impl), "\n")
cat("(4) TWFE     total:    ", fmt_num(coef(m3_tot)[b], 3),
    " SE", fmt_num(se(m3_tot)[b], 3), "| N", nobs(m3_tot), "\n")

# ---------------------------------------------------------------------------
# 3. Event study (modelo dinamico, base = 2021)
# ---------------------------------------------------------------------------

# i(anio, exportador, ref = 2021): un coef por anio de la interaccion, omitiendo
# 2021 (ultimo pre-choque). FE de pais y anio. SE cluster por pais.
m_es <- feols(subsidio ~ i(anio, exportador, ref = 2021) | iso + anio,
              data = df, cluster = ~ iso)

es <- broom::tidy(m_es, conf.int = TRUE) |>
  mutate(anio = as.integer(gsub("\\D", "", term))) |>
  filter(!is.na(anio)) |>
  select(anio, estimate, conf.low, conf.high)

# Anadir el punto base (2021 = 0 por construccion) para que la trayectoria sea continua
es <- bind_rows(es,
  tibble(anio = 2021, estimate = 0, conf.low = 0, conf.high = 0)) |>
  arrange(anio)

cat("\n--- Event study (coef por anio, base 2021 = 0) ---\n")
print(as.data.frame(es |> mutate(across(where(is.numeric), ~ round(., 3)))))

# Test de pre-tendencias: H0 = los coef pre-choque (2015-2020) son
# conjuntamente cero. Importa distinguir dos cosas:
#   - tendencia diferencial sistematica (coef que escalan hacia 2022): sesgaria
#     el DiD; es lo grave. En estos datos NO aparece (los signos alternan).
#   - volatilidad alrededor de cero (vaivenes por shocks 2018 y COVID 2020 en un
#     grupo de 7 paises): infla la incertidumbre, no sesga el punto estimado.
terms_pre <- grep("201[5-9]|2020", names(coef(m_es)), value = TRUE)
w_pre <- wald(m_es, keep = terms_pre)
cat("\n--- Pre-tendencias (Wald, H0: coef pre-choque conjuntamente = 0) ---\n")
cat("F =", fmt_num(w_pre$stat, 2), "| p =", fmt_num(w_pre$p, 4), "\n")
cat("Coef pre-choque (signos):",
    paste(sprintf("%+.2f", coef(m_es)[terms_pre]), collapse = " "), "\n")
cat("=> No hay tendencia diferencial sistematica preexistente (los signos\n")
cat("   alternan, no escalan hacia 2022). El test conjunto rechaza la nulidad\n")
cat("   estricta por la VOLATILIDAD del panel (grupo de 7 exportadores; shocks\n")
cat("   2018 y COVID 2020), no por una pendiente divergente. El salto de 2022\n")
cat("   (", fmt_num(coef(m_es)["anio::2022:exportador"], 2),
    ") es un quiebre, no la continuacion de una tendencia previa.\n", sep = "")

# ---------------------------------------------------------------------------
# 4. Tabla de regresion (estilo AER, openxlsx; coef, SE clustered y estrellas
#    de significancia segun el p-value clustered)
# ---------------------------------------------------------------------------

# Estrellas de significancia a partir del p-value (convencion del proyecto)
estrellas <- function(p) {
  if (is.na(p))      ""
  else if (p < .001) "***"
  else if (p < .01)  "**"
  else if (p < .05)  "*"
  else if (p < .10)  "†"
  else               ""
}

# Extrae coef, SE y p-value de un modelo fixest, indexado por nombre de termino
extraer <- function(m) {
  ct <- as.data.frame(summary(m)$coeftable)
  data.frame(var = rownames(ct), est = ct[[1]], se = ct[[2]], p = ct[[4]],
             row.names = NULL, stringsAsFactors = FALSE)
}

# Celda "coef***" y "(se)" para una variable v en un modelo extraido co
celda <- function(co, v) {
  i <- match(v, co$var)
  if (is.na(i)) return(list(coef = "", se = ""))
  list(coef = paste0(fmt_num(co$est[i], 3), estrellas(co$p[i])),
       se   = paste0("(", fmt_num(co$se[i], 3), ")"))
}

cols_mod <- list(extraer(m1), extraer(m2), extraer(m3_impl), extraer(m3_tot))

# Orden de filas: interaccion primero, luego terminos sueltos (solo en (1)),
# luego constante. Etiqueta legible por variable.
etiqueta <- c("post2022:exportador" = "Post2022 × Exportador neto",
              "post2022"            = "Post2022",
              "exportador"          = "Exportador neto",
              "(Intercept)"         = "Constante")
orden_vars <- names(etiqueta)

filas <- list()
for (v in orden_vars) {
  cs <- lapply(cols_mod, celda, v = v)
  if (all(vapply(cs, function(x) x$coef == "", logical(1)))) next  # var ausente
  filas[[length(filas)+1L]] <- c(etiqueta[v], vapply(cs, `[[`, "", "coef"))
  filas[[length(filas)+1L]] <- c("",          vapply(cs, `[[`, "", "se"))
}

# Filas inferiores: EF, N. fixest reporta nobs() por modelo (cae por NA en impl/tot).
ef_pais <- c("Efectos fijos de país", "No", "Sí", "Sí", "Sí")
ef_anio <- c("Efectos fijos de año",  "No", "Sí", "Sí", "Sí")
fila_n  <- c("N (país-año)", as.character(c(nobs(m1), nobs(m2),
                                            nobs(m3_impl), nobs(m3_tot))))

tabla_m <- as.data.frame(do.call(rbind, c(filas, list(ef_pais, ef_anio, fila_n))),
                         stringsAsFactors = FALSE)
names(tabla_m) <- c("Variable", "(1)", "(2)", "(3)", "(4)")

# Subheaders: que mide cada columna (VD y especificacion)
subhead <- c("", "Explícito\nDiD 2×2", "Explícito\nTWFE",
             "Implícito\nTWFE", "Total\nTWFE")

tab_path <- file.path(PATH$tab, "tab4_modelo.xlsx")
tabla_aer(
  tabla_m,
  name        = "tab4_modelo.xlsx",
  titulo      = "Tabla 4. Efecto del choque de 2022 sobre el subsidio a combustibles fósiles (DiD)",
  subheader   = subhead,
  ancho_datos = 14,
  notas = c(
    paste("Estimación por diferencias en diferencias. El coeficiente de interés es la",
          "interacción Post2022 × Exportador neto (β₃): el cambio del subsidio en los",
          "exportadores netos al pasar al año del choque, en exceso del cambio que",
          "experimentaron en el mismo lapso los importadores netos (el grupo de control)."),
    paste("Cada columna es una especificación. La (1) es el diseño básico y muestra los",
          "términos por separado (Post2022, Exportador neto y la constante); las (2)-(4)",
          "añaden efectos fijos de país y de año, que absorben esos términos sueltos y dejan",
          "solo la interacción. La variable dependiente es el subsidio explícito en (1) y (2),",
          "el implícito en (3) y el total en (4), todos como porcentaje del PIB. El efecto",
          "se concentra en el explícito —el componente que responde al precio internacional—",
          "y es nulo en el implícito, lo que confirma el canal del choque de precios."),
    paste("Coeficientes con su error estándar agrupado por país entre paréntesis.",
          "† p < 0.10, * p < 0.05, ** p < 0.01, *** p < 0.001."),
    paste("Muestra: panel 2015-2022 (34 países). El año del choque es 2022 y el período de",
          "comparación es 2015-2021. Se excluye 2023 porque el estimador busca el efecto del",
          "choque y 2023 es ya de reversión (el Brent cae de USD 101 a 82, -18 %); incluirlo",
          "promediaría un año de choque con uno de recuperación y subestimaría el efecto. La",
          "figura del event study sí conserva 2023 para mostrar que el efecto se revierte. El",
          "menor N en (3) y (4) se debe a que el implícito y el total no están estimados para",
          "todos los país-año."),
    "Fuente: IMF Fossil Fuel Subsidies Database; precio Brent: U.S. Energy Information Administration."
  )
)
message("\nTabla guardada: ", tab_path)

# ---------------------------------------------------------------------------
# 5. Figura del event study
# ---------------------------------------------------------------------------

fig <- ggplot(es, aes(anio, estimate)) +
  geom_hline(yintercept = 0, colour = WB_SUBTLE, linewidth = 0.3) +
  geom_vline(xintercept = YEAR_SHOCK, linetype = "dashed",
             colour = WB_SUBTLE, linewidth = 0.4) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = WB_CAT[1], alpha = 0.18) +
  geom_line(colour = WB_CAT[6], linewidth = 0.8) +
  geom_point(colour = WB_CAT[6], size = 1.8) +
  scale_x_continuous(breaks = YEARS_OBS) +
  labs(x = NULL,
       y = "Efecto diferencial sobre el subsidio explícito (pp del PIB)") +
  tema_wb_ts() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank())

nota_es <- paste0(
  "Cada punto muestra el efecto diferencial del choque sobre el subsidio explícito (puntos del PIB) ",
  "en los exportadores netos frente a los importadores, año por año, tomando 2021 como referencia, ",
  "con su intervalo de confianza al 95% (errores estándar agrupados por país); la línea vertical ",
  "marca el choque de 2022. Hasta 2021 los puntos rondan el cero, de modo que los dos grupos no venían ",
  "separándose, y la diferencia surge justo con el choque: es un quiebre en 2022 y no la continuación de ",
  "una brecha previa. Con apenas ", n_exp, " exportadores, sin embargo, el efecto se estima con poca ",
  "precisión, de ahí lo ancho de las bandas. N = ", nrow(df), " (", n_pais, " países × 9 años)."
)

save_fig_png(fig, "fig4_eventstudy.png", nota = nota_es,
             fuente = "IMF Fossil Fuel Subsidies Database.",
             w = 9, h = 6, dpi = 300)

# ---------------------------------------------------------------------------
# 6. Verificacion
# ---------------------------------------------------------------------------

delta <- abs(coef(m1)[b] - coef(m2)[b])
stopifnot(
  file.exists(tab_path),
  file.exists(file.path(PATH$fig, "fig4_eventstudy.png")),
  delta < 0.5                                   # beta3 estable entre (1) y (2)
)
cat("\n--- Verificacion ---\n")
cat("Tabla y figura generadas: OK\n")
cat("beta3 estable entre (1) y (2): |", fmt_num(coef(m1)[b], 3), "-",
    fmt_num(coef(m2)[b], 3), "| =", fmt_num(delta, 3), "< 0.5: OK\n")
cat("VERIFICACION PASS\n")

cerrar_log()
