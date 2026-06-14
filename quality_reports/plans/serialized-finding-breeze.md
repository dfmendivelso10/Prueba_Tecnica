# Plan: Pieza fiscal — del efecto del choque a la recomendación de política

**Fecha:** 2026-06-13  **Estado:** DRAFT
**Tarea:** Cerrar el entregable con la tercera pata que pide el reto — implicaciones
fiscales del choque y una recomendación de política pública sobre subsidios fósiles —
cruzando el efecto ya estimado (β₃ ≈ 1.8 pp del PIB) con las variables fiscales del WEO.

---

## Contexto

El bloque cuantitativo ya responde *si* el choque movió los subsidios (Tabla 4 + Fig 4:
en exportadores netos el subsidio explícito subió ~1.8 pp del PIB en 2022, β₃, p≈0.06).
Falta la pregunta de política del reto: *¿qué implica eso para las finanzas públicas y
qué debería hacer la política?*

Las tres variables fiscales del WEO (`deuda_publica`, `balance_fiscal`, `ingreso_publico`,
0% NA) se descargaron justo para esto y **aún no entran en ningún output**. No hace falta
estimar nada nuevo ni crear datos: la pieza es **post-estimación**, toma β₃ y lo contextualiza.
Esto es coherente con el pre-registro, que excluye las fiscales del modelo (serían "bad
controls": consecuencia del subsidio) y las reserva para la discusión.

**Hallazgo de la exploración de datos (2022) que define el diseño:**
- Los 7 exportadores cubren todo el rango de deuda (Guyana 25% → Venezuela 164%): hay
  variación real para una matriz.
- Cuadrante crítico con nombre propio: **Venezuela** (subsidio 18% PIB, deuda 164%) y
  **Bolivia** (8% PIB, deuda 69%, déficit −6.1%) = reforma urgente.
- Importadores con subsidio alto (**Suriname** 8.5%/deuda 112%, **Argentina** 3.6%/deuda 84%)
  están igual o peor que exportadores. ⇒ La presión *de nivel* del subsidio no es exclusiva
  de los exportadores; el choque solo la *agravó diferencialmente* en ellos.
- **Decisión de diseño:** la matriz incluye **todos los países con subsidio relevante**
  (color por grupo importador/exportador), no solo los 7 exportadores. Más honesto y más
  útil para política.

---

## Enfoque (decisiones ya tomadas con el usuario)

1. **Costo del choque en USD — mostrar ambos** (β₃ uniforme y cambio observado):
   - *Atribuible al choque*: `1.79% × gdp_2022` por exportador (efecto medio del modelo,
     uniforme). Se aclara que es el efecto promedio, no país-específico.
   - *Cambio bruto observado*: aumento real del subsidio de cada país 2021→2022 (de los
     datos). Refleja heterogeneidad real; no es causal.
2. **Ejes de la matriz — Subsidio explícito (% PIB) × Deuda pública (% PIB).**
   La deuda (stock) es el ancla de "espacio fiscal" en la literatura FMI/BID, no el déficit
   (flujo, coyuntural). El `balance_fiscal` se usa como insumo del costo (¿cuánto del déficit
   2022 explica el subsidio?) y como columna de respaldo en la tabla — las tres fiscales
   aparecen, pero la matriz se ancla en deuda.

---

## Salidas

- **Figura 5** (`outputs/figures/fig5_matriz_fiscal.png`): scatter subsidio (eje X, % PIB)
  × deuda pública (eje Y, % PIB), un punto por país con subsidio > umbral; color por grupo
  (exportador/importador, `COLORES_EXPOSICION`); **tamaño del punto = costo del choque en USD
  bn** (β₃ uniforme para exportadores; los importadores se grafican sin tamaño-costo o con el
  cambio observado — ver §implementación). Líneas de referencia (mediana de subsidio y de
  deuda) que parten el plano en los cuatro cuadrantes; etiquetas de país. Anotación textual
  de los cuadrantes (urgente / gradual / vigilar / sin presión).
- **Tabla 5** (`outputs/tables/tab5_fiscal.xlsx`, AER): un panel por grupo. Por país:
  subsidio explícito 2022 (% PIB), cambio observado 2021→2022 (pp), costo atribuible al choque
  (β₃, USD bn, solo exportadores), deuda pública (% PIB), balance fiscal (% PIB), cuadrante.
  Fila N por panel.
- **Párrafo de política** (texto al usuario; si se quiere, va luego a `docs/`): lectura de la
  matriz → recomendación diferenciada por cuadrante.

---

## Archivos a crear/modificar

- **CREAR `code/07_pieza_fiscal.R`** — script nuevo, numeración post-modelo (06 es el modelo).
  Estructura calcada de `code/descriptivas/05_fig_impacto.R` (figura) y
  `code/descriptivas/01_tabla_resumen.R` (tabla AER con paneles). Flujo:
  `source(config.R)` → `iniciar_log("07_pieza_fiscal")` → `cargar_panel_anio()` →
  `stopifnot(nrow==306)` → construir `dat` (corte 2022) → figura ggplot + `save_fig_png()` →
  tabla con `tabla_aer()` → verificación → `cerrar_log()`.
- **NO se toca** `data/`, ni el modelo, ni los scripts existentes.

## Helpers a reusar (de `code/config.R`, ya verificados)

- `cargar_panel_anio()` → panel 306×38 (trae las 3 fiscales).
- `save_fig_png(plot, name, nota, fuente, w, h, dpi)` — pega la nota midiendo ancho real.
- `tabla_aer(df, name, titulo, subheader, notas, ancho_datos, landscape)` — detecta
  filas "Panel …" y "N …" y las encajona (top+bottom border) automáticamente.
- `fmt_num(x, dec)`, `pais_es(iso)`, `COLORES_EXPOSICION`, `WB_CAT/WB_TEXT/WB_SUBTLE`,
  `tema_wb_base()`/`tema_wb_ts()`, `YEAR_SHOCK`, `PATH$fig`/`PATH$tab`.
- Constante β₃: definir `BETA3 <- 0.0179` (proporción del PIB) al inicio del script, con
  comentario que remite a `06_modelo.R` (TWFE explícito). No se re-estima.

## Detalle de implementación (puntos a resolver en código)

- **Umbral de inclusión:** reusar `PISO` (subsidio explícito > 0.05% PIB en 2022) como en
  fig3, para no graficar países sin subsidio relevante.
- **Tamaño del punto:** `scale_size_area()`; para exportadores = costo β₃ en USD bn. Para
  importadores el costo β₃ no aplica (β₃ es el efecto diferencial *de exportadores*); se
  grafican con tamaño = cambio observado en USD bn, **o** tamaño fijo y el costo solo en la
  tabla. Decisión: tamaño = **cambio observado 2021→2022 en USD bn** para *ambos* grupos
  (comparable y honesto), y el costo-β₃ como columna exclusiva de exportadores en la tabla.
- **Cuadrantes:** cortar por la **mediana** de subsidio y de deuda de la muestra graficada
  (no umbrales absolutos arbitrarios); anotar las 4 etiquetas de política.
- **Notas (orden AER):** descripción → qué mide cada eje y el tamaño → que β₃ es el efecto
  medio del modelo (no país-específico) y que el cambio observado es bruto (no causal) →
  que las fiscales no entran al modelo (se usan ex-post) → fuente (IMF FFS + IMF WEO).
  Con acentos (magick los renderiza bien).

## Verificación (orchestrator: IMPLEMENT → VERIFY → REVIEW → SCORE)

- [ ] `Rscript code/07_pieza_fiscal.R` corre sin error.
- [ ] `outputs/figures/fig5_matriz_fiscal.png` existe y pesa > 50 KB.
- [ ] `outputs/tables/tab5_fiscal.xlsx` existe.
- [ ] N de países graficados coincide con los que superan `PISO` en 2022; exportadores = 7.
- [ ] Venezuela y Bolivia caen en el cuadrante "deuda alta + subsidio alto"; chequeo numérico.
- [ ] Costo β₃ de un país reproduce `0.0179 × gdp` (p.ej. Colombia ≈ 6.8 USD bn).
- [ ] Revisión: `code-reviewer` (script de figura/tabla, sin estimación nueva).
- [ ] Las 3 fiscales del WEO aparecen en el output (deuda en eje, balance en tabla, ingreso
      al menos en tabla o nota).

## Fuera de alcance

- No se re-estima el modelo ni se añaden controles fiscales al DiD (bad controls).
- No se construye un índice compuesto de espacio fiscal (ponderación arbitraria).
- La matriz es descriptiva/tipológica; no es una segunda estimación causal.
