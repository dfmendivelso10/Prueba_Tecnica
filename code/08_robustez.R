###############################################################
# Choque petrolero 2022 - 08_robustez.R
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Robustez del efecto principal (beta3, 06_modelo.R) a paises extremos.
#   La muestra principal (34 paises) NO se toca: es la especificacion
#   pre-registrada. Aqui se re-estima el TWFE quitando los outliers a mano
#   para mostrar que el efecto sobrevive en signo y orden de magnitud:
#     (1) muestra completa (replica la Tabla 4)
#     (2) sin Venezuela  (el exportador con el subsidio mas extremo)
#     (3) sin Surinam    (el importador con el subsidio mas extremo, en el control)
#     (4) sin ambos
#   La nota reporta el rango leave-one-out de los 7 exportadores (re-estimar
#   beta3 quitando uno a la vez): la prueba sistematica de que el efecto no lo
#   carga un solo pais. Quitar paises por el valor de la VD sesgaria si fuera
#   la especificacion principal; como chequeo de sensibilidad junto a la
#   completa, es legitimo y transparente.
#
# Input:  data/processed/panel_pais_anio.xlsx  (306 obs)
# Output: outputs/tables/tab6_robustez.xlsx
# N:      estimador estatico 2015-2022 = 269 (cae 3 por NA en LHS).
#         Submuestras: sin VEN 261, sin SUR 261, sin ambos 253.
###############################################################

source(here::here("code/config.R"))
suppressMessages(library(fixest))

log_file <- iniciar_log("08_robustez")

# ---------------------------------------------------------------------------
# 1. Carga y construccion (igual que el estimador estatico de 06_modelo.R)
# ---------------------------------------------------------------------------

df <- cargar_panel_anio()
stopifnot(nrow(df) == 306)

df_est <- df |>
  filter(anio <= YEAR_SHOCK) |>                # 2015-2022 (post = solo 2022)
  mutate(
    subsidio   = 100 * expl_pctgdp,
    post2022   = as.integer(anio == YEAR_SHOCK),
    exportador = as.integer(exportador_neto)
  )

b <- "post2022:exportador"

# TWFE principal (mismo de la columna (2) de la Tabla 4). post2022 equivale al
# dummy de 2022 y queda absorbido por el FE de anio; solo la interaccion se
# identifica (dentro de pais y anio), que es beta3.
twfe <- function(dd) feols(subsidio ~ post2022:exportador | iso + anio,
                           data = dd, cluster = ~ iso)

# ---------------------------------------------------------------------------
# 2. Escalera de robustez: completa / sin VEN / sin SUR / sin ambos
# ---------------------------------------------------------------------------

m1 <- twfe(df_est)                                          # completa
m2 <- twfe(filter(df_est, iso != "VEN"))                    # sin Venezuela
m3 <- twfe(filter(df_est, iso != "SUR"))                    # sin Surinam
m4 <- twfe(filter(df_est, !iso %in% c("VEN", "SUR")))       # sin ambos
mods <- list(m1, m2, m3, m4)

cat("--- beta3 (Post2022 x Exportador), pp del PIB ---\n")
etq_col <- c("completa", "sin Venezuela", "sin Surinam", "sin ambos")
for (i in seq_along(mods)) {
  m <- mods[[i]]
  cat(sprintf("(%d) %-14s beta3 = %s  SE %s | N %d\n",
              i, etq_col[i], fmt_num(coef(m)[b], 3), fmt_num(se(m)[b], 3), nobs(m)))
}

# ---------------------------------------------------------------------------
# 3. Leave-one-out de exportadores (re-estimar quitando uno a la vez)
# ---------------------------------------------------------------------------

exps <- sort(unique(df_est$iso[df_est$exportador == 1]))
loo  <- vapply(exps, function(x) coef(twfe(filter(df_est, iso != x)))[b], numeric(1))
loo_min <- min(loo); loo_max <- max(loo)
pais_min <- pais_es(exps[which.min(loo)])

cat("\n--- Leave-one-out exportadores (", length(exps), ") ---\n")
for (i in seq_along(exps))
  cat(sprintf("  sin %-4s (%-18s) beta3 = %s\n",
              exps[i], pais_es(exps[i]), fmt_num(loo[i], 3)))
cat(sprintf("Rango LOO: [%s, %s] | minimo al quitar %s\n",
            fmt_num(loo_min, 2), fmt_num(loo_max, 2), pais_min))

# ---------------------------------------------------------------------------
# 4. Tabla 6 (estilo AER) — helpers identicos a 06_modelo.R
# ---------------------------------------------------------------------------

estrellas <- function(p) {
  if (is.na(p))      ""
  else if (p < .001) "***"
  else if (p < .01)  "**"
  else if (p < .05)  "*"
  else if (p < .10)  "†"
  else               ""
}

celda <- function(m) {
  ct <- as.data.frame(summary(m)$coeftable)[b, ]
  list(coef = paste0(fmt_num(ct[["Estimate"]], 3), estrellas(ct[["Pr(>|t|)"]])),
       se   = paste0("(", fmt_num(ct[["Std. Error"]], 3), ")"))
}

cs   <- lapply(mods, celda)
fila_coef <- c("Post2022 × Exportador neto", vapply(cs, `[[`, "", "coef"))
fila_se   <- c("",                           vapply(cs, `[[`, "", "se"))
ef_pais   <- c("Efectos fijos de país", rep("Sí", length(mods)))
ef_anio   <- c("Efectos fijos de año",  rep("Sí", length(mods)))
fila_n    <- c("N (país-año)", vapply(mods, function(m) as.character(nobs(m)), ""))

tabla6 <- as.data.frame(
  rbind(fila_coef, fila_se, ef_pais, ef_anio, fila_n),
  stringsAsFactors = FALSE
)
names(tabla6) <- c("Variable", "(1)", "(2)", "(3)", "(4)")

subhead <- c("", "Muestra\ncompleta", "Sin\nVenezuela",
             "Sin\nSurinam", "Sin\nambos")

# Subsidio maximo de VEN y SUR (2022), para no hardcodear en la nota
ven_max <- fmt_num(max(df_est$subsidio[df_est$iso == "VEN"], na.rm = TRUE), 1)
sur_max <- fmt_num(max(df_est$subsidio[df_est$iso == "SUR"], na.rm = TRUE), 1)

tab_path <- file.path(PATH$tab, "tab6_robustez.xlsx")
tabla_aer(
  tabla6,
  name        = "tab6_robustez.xlsx",
  titulo      = "Tabla 6. Robustez del efecto del choque a países extremos",
  subheader   = subhead,
  ancho_datos = 13,
  notas = c(
    paste("Chequeo de sensibilidad del coeficiente principal (β₃, Post2022 × Exportador neto)",
          "a la exclusión de los países con subsidio más extremo. Todas las columnas son la",
          "misma especificación TWFE de la Tabla 4 (efectos fijos de país y de año, errores",
          "estándar agrupados por país); solo cambia la muestra."),
    paste0("La columna (1) es la muestra completa pre-registrada (34 países) y reproduce la ",
           "Tabla 4. Las columnas (2)-(4) la re-estiman quitando a Venezuela (el exportador con ",
           "el subsidio más alto, ", ven_max, "% del PIB), a Surinam (el importador con el subsidio ",
           "más alto, ", sur_max, "% del PIB, que pesa en el grupo de control) y a ambos. El efecto se ",
           "mantiene positivo en todas: el choque no lo carga un país aislado. Quitar a Venezuela lo ",
           "reduce (de ", fmt_num(coef(m1)[b], 2), " a ", fmt_num(coef(m2)[b], 2), ") porque amplifica el ",
           "efecto, pero no lo crea; quitar a Surinam lo aumenta (", fmt_num(coef(m3)[b], 2),
           ") porque despeja el grupo de control de un subsidiador atípico."),
    paste0("Como prueba sistemática, al re-estimar β₃ excluyendo cada exportador por separado ",
           "(leave-one-out de los ", length(exps), " exportadores) la estimación puntual queda en el ",
           "rango [", fmt_num(loo_min, 2), ", ", fmt_num(loo_max, 2), "], siempre positiva; el valor más ",
           "bajo corresponde a la exclusión de ", pais_min, ". Es el rango de coeficientes, no un ",
           "intervalo de confianza."),
    paste("Entre paréntesis, los errores estándar agrupados por país.",
          "† p < 0.10, * p < 0.05, ** p < 0.01, *** p < 0.001."),
    "Fuente: IMF Fossil Fuel Subsidies Database; precio Brent: U.S. Energy Information Administration."
  )
)

# ---------------------------------------------------------------------------
# 5. Verificacion
# ---------------------------------------------------------------------------

stopifnot(
  file.exists(tab_path),
  abs(coef(m1)[b] - 1.790) < 0.05,        # col (1) replica la Tabla 4
  all(loo > 0),                            # efecto positivo en todo el LOO
  nobs(m1) == 269
)
cat("\n--- Verificacion ---\n")
cat("Tabla generada: OK\n")
cat("Columna (1) replica Tabla 4 (beta3 = 1.79): OK\n")
cat("Leave-one-out siempre positivo [", fmt_num(loo_min, 2), ",",
    fmt_num(loo_max, 2), "]: OK\n")
cat("VERIFICACION PASS\n")

cerrar_log()
