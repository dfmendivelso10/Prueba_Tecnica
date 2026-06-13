# Convenciones de tablas y figuras

Convenciones visuales del proyecto. Se aplican a **toda** tabla y figura.
Implementadas de forma centralizada en `code/config.R` (helpers `tabla_aer()`,
`tema_wb_*()`, `caption_wb()`, `save_fig()`).

## Tablas (estilo AER)

- Exportan a Excel (`.xlsx`) con `openxlsx`.
- Orientación vertical; máximo 9 columnas incluyendo la de variable.
- Numeración consecutiva (Tabla 1, Tabla 2, ...).
- Solo líneas horizontales y espacio en blanco; sin líneas verticales ni sombreado.
- Sin abreviar los encabezados de columna.
- Paneles temáticos (Panel A, Panel B, ...).
- Cero antes de los decimales (0.357, no .357).

### Tipografía
- Times New Roman en toda la tabla.
- Título 13 pt negrita; encabezados 11 pt negrita centrados; subencabezado de números
  de columna (1), (2), ... 10 pt centrado; datos 10 pt centrados; nombres de variable
  10 pt negrita a la izquierda; notas 9 pt.

### Disposición (Excel)
- Columna A vacía como margen (ancho 2).
- Columna de variable ancho 22; columnas de datos ancho 14.
- Bordes: encabezados #888888, cuerpo #CCCCCC; siempre horizontales.

### Notas al pie
- **Van de corrido en un solo párrafo** (una celda combinada del ancho de la tabla, con
  ajuste de texto), prefijado con `Notas.`. No una fila por punto.
- Claves de nota con letras minúsculas (a, b, c) para entradas específicas.
- Orden de las frases: descripción del contenido → formato de los valores (ej. media (DE))
  → definición de los grupos → restricciones de muestra → fuente (siempre al final).
- **Sin significancia, sin estrellas, sin tests:** el reto no evalúa significancia ni
  robustez, por lo que las tablas reportan solo estimadores puntuales.

## Figuras (paleta World Bank)

- Estilo basado en el World Bank Data Visualization Style Guide
  (https://wbg-vis-design.vercel.app/, paquetes `wbpyplot` / `wbplot`).
- Tipografía Times New Roman (vía `cairo_pdf`); fondo blanco; sin título ni subtítulo.
- Tamaño 7.5 × 5.2 pulgadas (forest plots 8.5 × 5.5).
- Paleta categórica oficial del WB; texto #111111, ejes #666666, grilla #EBEEF4.
- Año del choque (2022) sombreado en las series de tiempo.
- Caption únicamente con "Notas:" y "Fuente:".
