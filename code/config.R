###############################################################
# Choque petrolero 2022 y subsidios fósiles en LATAM
# config.R — configuración global del proyecto
# Autor: Daniel Mendivelso
#
# Descripción:
#   Centraliza librerías, rutas, catálogos (países LATAM, combustibles,
#   variables IMF), helpers (logging, guardar tablas/figuras) y temas
#   de figuras (paleta World Bank, tablas estilo AER).
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
# Ambos paneles los produce code/limpieza/00c_procesar.py (extracción + limpieza).

# =============================================================
# 3. Ventana temporal y escenario
# =============================================================
# Datos observados 2015-2023 (2024+ son proyecciones). Choque = 2022.
YEARS_OBS  <- 2015:2023
YEAR_SHOCK <- 2022
YEARS_PRE  <- 2015:2019   # pre-choque "normal" (excluye 2020-21 COVID/recuperación)

# Escenario baseline (sin reforma). El mapeo de columnas crudas de la
# hoja `data` vive en code/limpieza/00c_procesar.py (extracción + limpieza en Python).
SCENARIO_BASELINE <- "U1"

# =============================================================
# 4. Catálogos
# =============================================================
# Países de América Latina y el Caribe (ISO3)
LAC_ISO <- c("ATG","ARG","ABW","BHS","BRB","BLZ","BOL","BRA","CHL","COL","CRI",
             "DMA","DOM","ECU","SLV","GRD","GTM","GUY","HTI","HND","JAM","MEX",
             "NIC","PAN","PRY","PER","PRI","KNA","LCA","VCT","SUR","TTO","URY","VEN")

# Nombres de país en español (ISO3 -> etiqueta), para tablas y figuras.
# El panel trae los nombres del IMF en inglés; se traducen al reportar.
PAIS_ES <- c(
  ATG="Antigua y Barbuda", ARG="Argentina", ABW="Aruba", BHS="Bahamas",
  BRB="Barbados", BLZ="Belice", BOL="Bolivia", BRA="Brasil", CHL="Chile",
  COL="Colombia", CRI="Costa Rica", DMA="Dominica", DOM="República Dominicana",
  ECU="Ecuador", SLV="El Salvador", GRD="Granada", GTM="Guatemala", GUY="Guyana",
  HTI="Haití", HND="Honduras", JAM="Jamaica", MEX="México", NIC="Nicaragua",
  PAN="Panamá", PRY="Paraguay", PER="Perú", PRI="Puerto Rico",
  KNA="San Cristóbal y Nieves", LCA="Santa Lucía",
  VCT="San Vicente y las Granadinas", SUR="Surinam",
  TTO="Trinidad y Tobago", URY="Uruguay", VEN="Venezuela"
)
#' Traducir códigos ISO3 a nombre de país en español
pais_es <- function(iso) unname(PAIS_ES[iso])

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

#' Guardar figura en outputs/figures (PDF cairo, sin título). Si pdfcrop está
#' disponible en el sistema, recorta los márgenes sobrantes del PDF.
save_fig <- function(plot, name, w = FIG_W, h = FIG_H) {
  path <- file.path(PATH$fig, name)
  ggsave(path, plot, width = w, height = h, device = grDevices::cairo_pdf)
  if (nchar(Sys.which("pdfcrop")) > 0) {
    system2("pdfcrop", args = c(shQuote(path), shQuote(path)),
            stdout = FALSE, stderr = FALSE)
  }
  message("Figura guardada: ", path)
}

#' Guardar figura como PNG 300 dpi con la nota al pie compuesta DENTRO de la
#' imagen (estilo PACES). El ggplot se renderiza a un PNG temporal y magick le
#' pega abajo un bloque blanco con la nota (envuelta al ancho). Conserva color.
#'   plot:   ggplot/patchwork (sin caption; la nota va aparte).
#'   name:   archivo de salida (.png) en outputs/figures.
#'   nota:   texto al pie, de corrido. Se le antepone "Notas. " y la fuente.
#'   fuente: texto tras "Fuente: " (se agrega al final de la nota).
#'   w, h:   tamaño del panel de la figura en pulgadas (sin contar la nota).
save_fig_png <- function(plot, name, nota, fuente = NULL,
                         w = 9, h = 7, dpi = 300) {
  stopifnot(requireNamespace("magick", quietly = TRUE))
  path <- file.path(PATH$fig, name)
  tmp  <- tempfile(fileext = ".png")
  ggsave(tmp, plot, width = w, height = h, dpi = dpi,
         device = grDevices::png, type = "cairo")

  img  <- magick::image_read(tmp)
  w_px <- magick::image_info(img)$width

  # Nota al pie de corrido. La fuente se fija a un tamano PROPORCIONAL al chart
  # (~8pt = dpi*0.11 px), no se infla para llenar el ancho: forzar el texto de
  # borde a borde lo agranda mas que los ejes de la figura. El texto se envuelve
  # dentro del ancho disponible. El ancho medio de caracter Times en magick es
  # ~0.46 px por unidad de fuente: con 0.404 el texto se desbordaba por el borde
  # derecho en figuras angostas (dot plot); con 0.52 quedaba demasiado corto,
  # dejando aire a la derecha en figuras anchas (fig1). 0.46 llena casi hasta el
  # borde sin desbordar en ninguno de los dos formatos.
  texto     <- paste0("Notas. ", nota,
                      if (!is.null(fuente)) paste0(" Fuente: ", fuente))
  margen    <- as.integer(round(dpi * 0.12))
  ancho_txt <- w_px - 2 * margen
  fs        <- as.integer(round(dpi * 0.11))      # ~33px = 8pt a 300dpi
  por_linea <- floor(ancho_txt / (fs * 0.46))     # cols que caben a esa fuente
  envuelto  <- paste(strwrap(texto, width = por_linea), collapse = "\n")
  n_lineas  <- length(strsplit(envuelto, "\n")[[1L]])
  h_nota    <- n_lineas * round(fs * 1.45) + margen

  lienzo <- magick::image_blank(w_px, h_nota, color = "white")
  lienzo <- magick::image_annotate(lienzo, envuelto, font = "Times",
             size = fs, color = WB_TEXT,
             location = paste0("+", margen, "+", round(margen / 2)),
             gravity = "northwest")
  final  <- magick::image_append(c(img, lienzo), stack = TRUE)
  magick::image_write(final, path, format = "png", density = dpi)
  message("Figura guardada: ", path, " (PNG ", dpi, " dpi)")
  invisible(path)
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
#'   subheader: opcional, vector de etiquetas de columna (ej. c("","(1)","(2)"))
#'              que va bajo el encabezado; 10pt centrado.
#'   notas:  vector de notas al pie; la 1a va en cursiva (descripción), resto normal.
#'   paneles: opcional, vector con la fila de inicio de cada panel y su etiqueta
#'            como c("Panel A. ..." = 1, "Panel B. ..." = 5) (fila relativa a los datos).
#' Layout: columna A vacía (margen), líneas horizontales, sin verticales ni sombreado.
tabla_aer <- function(df, name, titulo, subheader = NULL, notas = NULL,
                      paneles = NULL, ancho_datos = 14, landscape = FALSE,
                      sheet_name = "Tabla") {
  TNR <- "Times New Roman"

  wb <- createWorkbook()
  addWorksheet(wb, sheet_name, gridLines = FALSE,
               orientation = if (landscape) "landscape" else "portrait")

  off_col <- 2L                       # columna A vacía (margen izquierdo)
  off_row <- 1L                       # fila 1 = título
  ncol_df <- ncol(df)
  cols    <- off_col:(off_col + ncol_df - 1L)

  # Título (fila 1)
  writeData(wb, sheet_name, titulo, startCol = off_col, startRow = off_row)
  addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 13,
           textDecoration = "Bold"), rows = off_row, cols = off_col)

  # Encabezado (fila 2): 11pt bold centrado, borde superior e inferior #888888.
  # Se escribe solo la fila de nombres (los datos van aparte para no chocar con
  # el subheader opcional).
  hdr_row <- off_row + 1L
  writeData(wb, sheet_name, as.data.frame(t(names(df))), startCol = off_col,
            startRow = hdr_row, colNames = FALSE)
  addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 11,
           textDecoration = "Bold", halign = "center", numFmt = "@",
           border = "TopBottom", borderColour = "#888888"),
           rows = hdr_row, cols = cols, gridExpand = TRUE)

  # Subheader opcional con números de columna (1), (2): 10pt centrado
  sub_row <- hdr_row
  if (!is.null(subheader)) {
    sub_row <- hdr_row + 1L
    for (j in seq_along(subheader)) {
      writeData(wb, sheet_name, subheader[j], startCol = off_col + j - 1L,
                startRow = sub_row)
    }
    addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 10,
             halign = "center"), rows = sub_row, cols = cols, gridExpand = TRUE)
  }

  # Cuerpo: nombres de variable (col 1) 10pt bold izquierda; datos 10pt centrado.
  dat_row0 <- sub_row + 1L
  n        <- nrow(df)
  writeData(wb, sheet_name, df, startCol = off_col, startRow = dat_row0,
            colNames = FALSE)
  addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 10,
           textDecoration = "Bold", halign = "left"),
           rows = dat_row0:(dat_row0 + n - 1L), cols = off_col, gridExpand = TRUE)
  if (ncol_df > 1) {
    # Datos centrados, SIN bordes de fila (cuerpo en blanco). numFmt "@" marca
    # las celdas como texto a propósito y suprime el aviso verde de Excel.
    addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 10,
             halign = "center", numFmt = "@"),
             rows = dat_row0:(dat_row0 + n - 1L),
             cols = (off_col + 1L):(off_col + ncol_df - 1L), gridExpand = TRUE)
  }

  # Filas de N (etiqueta empieza con "N "): se escriben como número entero real
  # (numFmt "0") para que no salga el triángulo verde de "texto como número".
  # La fila N queda encajonada: borde superior (la separa de los datos) y el
  # borde inferior lo aporta el cierre del panel (más abajo).
  idx_n <- which(grepl("^\\s*N\\b", as.character(df[[1]])))
  for (k in idx_n) {
    r <- dat_row0 + k - 1L
    # Borde superior de la fila N, a todo el ancho (incluye la etiqueta)
    addStyle(wb, sheet_name, createStyle(border = "Top", borderColour = "#888888"),
             rows = r, cols = cols, gridExpand = TRUE, stack = TRUE)
    vals <- suppressWarnings(as.numeric(df[k, -1]))
    if (any(!is.na(vals))) {
      for (j in which(!is.na(vals)))
        writeData(wb, sheet_name, vals[j], startCol = off_col + j, startRow = r)
      addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 10,
               halign = "center", numFmt = "0", border = "Top",
               borderColour = "#888888"), rows = r,
               cols = (off_col + 1L):(off_col + ncol_df - 1L),
               gridExpand = TRUE, stack = TRUE)
    }
  }

  # Línea de cierre bajo la última fila de datos (medium, igual que el cierre de
  # cada panel, para que los tres cierren con el mismo grosor)
  addStyle(wb, sheet_name, createStyle(border = "Bottom", borderColour = "#888888",
           borderStyle = "medium"),
           rows = dat_row0 + n - 1L, cols = cols, gridExpand = TRUE, stack = TRUE)

  # Etiquetas de panel: se detectan por la 1a columna que empieza con "Panel ".
  # (también admite el parámetro `paneles` por compatibilidad.) La fila de la
  # etiqueta queda ENCAJONADA igual que la fila N: línea medium ARRIBA y ABAJO
  # de la propia etiqueta. Y al cierre del panel anterior, una línea medium bajo
  # su fila N.
  idx_panel <- which(grepl("^Panel ", trimws(as.character(df[[1]]))))
  if (!is.null(paneles)) idx_panel <- as.integer(paneles)
  for (k in idx_panel) {
    r <- dat_row0 + k - 1L
    # Etiqueta del panel en negrita, encajonada: medium arriba y abajo a todo
    # el ancho (la celda de la etiqueta conserva además la negrita).
    addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 10,
             textDecoration = "Bold", border = "TopBottom",
             borderColour = "#888888", borderStyle = "medium"),
             rows = r, cols = off_col, stack = TRUE)
    addStyle(wb, sheet_name, createStyle(border = "TopBottom",
             borderColour = "#888888", borderStyle = "medium"),
             rows = r, cols = (off_col + 1L):(off_col + ncol_df - 1L),
             gridExpand = TRUE, stack = TRUE)
    # Línea inferior medium al cierre del panel anterior: la fila justo encima
    # de la apertura de este panel (es la fila N del panel previo).
    if (k > 1L)
      addStyle(wb, sheet_name, createStyle(border = "Bottom",
               borderColour = "#888888", borderStyle = "medium"),
               rows = r - 1L, cols = cols, gridExpand = TRUE, stack = TRUE)
  }

  # Notas al pie: 9pt, todo de corrido en una sola celda (mergeada sobre el ancho
  # de la tabla) con ajuste de texto. Las partes del vector se unen con espacio.
  if (!is.null(notas)) {
    nr <- dat_row0 + n
    texto <- paste0("Notas. ", paste(notas, collapse = " "))
    writeData(wb, sheet_name, texto, startCol = off_col, startRow = nr)
    mergeCells(wb, sheet_name, cols = cols, rows = nr)
    addStyle(wb, sheet_name, createStyle(fontName = TNR, fontSize = 9,
             valign = "top", wrapText = TRUE), rows = nr, cols = off_col)
    # Alto de la fila de notas ajustado al texto real. El factor 1.7 convierte
    # unidades de ancho de columna a caracteres Times 9pt: la fuente de notas
    # es más pequeña que la por defecto, así que caben ~1.7 caracteres por
    # unidad de ancho. Cada línea ocupa ~12.5 pt (9pt + interlineado) y sin
    # colchón extra, para que no quede aire en blanco bajo las notas.
    ancho_chars <- (22 + ancho_datos * max(ncol_df - 1L, 0)) * 1.7
    n_lineas    <- ceiling(nchar(texto) / ancho_chars)
    setRowHeights(wb, sheet_name, rows = nr, heights = 12.5 * n_lineas)
  }

  # Anchos (col A margen=2; nombre de variable=22; datos=14) y alturas
  setColWidths(wb, sheet_name, cols = 1, widths = 2)
  setColWidths(wb, sheet_name, cols = off_col, widths = 22)
  if (ncol_df > 1) setColWidths(wb, sheet_name,
                                cols = (off_col + 1L):(off_col + ncol_df - 1L),
                                widths = ancho_datos)
  setRowHeights(wb, sheet_name, rows = off_row, heights = 22)
  setRowHeights(wb, sheet_name, rows = hdr_row, heights = 18)

  saveWorkbook(wb, file.path(PATH$tab, name), overwrite = TRUE)
  message("Tabla guardada: ", file.path(PATH$tab, name))
}

#' Anteponer cero a fracciones decimales y fijar decimales (0.357, no .357)
fmt_num <- function(x, dec = 2) {
  x <- round(x, dec)
  x[x == 0] <- 0                       # evita el "-0.00" por redondeo
  ifelse(is.na(x), "", formatC(x, format = "f", digits = dec))
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
