# Validación de la extracción de datos IMF

**7 de 7 pruebas superadas.**

Verifica la estructura de los paneles, la coherencia de las variables derivadas y que el subsidio por combustible sea consistente entre el panel anual y el panel por combustible.

| Prueba | Resultado |
|---|---|
| Años 2015-2023 (sin proyecciones) | PASS |
| 34 países de LATAM | PASS |
| Sin duplicados país-año | PASS |
| Sin duplicados país-año-combustible | PASS |
| Brecha de gasolina = precio - costo | PASS |
| Explícito de petróleo coincide entre paneles | PASS |
| Explícito de gas natural coincide entre paneles | PASS |

## Nota
El agregado `tot_total` del IMF no equivale exactamente a `expl_total + impl_total` (difieren en algunos países), porque el IMF calcula sus totales `all.all` de forma independiente. Se conserva el agregado oficial del IMF.
