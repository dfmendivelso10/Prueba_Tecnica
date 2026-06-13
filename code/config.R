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
# 5. Temas de figuras (paleta World Bank, tipografía Times New Roman)
# =============================================================
# Estilo visual basado en el World Bank Data Visualization Style Guide.
#   Guía:      https://wbg-vis-design.vercel.app/  (sección Colors)
#   Paletas:   paquetes oficiales wbpyplot (Python) / wbplot (R)
#              https://worldbank.github.io/wbpyplot/
#   Consultado: 2026-06-13.
# Se adopta la paleta del WB; la tipografía se mantiene en Times New Roman
# (convención del proyecto) en lugar de Open Sans del WB.

# Paleta categórica oficial (9 colores)
WB_CAT <- c("#34A7F2", "#FF9800", "#664AB6", "#4EC2C0", "#F3578E",
            "#081079", "#0C7C68", "#AA0000", "#DDDA21")
# Secuencial monocromática (para énfasis del choque)
WB_SEQ_YELLOW <- c("#FDF7DB", "#ECB63A", "#BE792B", "#8D4117", "#5C0000")
WB_SEQ_BLUE   <- c("#E3F6FD", "#75CCEC", "#089BD4", "#0169A1", "#023B6F")
# Elementos de gráfico (texto, ejes, grilla, fondo)
WB_TEXT   <- "#111111"   # texto principal
WB_SUBTLE <- "#666666"   # ejes / texto secundario
WB_GRID   <- "#EBEEF4"   # líneas de guía (Grey100)
WB_SHADE  <- "#EBEEF4"   # sombreado del año del choque

# Explícito vs implícito (el explícito es el que reacciona al choque -> naranja)
COLORES_COMPONENTE <- c("Explícito" = WB_CAT[2], "Implícito" = WB_CAT[1])

# Importadores vs exportadores netos de petróleo (azul vs naranja, default WB)
COLORES_EXPOSICION <- c("Importador neto" = WB_CAT[1],
                        "Exportador neto" = WB_CAT[2])

# Tema base World Bank: fondo blanco, Times New Roman, sin grilla menor ni borde
tema_wb_base <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      text             = element_text(family = "Times New Roman", colour = WB_TEXT),
      plot.title       = element_blank(),
      axis.text        = element_text(colour = WB_SUBTLE),
      axis.title       = element_text(colour = WB_TEXT),
      strip.background = element_blank(),
      strip.text       = element_text(face = "bold"),
      legend.position  = "bottom",
      legend.title     = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border     = element_blank(),
      plot.caption     = element_text(size = 8, hjust = 0, colour = WB_SUBTLE,
                                      family = "Times New Roman",
                                      margin = margin(t = 10))
    )
}

# Variante series de tiempo: eje X visible, grilla Y de guía
tema_wb_ts <- function(base_size = 11) {
  tema_wb_base(base_size) +
    theme(
      axis.line.x        = element_line(colour = WB_SUBTLE, linewidth = 0.3),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(colour = WB_GRID, linewidth = 0.5)
    )
}

# Variante ranking/barras horizontales: grilla X de guía
tema_wb_barras <- function(base_size = 11) {
  tema_wb_base(base_size) +
    theme(
      axis.title.y       = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = WB_GRID, linewidth = 0.5),
      axis.line.x        = element_line(colour = WB_SUBTLE, linewidth = 0.3)
    )
}

# Aliases compatibles (los scripts pueden usar el nombre AER previo)
tema_aer_base <- tema_wb_base; tema_aer_ts <- tema_wb_ts; tema_aer_barras <- tema_wb_barras

FIG_W <- 7.5; FIG_H <- 5.2          # estándar (pulgadas)
FIG_W_FOREST <- 8.5; FIG_H_FOREST <- 5.5

#' Caption estándar: solo "Notas:" + "Fuente:"
#' @param notas texto tras "Notas:"; fuente texto tras "Fuente:"
caption_wb <- function(notas = NULL, fuente = NULL) {
  partes <- c(if (!is.null(notas))  paste0("Notas: ", notas),
              if (!is.null(fuente)) paste0("Fuente: ", fuente))
  paste(partes, collapse = "\n")
}

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

#' Tabla con formato AER (ver .claude/rules/table-standards.md)
#'   df:     data.frame; la 1a columna es el nombre de variable (texto, izquierda).
#'   titulo: título de la tabla (13pt bold).
#'   notas:  vector de notas al pie; la 1a va en cursiva (descripción), resto normal.
#'   paneles: opcional, vector con la fila de inicio de cada panel y su etiqueta
#'            como c("Panel A. ..." = 1, "Panel B. ..." = 5) (fila relativa a los datos).
#' Layout: columna A vacía (margen), líneas horizontales, sin verticales ni sombreado.
tabla_aer <- function(df, name, titulo, notas = NULL, paneles = NULL,
                      sheet_name = "Tabla") {
  TNR <- "Times New Roman"
  wb <- createWorkbook()
  addWorksheet(wb, sheet_name, gridLines = FALSE)

  off_col <- 2L                       # columna A vacía (margen izquierdo)
  off_row <- 1L                       # fila 1 = título
  ncol_df <- ncol(df)
  cols    <- off_col:(off_col + ncol_df - 1L)

  # Título (fila 1)
  writeData(wb, sheet_name, titulo, startCol = off_col, startRow = off_row)
  addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 13,
           textDecoration = "Bold"), rows = off_row, cols = off_col)

  # Encabezado (fila 2): 11pt bold centrado, borde superior e inferior #888888
  hdr_row <- off_row + 1L
  writeData(wb, sheet_name, df, startCol = off_col, startRow = hdr_row,
            headerStyle = createStyle(fontName = TNR, fontSize = 11,
              textDecoration = "Bold", halign = "center",
              border = "TopBottom", borderColour = "#888888"))

  # Cuerpo: nombres de variable (col 1) 10pt bold izquierda; datos 10pt centrado.
  dat_row0 <- hdr_row + 1L
  n        <- nrow(df)
  addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 10,
           textDecoration = "Bold", halign = "left"),
           rows = dat_row0:(dat_row0 + n - 1L), cols = off_col, gridExpand = TRUE)
  if (ncol_df > 1) {
    addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 10,
             halign = "center", border = "Bottom", borderColour = "#CCCCCC"),
             rows = dat_row0:(dat_row0 + n - 1L),
             cols = (off_col + 1L):(off_col + ncol_df - 1L), gridExpand = TRUE)
  }

  # Línea de cierre bajo la última fila de datos
  addStyle(wb, sheet_name, createStyle(border = "Bottom", borderColour = "#888888"),
           rows = dat_row0 + n - 1L, cols = cols, gridExpand = TRUE, stack = TRUE)

  # Etiquetas de panel (negrita, sobre la fila indicada)
  if (!is.null(paneles)) {
    for (i in seq_along(paneles)) {
      r <- dat_row0 + as.integer(paneles[i]) - 1L
      writeData(wb, sheet_name, names(paneles)[i], startCol = off_col, startRow = r)
      addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 10,
               textDecoration = "Bold"), rows = r, cols = off_col, stack = TRUE)
    }
  }

  # Notas al pie: 9pt, primera en cursiva (descripción), resto normal
  if (!is.null(notas)) {
    nr <- dat_row0 + n
    for (i in seq_along(notas)) {
      writeData(wb, sheet_name, notas[i], startCol = off_col, startRow = nr + i - 1L)
      addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 9,
               textDecoration = if (i == 1) "Italic" else NULL),
               rows = nr + i - 1L, cols = off_col)
    }
  }

  # Anchos (col A margen=2; nombre de variable=22; datos=14) y alturas
  setColWidths(wb, sheet_name, cols = 1, widths = 2)
  setColWidths(wb, sheet_name, cols = off_col, widths = 22)
  if (ncol_df > 1) setColWidths(wb, sheet_name,
                                cols = (off_col + 1L):(off_col + ncol_df - 1L), widths = 14)
  setRowHeights(wb, sheet_name, rows = off_row, heights = 22)
  setRowHeights(wb, sheet_name, rows = hdr_row, heights = 18)

  saveWorkbook(wb, file.path(PATH$tab, name), overwrite = TRUE)
  message("Tabla guardada: ", file.path(PATH$tab, name))
}

#' Anteponer cero a fracciones decimales y fijar decimales (0.357, no .357)
fmt_num <- function(x, dec = 2) {
  ifelse(is.na(x), "", formatC(round(x, dec), format = "f", digits = dec))
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
