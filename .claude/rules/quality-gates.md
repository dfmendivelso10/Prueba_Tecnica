---
paths:
  - "scripts/**/*.py"
  - "scripts/**/*.R"
  - "scripts/**/*.do"
  - "outputs/**"
---

# Quality Gates & Scoring Rubrics

- **80/100 = Commit threshold** — good enough to save progress
- **90/100 = Production threshold** — publication-ready / shareable externally
- **95/100 = Excellence** — aspirational

---

## Scripts (.py / .R / .do)

### Critical (auto-fail si falla)
| Issue | Deduction |
|-------|-----------|
| Script falla al ejecutar | -100 |
| N incorrecto vs. CLAUDE.md | -100 |
| Variable incorrecta usada | -30 |
| Ruta hardcodeada absoluta | -20 |
| Config no importado | -20 |
| Umbral o parámetro incorrecto | -20 |

### Major
| Issue | Deduction |
|-------|-----------|
| SE incorrecto para el estimador | -15 |
| Sin manejo de missings documentado | -10 |
| Especificación desvía de config sin justificación | -10 |
| Multicolinealidad conocida ignorada | -10 |
| Pruebas de diagnóstico omitidas (estacionariedad, heterocedasticidad) | -10 |

### Minor
| Issue | Deduction |
|-------|-----------|
| Sin header de script | -3 |
| Convención de naming inconsistente | -2 |
| print() de debug no removido | -1 |
| Líneas > 100 caracteres | -1 |

---

## Output Tables

### Critical
| Issue | Deduction |
|-------|-----------|
| N incorrecto reportado | -100 |
| Notación de significancia incorrecta | -15 |
| Intervalos de confianza faltantes | -10 |

### Major
| Issue | Deduction |
|-------|-----------|
| Formato desvía del estándar del proyecto | -5 |
| Sin notas al pie / fuente | -3 |

---

## Enforcement

- **Score < 80:** Bloquear commit. Listar issues bloqueantes.
- **Score < 90:** Permitir commit con advertencia.
- Usuario puede override con justificación.
