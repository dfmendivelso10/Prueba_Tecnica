###############################################################
# Choque petrolero 2022 y subsidios fósiles en LATAM
# config.R — configuración global del proyecto
# Autor: Daniel Mendivelso
#
# Descripción:
#   Centraliza librerías, rutas, catálogos (países LATAM, combustibles,
#   variables IMF), helpers (logging, guardar tablas/figuras) y temas
#   de figuras estilo AER.
#
# Uso: source(here::here("code/config.R")) al inicio de cada script.
# Input/Output: ninguno (solo define objetos en el environment).
###############################################################

# =============================================================
# 1. Librerías base
# =============================================================
suppressPackageStartupMessages({
  library(here)       # rutas relativas al proyecto
  library(readxl)     # leer Excel
  library(writexl)    # escribir Excel (ligero)
  library(openxlsx)   # escribir Excel con formato
  library(dplyr)      # manipulación
  library(tidyr)      # reshape
  library(purrr)      # programación funcional
  library(stringr)    # strings
  library(ggplot2)    # gráficos
  library(patchwork)  # combinar gráficos
})

# =============================================================
# 2. Rutas del proyecto
# =============================================================
PROJ_DIR <- here()

PATH <- list(
  raw       = here("data", "raw"),
  processed = here("data", "processed"),
  fig       = here("outputs", "figures"),
  tab       = here("outputs", "tables"),
  docs      = here("docs"),
  logs      = here("logs")
)
for (p in PATH) dir.create(p, showWarnings = FALSE, recursive = TRUE)

# Archivos principales
FILE_PANEL_ANIO <- file.path(PATH$processed, "panel_pais_anio.xlsx")
FILE_PANEL_FUEL <- file.path(PATH$processed, "panel_pais_anio_combustible.xlsx")
# Ambos paneles los produce code/00c_procesar.py (extracción + limpieza).

# =============================================================
# 3. Ventana temporal y escenario
# =============================================================
# Datos observados 2015-2023 (2024+ son proyecciones). Choque = 2022.
YEARS_OBS  <- 2015:2023
YEAR_SHOCK <- 2022
YEARS_PRE  <- 2015:2019   # pre-choque "normal" (excluye 2020-21 COVID/recuperación)

# Escenario baseline (sin reforma). El mapeo de columnas crudas de la
# hoja `data` vive en code/00c_procesar.py (extracción + limpieza en Python).
SCENARIO_BASELINE <- "U1"

# =============================================================
# 4. Catálogos
# =============================================================
# Países de América Latina y el Caribe (ISO3)
LAC_ISO <- c("ATG","ARG","ABW","BHS","BRB","BLZ","BOL","BRA","CHL","COL","CRI",
             "DMA","DOM","ECU","SLV","GRD","GTM","GUY","HTI","HND","JAM","MEX",
             "NIC","PAN","PRY","PER","PRI","KNA","LCA","VCT","SUR","TTO","URY","VEN")

# Combustibles (código IMF -> etiqueta)
FUELS <- tribble(
  ~code,  ~label,
  "gso",  "Gasolina",
  "die",  "Diésel",
  "lpg",  "GLP",
  "ker",  "Keroseno",
  "oop",  "Otros derivados de petróleo",
  "oil",  "Petróleo (agregado)",
  "nga",  "Gas natural",
  "coa",  "Carbón",
  "ecy",  "Electricidad"
)

# Variables de subsidio agregadas (MTCode -> nombre corto)
MT_AGG <- c(
  expl_total  = "mit.expsub.con.all.all.1",    # explícito total (USD bn)
  impl_total  = "mit.impsub.con.all.all.1",    # implícito total (USD bn)
  tot_total   = "mit.allsub.con.all.all.1",    # total expl+impl (USD bn)
  expl_pctgdp = "mit.expsubgdp.con.all.all.1", # explícito % PIB (fracción)
  impl_pctgdp = "mit.impsubgdp.con.all.all.1", # implícito % PIB (fracción)
  tot_pctgdp  = "mit.allsubgdp.con.all.all.1"  # total % PIB (fracción)
)
# Contexto macro/fiscal (MTCode -> nombre corto)
MT_MACRO <- c(
  gdp      = "mit.gdp.pre.lvl.1",   # PIB baseline
  pop      = "mit.pop.mn",          # población (millones)
  rev_usd  = "mit.rev.new.usd.1",   # ingreso fiscal neto subsidios (USD bn)
  eff_cost = "mit.wel.eco.dwl.usd"  # costo de eficiencia (USD bn)
)

# NOTA: las variables *pctgdp vienen como FRACCIÓN (0.093 = 9.3% PIB).
# Multiplicar por 100 al reportar en porcentaje.

# =============================================================
# 5. Temas de figuras (estilo AER — Times New Roman)
# =============================================================
# Paleta energía/fiscal (azul petróleo + ámbar + grises)
PALETA <- c(
  "primario"   = "#1F4E5F",   # azul petróleo oscuro
  "secundario" = "#3E7C8C",   # azul medio
  "acento"     = "#D98E04",   # ámbar (choque/explícito)
  "alerta"     = "#A63A2B",   # rojo terracota
  "claro"      = "#EEF2F4",   # fondo suave
  "neutro"     = "#3A3A3A"    # texto/ejes
)

# Explícito vs implícito (el explícito es el que reacciona al choque)
COLORES_COMPONENTE <- c("Explícito" = PALETA[["acento"]],
                        "Implícito" = PALETA[["secundario"]])

# Importadores vs exportadores netos de petróleo
COLORES_EXPOSICION <- c("Importador neto" = PALETA[["primario"]],
                        "Exportador neto" = PALETA[["alerta"]])

# Tema base AER: Times New Roman, sin grilla menor, sin borde de panel
tema_aer_base <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      text             = element_text(family = "Times New Roman"),
      plot.title       = element_blank(),
      strip.background = element_blank(),
      strip.text       = element_text(face = "bold"),
      legend.position  = "bottom",
      legend.title     = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border     = element_blank(),
      plot.caption     = element_text(size = 8, hjust = 0, colour = "grey20",
                                      family = "Times New Roman",
                                      margin = margin(t = 10))
    )
}

# Variante series de tiempo: eje X visible, grilla Y de guía
tema_aer_ts <- function(base_size = 11) {
  tema_aer_base(base_size) +
    theme(
      axis.line.x        = element_line(colour = "black", linewidth = 0.3),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(colour = "grey92", linewidth = 0.4)
    )
}

# Variante ranking/barras horizontales: grilla X de guía
tema_aer_barras <- function(base_size = 11) {
  tema_aer_base(base_size) +
    theme(
      axis.title.y       = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.3),
      axis.line.x        = element_line(colour = "black", linewidth = 0.3)
    )
}

FIG_W <- 9; FIG_H <- 6   # pulgadas

#' Guardar figura en outputs/figures (PDF cairo, sin título)
save_fig <- function(plot, name, w = FIG_W, h = FIG_H) {
  ggsave(file.path(PATH$fig, name), plot, width = w, height = h,
         device = grDevices::cairo_pdf)
  message("Figura guardada: ", file.path(PATH$fig, name))
}

# =============================================================
# 6. Helpers de datos / tablas / logging
# =============================================================
options(openxlsx.dateFormat = "yyyy-mm-dd")
set.seed(42)

#' Cargar el panel país×año
cargar_panel_anio <- function() read_excel(FILE_PANEL_ANIO)

#' Cargar el panel país×año×combustible
cargar_panel_fuel <- function() read_excel(FILE_PANEL_FUEL)

#' Guardar tabla en Excel con formato de encabezado
guardar_tabla <- function(df, name, sheet_name = "Datos") {
  path <- file.path(PATH$tab, name)
  wb <- createWorkbook()
  addWorksheet(wb, sheet_name)
  writeData(wb, sheet_name, df)
  headerStyle <- createStyle(
    fontSize = 11, fontName = "Times New Roman", halign = "center",
    border = "Bottom", borderColour = "#888888", textDecoration = "Bold"
  )
  addStyle(wb, sheet_name, headerStyle, rows = 1, cols = 1:ncol(df), gridExpand = TRUE)
  setColWidths(wb, sheet_name, cols = 1:ncol(df), widths = "auto")
  saveWorkbook(wb, path, overwrite = TRUE)
  message("Tabla guardada: ", path)
}

#' Iniciar log de script (sink a logs/)
iniciar_log <- function(script_name) {
  log_file <- file.path(PATH$logs, paste0("log_", script_name, "_", Sys.Date(), ".txt"))
  sink(log_file, split = TRUE)
  cat("========================================\n")
  cat("Script:", script_name, "\n")
  cat("Inicio:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("========================================\n\n")
  invisible(log_file)
}

#' Cerrar log de script
cerrar_log <- function() {
  cat("\n========================================\n")
  cat("Fin:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("========================================\n")
  sink()
}

# =============================================================
# 7. Confirmación
# =============================================================
message("config.R cargado — choque petrolero 2022 × subsidios fósiles LATAM")
message("Proyecto: ", PROJ_DIR)
