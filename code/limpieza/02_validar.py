# Validación de la extracción de datos del IMF
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Comprueba que los paneles procesados son correctos antes de analizar:
#   estructura (años, países, duplicados), coherencia de las variables
#   derivadas y consistencia entre el panel anual y el de combustibles.
#   Escribe un reporte en markdown.
#
# Input:  data/processed/panel_pais_anio.xlsx
#         data/processed/panel_pais_anio_combustible.xlsx
# Output: quality_reports/validacion.md

import os
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROC = os.path.join(ROOT, "data", "processed")
OUT = os.path.join(ROOT, "quality_reports", "validacion.md")

pa = pd.read_excel(os.path.join(PROC, "panel_pais_anio.xlsx"))
pf = pd.read_excel(os.path.join(PROC, "panel_pais_anio_combustible.xlsx"))

# El subsidio por combustible debe coincidir entre el panel anual y el de combustible
def cruza(col, combustible):
    a = pa[["iso", "anio", col]]
    b = pf.query("combustible == @combustible")[["iso", "anio", "explicito"]]
    m = a.merge(b, on=["iso", "anio"])
    return (m[col] - m.explicito).abs().max()

pruebas = {
    "Años 2015-2023 (sin proyecciones)": set(pa.anio) == set(range(2015, 2024)),
    "34 países de LATAM": pa.iso.nunique() == 34,
    "Sin duplicados país-año": not pa.duplicated(["iso", "anio"]).any(),
    "Sin duplicados país-año-combustible": not pf.duplicated(["iso", "anio", "combustible"]).any(),
    "Brecha de gasolina = precio - costo": (pa.brecha_gso - (pa.precio_gso - pa.costo_gso)).abs().max() < 1e-9,
    "Explícito de petróleo coincide entre paneles": cruza("expl_oil", "Petróleo") < 1e-9,
    "Explícito de gas natural coincide entre paneles": cruza("expl_nga", "Gas natural") < 1e-9,
}

# Reporte
ok = sum(pruebas.values())
filas = [f"| {nombre} | {'PASS' if v else 'FALLA'} |" for nombre, v in pruebas.items()]
reporte = (
    f"# Validación de la extracción de datos IMF\n\n"
    f"**{ok} de {len(pruebas)} pruebas superadas.**\n\n"
    f"Verifica la estructura de los paneles, la coherencia de las variables "
    f"derivadas y que el subsidio por combustible sea consistente entre el "
    f"panel anual y el panel por combustible.\n\n"
    f"| Prueba | Resultado |\n|---|---|\n" + "\n".join(filas) + "\n\n"
    f"## Nota\n"
    f"El agregado `tot_total` del IMF no equivale exactamente a "
    f"`expl_total + impl_total` (difieren en algunos países), porque el IMF "
    f"calcula sus totales `all.all` de forma independiente. Se conserva el "
    f"agregado oficial del IMF.\n")
open(OUT, "w").write(reporte)

print(f"{ok}/{len(pruebas)} pruebas superadas. Reporte en {OUT}")
assert ok == len(pruebas), "Revisar: hay pruebas que no pasan"
