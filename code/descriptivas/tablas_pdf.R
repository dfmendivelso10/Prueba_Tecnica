###############################################################
# Choque petrolero 2022 - tablas_pdf.R
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Exporta las tablas del proyecto a PDF VECTORIAL para insertarlas en LaTeX
#   con \includegraphics (sin pixelarse). Lee el contenido de cada .xlsx oficial
#   y lo reconstruye con flextable en estilo AER (Times New Roman, solo lineas
#   horizontales, paneles encajonados), sin el titulo (lo pone \caption{} en
#   LaTeX) y con las notas al pie. Renderiza a cairo_pdf (vectorial) y recorta
#   con pdfcrop. No reemplaza los .xlsx: es una salida adicional para LaTeX.
#
#   Maneja dos formatos: descriptivas (header simple, con paneles) y de
#   regresion (header + subheader de columnas (1)(2)(3), sin paneles).
#
# Input:  outputs/tables/{tab1,tab2,tab4,tab5,tab6}*.xlsx
# Output: outputs/tables/<mismo nombre>.pdf  (vectorial, recortado, sin titulo)
###############################################################

source(here::here("code/config.R"))
suppressMessages({library(flextable); library(officer)})

TABLAS <- c("tab1_descriptiva", "tab2_paises", "tab4_modelo",
            "tab5_fiscal", "tab6_robustez")

bdr <- fp_border(color = "black", width = 1)

# Convierte un .xlsx de tabla a PDF vectorial sin titulo
xlsx_a_pdf <- function(stem) {
  xlsx <- file.path(PATH$tab, paste0(stem, ".xlsx"))
  pdf  <- file.path(PATH$tab, paste0(stem, ".pdf"))
  stopifnot(file.exists(xlsx))

  raw <- openxlsx::read.xlsx(xlsx, colNames = FALSE, skipEmptyRows = FALSE)
  raw[is.na(raw)] <- ""

  # flextable no interpreta el \n del Excel dentro de una celda: apila el texto
  # superpuesto. Se reemplaza por un espacio para que cada encabezado vaya en linea.
  sin_salto <- function(x) gsub("[\r\n]+", " ", x)

  header <- sin_salto(as.character(raw[2, ]))     # fila 2: encabezado principal
  fila_nota <- max(which(nzchar(raw[, 1])))       # ultima fila no vacia col 1
  nota   <- raw[fila_nota, 1]

  # Subheader: fila 3 con col 1 vacia (tablas de regresion: (1)(2)(3) + VD)
  hay_sub <- nzchar(raw[3, 1]) == FALSE
  fila_ini <- if (hay_sub) 4 else 3
  subhead  <- if (hay_sub) sin_salto(as.character(raw[3, ])) else NULL

  cuerpo <- raw[fila_ini:(fila_nota - 1), , drop = FALSE]
  names(cuerpo) <- paste0("V", seq_len(ncol(cuerpo)))

  es_panel <- grepl("^Panel", cuerpo$V1)
  es_n     <- grepl("^\\s*N ", cuerpo$V1)

  ft <- flextable(cuerpo)
  ft <- set_header_labels(ft, values = setNames(as.list(header), names(cuerpo)))
  if (hay_sub) {                                  # fila de subheader bajo el header
    ft <- add_header_row(ft, values = subhead, top = FALSE)
  }
  ft <- font(ft, fontname = "Times New Roman", part = "all")
  ft <- fontsize(ft, size = 9, part = "all")
  ft <- fontsize(ft, size = 8, part = "footer")
  ft <- align(ft, j = seq(2, ncol(cuerpo)), align = "center", part = "all")
  ft <- align(ft, j = 1, align = "left", part = "all")
  ft <- bold(ft, part = "header")

  ft <- border_remove(ft)
  ft <- hline_top(ft, border = bdr, part = "header")
  ft <- hline_bottom(ft, border = bdr, part = "header")
  ft <- hline_bottom(ft, border = bdr, part = "body")
  for (i in which(es_panel)) {                    # paneles: negrita + linea encima
    ft <- bold(ft, i = i, part = "body")
    ft <- hline(ft, i = i, border = bdr, part = "body")
  }
  for (i in which(es_n)) ft <- hline(ft, i = i, border = bdr, part = "body")

  ft <- add_footer_lines(ft, values = nota)       # notas (sin titulo)
  ft <- italic(ft, part = "footer")
  ft <- autofit(ft)

  gr  <- gen_grob(ft, fit = "auto", just = "center")
  dm  <- dim(gr)
  grDevices::cairo_pdf(pdf, width = dm$width + 0.2, height = dm$height + 0.2)
  grid::grid.draw(gr)
  grDevices::dev.off()

  if (nchar(Sys.which("pdfcrop")) > 0) {
    system2("pdfcrop", args = c(shQuote(pdf), shQuote(pdf)),
            stdout = FALSE, stderr = FALSE)
  }
  stopifnot(file.exists(pdf), file.info(pdf)$size > 5000)
  message("  ", basename(pdf), " (", round(file.info(pdf)$size / 1024, 1), " KB)")
}

message("Tablas a PDF vectorial (sin titulo, para LaTeX):")
for (t in TABLAS) xlsx_a_pdf(t)
message("Listo: ", length(TABLAS), " PDF en ", PATH$tab)
