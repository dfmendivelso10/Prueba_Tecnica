# Choque petrolero 2022 y subsidios a combustibles fósiles en LATAM — Instrucciones para Claude

## Proyecto
Prueba técnica de economía aplicada. **Pregunta:** cuantificar y caracterizar el
efecto del choque de precio internacional del petróleo de 2022 sobre los subsidios a
los combustibles fósiles en Latinoamérica, y discutir sus implicaciones fiscales para
generar una recomendación de política pública sobre subsidios fósiles.

- **Candidato:** Daniel (df.mendivelso10@gmail.com)
- **Fecha límite de entrega:** [VERIFICAR]
- **Entregar a:** sa.sanchezm@uniandes.edu.co, ja.guerrae@uniandes.edu.co
- **Período de análisis:** ~2010–2023 (centrado en el choque 2022) [AJUSTAR según datos]
- **Cobertura:** países de América Latina y el Caribe

### Naturaleza de la evaluación
No se evalúa significancia ni robustez estadística, sino: intuición y entendimiento
del problema y del método, justificación de las variables, forma de abordar el problema
y los recursos usados. **Libertad metodológica** con un flujo internamente consistente.

---

## Fuentes de Datos

| Fuente | Uso | Estado |
|--------|-----|--------|
| **IMF Fossil Fuel Subsidies Database** (OBLIGATORIA) | Variable dependiente: subsidios explícitos + implícitos | [PENDIENTE descarga] |
| IMF WEO | PIB, fiscal, deflactores, precios | [opcional] |
| World Bank (WDI) | PIB per cápita, población, consumo energético | [opcional] |
| Precio internacional del petróleo (Brent/WTI, IMF PCPS / EIA) | Variable de tratamiento / choque | [opcional] |
| GTED, OECD | Gasto tributario, subsidios complementarios | [opcional] |

- **IMF Fossil Fuel Subsidies** distingue subsidios **explícitos** (precio bajo costo de
  suministro) e **implícitos** (externalidades no internalizadas + IVA no aplicado).
  Para el choque de precios, el componente **explícito** es el más sensible y relevante.

---

## Reglas de Trabajo

### Datos
- **NUNCA** modificar archivos en `data/raw/` sin confirmación explícita.
- Datos limpios van en `data/processed/`.
- Todo output reproducible desde `data/raw/`.
- Documentar fuente, fecha de descarga y URL de cada archivo raw (en README o data dictionary).

### Código
- R: `source(here::here("code/config.R"))` al inicio de cada script.
- `config.R` define: rutas, semilla (`set.seed(42)`), paleta de figuras, parámetros de modelos.
- Scripts numerados en `code/` (ver Estructura). Tablas → `outputs/tables/`, figuras → `outputs/figures/`.

### Verificación
Antes de reportar "completado":
1. Script ejecuta sin errores (`Rscript code/XX_*.R`).
2. Output existe en la ruta esperada.
3. N de observaciones / países coincide con lo esperado.

### Archivos
- **NO borrar/mover** archivos sin confirmar. Preferir editar existentes sobre crear nuevos.

### Logs de IA (entregable 5)
- Guardar prompts/chats/decisiones relevantes en `ai_logs/`.

---

## Estructura

```
code/
├── config.R                 # rutas, semilla, parámetros, paleta de figuras (R)
├── 00a_descargar_brent.py   # descarga precio Brent (EIA vía datahub)
├── 00b_descargar_fiscal.py  # descarga indicadores fiscales (World Bank)
├── 00d_descargar_riesgo.py  # descarga riesgo país EMBIG (BCRP, 8 países)
├── 00c_procesar.py          # extracción IMF + Brent + fiscal + riesgo -> paneles
├── 01_variables.py          # variables derivadas (per cápita, brechas)
├── 02_validar.py            # validación de la extracción
├── 03_eda.R                 # estadística descriptiva, EDA, series de tiempo
├── 04_model.R               # modelo principal (efecto del choque)
└── explorations/            # análisis exploratorio temporal (no publicable)

data/
├── raw/                  # fuentes crudas (NO tocar) — IMF .xlsb, WEO, WB, precio Brent
└── processed/            # paneles limpios .xlsx listos para análisis

outputs/
├── tables/               # tablas finales
└── figures/              # figuras (PDF)

docs/                     # pieza de comunicación final (entregable 4)
ai_logs/                  # prompts/chats de IA (entregable 5)
quality_reports/          # planes, logs de sesión, auditorías
```

---

## Estrategia de Identificación (borrador — ajustar al elegir método)

El choque de 2022 es un evento global plausiblemente exógeno a la política de subsidios
de cualquier país individual de LATAM (precio internacional). Candidatos:

- **Event study / serie de tiempo:** trayectoria de subsidios antes/después de 2022;
  el precio del petróleo como variable de choque.
- **Panel FE (país + año):** subsidios ~ precio petróleo × exposición, con efectos fijos.
- **Descomposición:** separar variación de subsidios por precio vs. cantidad vs. política.

Heterogeneidad esperada: **importadores netos** (sube costo de subsidiar, presión fiscal)
vs. **exportadores netos** (ingreso petrolero amortigua / subsidios como redistribución de renta).
Documentar la estrategia elegida aquí antes de estimar.

---

## Convenciones Estadísticas
- **Panel:** SE clustered a nivel de país.
- **Series de tiempo:** Newey-West HAC, especificar lags.
- **Significancia:** †p<0.10  *p<0.05  **p<0.01  ***p<0.001 (reportar IC 95%).
- **Semilla:** `set.seed(42)` una sola vez en `config.R`.

## Convenciones de Figuras
- R: `ggsave(width=9, height=6, device=cairo_pdf)`, sin título en la figura.
- Paleta colorblind-safe (viridis) o escala de grises.
- Caption: solo "Notas:" + "Fuente:".
- Sombrear 2022 (choque) cuando sea serie temporal.

---

## Hallazgos Clave
[Llenar conforme avanza el proyecto]
