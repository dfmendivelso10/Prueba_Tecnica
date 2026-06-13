# Choque petrolero 2022 y subsidios a combustibles fósiles en Latinoamérica

Prueba técnica de economía aplicada. Cuantifica y caracteriza el efecto del choque de
precio internacional del petróleo de 2022 sobre los subsidios a combustibles fósiles en
América Latina, y discute sus implicaciones fiscales para una recomendación de política.

## Pregunta

¿Cómo afectó el choque de precios del petróleo de 2022 a los subsidios a combustibles
fósiles en LATAM, y qué implica para la política fiscal y de subsidios?

## Fuentes de datos

- **IMF Fossil Fuel Subsidies Database** (obligatoria): subsidios explícitos e implícitos.
- **EIA**: precio internacional del petróleo Brent.
- **World Bank (WDI)**: indicadores fiscales (balance, deuda, ingreso público).

Descargadas como referencia pero no integradas al panel: riesgo país EMBIG (BCRP) y
reservas internacionales (World Bank). El detalle de cada fuente, con URL y motivo de
inclusión o exclusión, está en `data/raw/FUENTES.md`.

## Estructura

```
code/            config.R (configuración global)
code/limpieza/   descarga, procesamiento, validación y diccionario
code/descriptivas/  tablas y figuras descriptivas
data/raw/        Fuentes crudas sin modificar (IMF .xlsb, Brent, fiscal)
data/processed/  Paneles limpios (.xlsx)
outputs/         figures/ y tables/
docs/            Pieza de comunicación final
ai_logs/         Prompts y chats de IA usados
```

## Reproducir

Requiere **Python 3** (datos) y **R 4.4+** (análisis). Desde la raíz del proyecto:

```bash
# Dependencias (una vez)
pip install pyxlsb pandas openpyxl requests
Rscript -e 'install.packages(c("here","tidyverse","readxl","writexl","openxlsx","patchwork","fixest","sandwich","lmtest"))'

# 1) Descargar fuentes complementarias (precio Brent y datos fiscales)
python3 code/limpieza/00a_descargar_brent.py
python3 code/limpieza/00b_descargar_fiscal.py
# Opcionales (descargadas pero no integradas al panel; ver data/raw/FUENTES.md)
python3 code/limpieza/00d_descargar_riesgo.py     # riesgo país EMBIG
python3 code/limpieza/00e_descargar_reservas.py   # reservas internacionales

# 2) Procesamiento: IMF + Brent + fiscal -> paneles en data/processed/  (~9 s)
python3 code/limpieza/00c_procesar.py
python3 code/limpieza/01_variables.py
python3 code/limpieza/02_validar.py

# 3) Análisis en R (lee los paneles .xlsx)
Rscript code/03_eda.R         # estadística descriptiva y figuras
Rscript code/04_model.R       # modelo principal del efecto del choque
```

El procesamiento está en Python (pyxlsb) porque leer el `.xlsb` del IMF en R es
prohibitivamente lento; el análisis es 100% R. Todos los outputs se regeneran desde
`data/raw/`.

## Convenciones visuales

Las figuras siguen la paleta del **World Bank Data Visualization Style Guide**
(https://wbg-vis-design.vercel.app/, paquetes `wbpyplot` / `wbplot`), con tipografía
Times New Roman. Las tablas siguen un estándar tipo AER (Times New Roman, solo líneas
horizontales, notas al pie de corrido). Ambos se definen de forma centralizada en
`code/config.R` y se documentan en `docs/convenciones.md`.

## Entregables

1. Datos — `data/`
2. Código de procesamiento — `code/limpieza/`
3. Código de análisis — `code/descriptivas/`, `code/04_model.R`
4. Comunicación de resultados — `docs/`
5. Logs de IA — `ai_logs/`
