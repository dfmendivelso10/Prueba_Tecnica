---
paths:
  - "*.tex"
  - "quality_reports/**"
---

# Protocolo de Proofreading (presentación de resultados)

Antes de un commit del `.tex` o de entregar la presentación, conviene pasar el agente
`proofreader` sobre el deck. Revisa: gramática/ortografía, typos, overflow (overfull hbox),
consistencia terminológica (sigla **ALC** uniforme, notación, términos), **consistencia
numérica** (la misma cifra idéntica en todos los slides/notas/tablas), **huella de IA** (frases
prohibidas de `resultados-formato.md`) y coherencia econométrica de la redacción.

## Flujo de tres fases: PROPONER → APROBAR → APLICAR

**El agente NUNCA aplica cambios directamente. Primero propone; las correcciones se aplican
tras aprobación.**

### Fase 1 — Revisar y proponer (SIN editar)

Lanzar el agente `proofreader` sobre el `.tex`. El agente:

1. Lee el archivo completo.
2. Identifica todos los problemas (gramática, typo, overflow, consistencia, numérica, IA,
   econométrica).
3. Cuando puede, **coteja cada cifra contra la fuente** (`logs/`, `data/processed/`); no
   recalcula el modelo, solo verifica.
4. Produce un **reporte** con: ubicación (línea o título del slide), texto actual, corrección
   propuesta, categoría y severidad.
5. Guarda el reporte en `quality_reports/[archivo]_proofread.md`.
6. **No modifica ninguna fuente.**

### Fase 2 — Revisar y aprobar

El usuario revisa las correcciones propuestas: acepta todo, acepta selectivamente, o pide
cambios. **Solo tras aprobación explícita** se pasa a aplicar.

### Fase 3 — Aplicar

Aplicar únicamente las correcciones aprobadas con la herramienta Edit; `replace_all: true`
para los problemas con varias ocurrencias (ej. una sigla mal escrita repetida). Verificar cada
edición y recompilar (`/compile-latex`) para confirmar que el deck sigue limpio.

## Cuándo correrlo

1. Antes de un commit que toque el `.tex`.
2. Antes de la entrega final (barrido completo).
3. Después de ediciones masivas (buscar-y-reemplazar, reestructurar slides).

## Reglas relacionadas
- `resultados-formato.md` (rule global) — notación estadística y frases prohibidas (huella IA).
- `beamer-slide-conventions.md` — convenciones del deck.
- Skills: `proofread` (corre este protocolo), `compile-latex` (verifica la compilación).
