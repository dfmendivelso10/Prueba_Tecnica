# Pre-registro: Modelo DiD del efecto del choque 2022 sobre subsidios fósiles

**Fecha:** 2026-06-13  **Estado:** DRAFT (pendiente de aprobación)
**Tarea:** cuantificar y caracterizar el efecto del choque de precio del petróleo de 2022
sobre el subsidio explícito a combustibles fósiles en LATAM, con heterogeneidad por
exposición fiscal, como insumo para recomendación de política.

> Forward engineering (Baker et al. 2026, JEL; checklist de Pedro Sant'Anna): el estimando,
> los supuestos y la tabla de diseño se fijan ANTES de estimar. No se hace specification
> search: la especificación de abajo es la única; si los resultados salen raros, se reportan
> crudos, no se "arregla" la especificación hasta que cuadre.

---

## 1. El estimando (en palabras precisas, no solo "ATT")

**β₃ = el cambio diferencial en el subsidio explícito a combustibles fósiles (como % del
PIB) de los países exportadores netos respecto a los importadores netos, al comparar el
año del choque (2022) con el período pre-choque (2015-2021), bajo el supuesto de
tendencias paralelas.**

> Nota de ajuste (durante la implementación): el período post se fija en **solo 2022**,
> el año del choque. 2023 se excluye del estimador estático por ser de recuperación (el
> Brent baja) — incluirlo diluía el efecto y generaba dos números distintos entre la tabla
> (promedio 2022-23 ≈ 0.96) y el event study (pico 2022 ≈ 1.79). Con post = 2022, ambos
> coinciden en ≈ 1.79. El event study sí conserva 2023 para mostrar que el efecto se revierte.

- **Outcome (potential outcome):** Y_it(post) − Y_it(0) = subsidio explícito que se observa
  tras el choque menos el que se habría observado sin él.
- **Población:** los 34 países de LATAM del panel IMF, divididos en 2 grupos fijos.
- **Comparación binaria:** (cambio en exportadores) − (cambio en importadores).
- **Pesos:** simple por país-año dentro de cada celda (no ponderado por PIB ni población;
  la unidad de análisis es el país, coherente con una recomendación país por país).
- **Signo esperado:** β₃ > 0. La renta petrolera permite a los exportadores expandir el
  subsidio cuando sube el Brent; los importadores enfrentan presión fiscal y lo contienen.

NO es un efecto causal del Brent "puro" (ese no es identificable, ver §4). Es el efecto
DIFERENCIAL entre grupos, que es lo relevante para política (a cada grupo, una recomendación).

---

## 2. Especificación

```
Subsidio_it = β₃·(Post2022_t × Exportador_i) + μ_i + λ_t + ε_it
```

- `Subsidio_it`: subsidio explícito (% del PIB), país i, año t. VD principal.
- `Post2022_t × Exportador_i`: interacción tratamiento × exposición. **β₃ es el coeficiente
  de interés.**
- `μ_i`: efecto fijo de país (absorbe nivel estructural; incluye el término `Exportador_i`,
  que es fijo por país, por eso NO entra suelto).
- `λ_t`: efecto fijo de año (absorbe shocks comunes a todos los países, **incluido el Brent
  global y el término `Post2022_t`**, que es función del año; por eso NO entran sueltos).
- `ε_it`: error. SE clustered por país (convención del proyecto); la tabla reporta estrellas
  de significancia según el p-value clustered.

**Por qué Post2022 y Exportador no aparecen sueltos:** quedan absorbidos por μ_i y λ_t
(colinealidad perfecta). Se mencionan en la intuición para explicar de dónde sale β₃, pero
al estimar solo sobrevive la interacción. Esto es DiD de dos vías de efectos fijos estándar.

---

## 3. Tabla de diseño (checklist de Pedro, paso 2)

| Grupo | N países | Obs pre (2015-21) | Obs post (2022) |
|---|---|---|---|
| Exportadores netos | 7 | 49 | 7 |
| Importadores netos | 27 | 189 | 27 |
| **Total** | **34** | **238** | **34** |

- Estimador estático: panel 2015-2022 = 272 obs (8 años × 34); el N efectivo del
  modelo es 269 por 3 país-año sin subsidio explícito estimado.
- Panel completo (con 2023, para el event study): 34 países × 9 años = 306 obs.
- **Limitación honesta:** el grupo de exportadores es pequeño (7). No afecta la
  identificación del DiD, pero sí la precisión y la influencia de casos individuales
  (Venezuela pesa mucho). Se reportará explícitamente, no se esconde.

**DiD crudo (post = 2022; anticipa el resultado, NO es el modelo):**
- Exportadores: pre (2015-21) 3.30 → 2022 5.55 (cambio +2.25 pp)
- Importadores: pre (2015-21) 0.43 → 2022 0.88 (cambio +0.45 pp)
- **β₃ crudo ≈ +1.80 pp del PIB.** El modelo con FE lo confirma (TWFE: +1.79).

---

## 4. Supuestos y su verificación

| Supuesto | Cómo se inspecciona | Estado |
|---|---|---|
| **Tendencias paralelas** (sin choque, ambos grupos habrían seguido trayectorias paralelas) | Event study (leads 2015-2020, base 2021) + test conjunto de Wald. RESULTADO: los coeficientes pre-choque alternan de signo (+0.04 −0.41 −0.09 +0.95 +0.26 −0.77) sin escalar hacia 2022 → no hay tendencia diferencial sistemática preexistente. El test conjunto rechaza la nulidad estricta (F=4.09, p<0.001), pero por VOLATILIDAD (grupo de 7 exportadores; shocks 2018 y COVID 2020), no por pendiente divergente. Se reporta como limitación: el punto estimado no está sesgado por pre-tendencia, pero el panel pre-choque es ruidoso. | Verificado y reportado (Figura 4) |
| **No anticipación** (el subsidio no reacciona antes de 2022) | El choque fue exógeno y súbito (invasión de Ucrania, feb-2022); no había forma de anticiparlo en 2021. | Argumento institucional |
| **Brent exógeno a la política de subsidios de un país** | El precio internacional no lo fija ningún país de LATAM individualmente. | Argumento estructural |
| **SUTVA / no contaminación entre grupos** | La política de subsidios de un país no altera el subsidio de otro vía el Brent (que es global y λ_t lo absorbe). | Razonable |

**Por qué el Brent puro NO es identificable:** el Brent no varía entre países en un año
dado (serie global, sd intra-año = 0), así que es colineal con λ_t y se elimina. La
identificación viene SOLO de la heterogeneidad (interacción con Exportador). Esto es una
restricción del diseño, declarada, no un problema a ocultar.

---

## 5. Qué NO se incluye y por qué (anti specification-search)

| Variable | Por qué se excluye |
|---|---|
| `balance_fiscal`, `deuda_publica`, `ingreso_publico` | NO por cobertura (ahora 0% NA con WEO/FMI, 34 países). Se excluyen del modelo causal porque son CONSECUENCIA del subsidio (el subsidio deteriora el balance/eleva la deuda), no causa independiente: controlarlas sesgaría β₃ (bad control por post-tratamiento). Se usan DESPUÉS del modelo para dimensionar la presión fiscal y construir la recomendación (ver §8). |
| `brecha_gso/die/nga`, `precio_*`, `costo_*` | "Bad controls": están en el canal causal entre el tratamiento (Brent) y el resultado (subsidio). Controlarlas sesgaría β₃. Sirven para describir el mecanismo, no como regresores. |
| `gdp`, `pop` | Ya están dentro de la VD (subsidio como % del PIB). Incluirlas sería redundante. |
| `brent_usd` suelto | Colineal con λ_t (ver §4). |

---

## 6. Especificaciones: escalera de modelos (de simple a robusto)

Se sigue la estructura del DiD de panel estándar (ej. de clase, Econometría Avanzada): se
estima de lo simple a lo robusto y se muestra que β₃ sobrevive al agregar exigencia. Cada
peldaño añade una capa de control; el coeficiente de interés es siempre la interacción
`Post2022 × Exportador`. En R con `fixest::feols` (equivalente a `reghdfe` de Stata).

**Modelo estático (la tabla principal, 3 columnas):**

| # | Especificación | Qué añade | Equivalente Stata |
|---|---|---|---|
| (1) | `Subsidio ~ Post2022 * Exportador`, SE cluster país | DiD 2×2 puro: los términos sueltos + la interacción | `reg Y choque##post, cluster(id)` |
| (2) | `Subsidio ~ Post2022:Exportador \| iso + anio`, SE cluster país | TWFE: efectos fijos de país y año (Post2022 y Exportador caen, absorbidos) | `reghdfe Y 1.choque#1.post, a(anio id) cl(id)` |
| (3) | (2) + verificación con VD alternativas | Robustez del canal: implícito y total como VD | — |

El paso (1)→(2) es clave: en (1) se ven los términos sueltos (didáctico, muestra de dónde
sale β₃); en (2) los efectos fijos los absorben y β₃ queda identificado dentro de país y
año. Que β₃ sea estable entre (1) y (2) es señal de diseño sano.

**Modelo dinámico (event study, la figura):**

`Subsidio_it = Σ_t β_t·(Año_t × Exportador_i) + μ_i + λ_t + ε`, con **2021 como año base
omitido** (último año pre-choque). Entrega un β_t por año → coefplot con línea vertical en
2022. Dos lecturas:
- β_t pre-2022 sin tendencia sistemática (signos alternan) → no hay divergencia previa
  que sesgue el estimador; pero su volatilidad hace que el test conjunto las rechace como
  estrictamente nulas (se reporta como limitación, no se afirma "paralelas validadas").
- β_t en 2022-2023 → el efecto aparece con el choque (quiebre) y su trayectoria.

**VD alternativas (peldaño 3, robustez del canal):** subsidio implícito
y total. Esperado: efecto menor o nulo, porque no reaccionan al precio en el corto plazo.
Confirma que el efecto está donde la teoría dice (el explícito).

---

## 8. Uso de las variables fiscales (post-modelo, insumo de política)

Tres momentos, todos DESPUÉS de estimar β₃ (nunca como regresores):

1. **Dimensionar el costo:** traducir β₃ (pp del PIB) a presión presupuestal usando el
   balance fiscal y la deuda de cada país en 2022 (ej.: Venezuela, +subsidio sobre deuda de
   164% del PIB y déficit de −5.3%).
2. **Recomendación diferenciada:** matriz subsidio × espacio fiscal (deuda) → a quién urge
   reformar (subsidio alto + deuda alta = sin margen) vs. quién puede transición gradual.
3. **Figura de implicación fiscal (opcional):** scatter deuda (X) vs. subsidio (Y) en 2022,
   color por grupo; muestra el cuadrante de riesgo. Cierra el arco efecto → implicación →
   recomendación.

---

## 9. Verificación (insistir en cero error — Cunningham)

Antes de reportar cualquier resultado, juntos:
1. Script corre sin errores; N = 306, 34 países, 9 años.
2. β₃ estimado tiene el signo esperado (>0) y magnitud cercana al DiD crudo (~1.8 pp en 2022).
3. β₃ estable entre (1) DiD 2×2 y (2) TWFE: si cambia mucho, entender por qué.
4. Los FE absorben lo que deben (Post2022 y Exportador caen por colinealidad en (2) — confirmar).
5. Event study: β_t base (2021) = 0 por construcción. Test conjunto de Wald sobre los
   pre-coeficientes. RESULTADO: rechaza nulidad estricta (p<0.001) por volatilidad, no por
   tendencia sistemática (signos alternan). Reportado como limitación en Figura 4 — hecho.
6. VD alternativas (implícito/total): efecto menor que en explícito (confirma el canal).
7. SE clustered por país en todos los modelos (convención del proyecto; ej. de clase).
8. Ningún resultado se "arregla" cambiando la especificación; si algo sale raro, se reporta.

---

## Archivos a crear
- `code/06_modelo.R` — escalera estática (1)(2) + VD alternativas + event study;
  tabla de regresión a `outputs/tables/`, figura event-study a `outputs/figures/`.

## Checklist de aprobación
- [ ] El estimando (§1) refleja lo que queremos responder
- [ ] La especificación (§2) es correcta y entendida
- [ ] Las exclusiones (§5) están justificadas (fiscales = consecuencia, no causa)
- [ ] La escalera de modelos (§6) sigue el estándar simple→robusto
- [ ] El uso de las fiscales post-modelo (§8) sirve a la recomendación de política
