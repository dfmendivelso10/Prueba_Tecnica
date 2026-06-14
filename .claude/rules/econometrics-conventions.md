---
paths:
  - "code/**/*.py"
  - "code/**/*.R"
  - "code/**/*.do"
---

# Convenciones Econométricas

Reglas para análisis macro-fiscal aplicado. Leer junto con CLAUDE.md.

---

## Errores Estándar

| Contexto | SE Requerido |
|---------|-------------|
| OLS cross-section | HC3 (heteroscedasticity-robust) |
| Panel (FE/RE) | Clustered a nivel de país/unidad |
| Series de tiempo | Newey-West (HAC), especificar lags |
| IV / 2SLS | Robust o clustered según datos |
| Bootstrap | Solo para estadísticos no-estándar |

**Nunca reportar SE convencionales (OLS) en datos observacionales.**

---

## Series de Tiempo

- Prueba de estacionariedad ANTES de estimar: ADF, KPSS, PP
- Reportar orden de integración I(d) de cada serie
- Si series no estacionarias: cointegración (Johansen, VECM) o primeras diferencias
- Para VARs: selección de rezagos por AIC/BIC/HQIC; reportar criterio usado
- Para proyecciones locales (LP-OLS): especificar horizonte h, estructura de rezagos
- IRFs: reportar con bandas de confianza bootstrap (1000+ reps)
- Para MIDAS: especificar frecuencia alta/baja y esquema de ponderación

---

## Panel Data

- Hausman test para FE vs RE si hay duda
- Reportar R² within/between/overall según sea relevante
- Para DiD: verificar parallel trends pre-tratamiento (gráfico + test)
- Para event studies: normalizar período base, reportar leads y lags
- Para PSM: balanceo post-matching obligatorio (tabla de medias, SMD)

---

## Diferencias en Diferencias (DiD)

Adaptado del estándar de práctica de Sant'Anna (Callaway & Sant'Anna 2021; Roth,
Sant'Anna, Bilinski & Poe 2023). En este proyecto el diseño es un **2×2 canónico**
(un único período de tratamiento, 2022), no escalonado; las reglas de adopción
escalonada (`att_gt`, never-treated = 0, grupos no-tratados-aún, comparaciones
prohibidas) **no aplican aquí**, pero sí estas:

- **Datos en formato LONG:** una fila por unidad-período. `id` numérico, invariante en
  el tiempo y único dentro de cada período. **Verificar balance del panel antes de
  estimar.**
- **Pre-tendencias es un PRE-TEST, no una prueba.** Es evidencia sobre credibilidad,
  nunca demostración del supuesto. No condicionar el análisis a "pasar" el pre-test ni
  leer el rechazo de un Wald como prueba de sesgo: distinguir **tendencia divergente**
  (sesga) de **volatilidad alrededor de cero** (solo infla la incertidumbre).
- **Forma funcional:** paralelismo en niveles ≠ paralelismo en logs. Declarar la escala
  de la variable dependiente y justificarla; no es invariante.
- **Period base** del event study normalizado (aquí 2021 = 0); reportar leads y lags.
- **Placebo obligatorio:** el efecto debe aparecer en el componente sensible al canal
  (explícito) y NO en el estructural (implícito). Un artefacto contable movería ambos.
- **Leave-one-out / observaciones influyentes:** confirmar que el resultado no lo carga
  una sola unidad (aquí, ningún exportador individual). Nunca quitar un caso "a dedo"
  (selección sobre el resultado); el leave-one-out sistemático es lo correcto.
- **Para DiD escalonado** (si el scope crece): Callaway-Sant'Anna (`did::att_gt`,
  estimador doblemente robusto, bandas uniformes `cband = TRUE`), nunca leer
  pre-tendencias de un event-study TWFE dinámico. Ver `did-conventions.md` del toolkit.

---

## Causalidad e Identificación

- Documentar explícitamente la estrategia de identificación en CLAUDE.md
- Para IV: reportar primera etapa (F > 10), test de instrumentos débiles (Cragg-Donald / Kleibergen-Paap)
- Para RDD: bandwidth selection (IK, CCT), donut hole si hay manipulación
- Para DiD con múltiples períodos: Callaway-Sant'Anna o Roth et al. si hay heterogeneidad en timing
- Placebo tests son obligatorios para cualquier claim causal
- **El paper y el código original del autor son la verdad;** los wrappers traducidos y los
  números impresos son artefactos derivados que hay que verificar contra ellos. Si un
  resultado parece implausible, depurar el wrapper (muestra, pesos, clustering,
  construcción de datos) ANTES de interpretarlo. Ver `inference-robustness.md`.

---

## Machine Learning

- Train/test split documentado
- Cross-validation: especificar k-folds o TSCV (time-series cross-validation) para datos temporales
- Para regularización (LASSO/Ridge): reportar lambda seleccionado y criterio
- Para Random Forest / XGBoost: SHAP values o importancia de variables
- NUNCA usar ML para inferencia causal directamente sin un marco de identificación

---

## Significancia y Reporte

APA: `†p<0.10  *p<0.05  **p<0.01  ***p<0.001`

- Reportar siempre IC 95% junto con el estimador puntual
- Para elasticidades: especificar si son corto o largo plazo
- Efectos estandarizados o en unidades interpretables (no solo coeficientes crudos)
- `p-value` vs. `< .001` — nunca reportar p = 0.000

---

## Reproducibilidad

- Semilla: `np.random.seed(42)` / `set.seed(42)` — UNA VEZ en config
- Dependencias: `requirements.txt` o `renv.lock`
- Datos: nunca modificar `data/raw/`; outputs reproducibles desde raw

---

## Reglas relacionadas

- `inference-robustness.md` — testeo de hipótesis múltiples, grados de libertad del
  investigador, robustez de especificación (leave-one-out, multiverse).
- `code-conventions.md` (§ R) — disciplina numérica y estilo de scripts en R.
- Para DiD escalonado (si el diseño deja de ser un 2×2): Callaway & Sant'Anna (2021),
  paquete `did`, y el hub <https://psantanna.com/did-resources/>.
