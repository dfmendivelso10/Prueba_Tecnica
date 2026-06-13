# Construcción de variables derivadas
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Toma el panel base y construye los indicadores del análisis:
#     per cápita, participación del explícito, y las brechas de precio
#     (precio al consumidor menos costo de suministro) por combustible.
#   La brecha es el subsidio explícito por unidad: el canal del choque.
#
# Input:  data/processed/panel_base.xlsx
# Output: data/processed/panel_pais_anio.xlsx

import os
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROC = os.path.join(ROOT, "data", "processed")

df = pd.read_excel(os.path.join(PROC, "panel_base.xlsx"))

# Subsidio per cápita y peso del componente explícito
df["subsidio_pc_usd"] = df["tot_total"] / df["pop"]
df["expl_share"] = (df["expl_total"] / df["tot_total"]).where(df["tot_total"] > 0)

# Brechas de precio: precio al consumidor - costo de suministro (subsidio explícito unitario)
df["brecha_gso"] = df["precio_gso"] - df["costo_gso"]
df["brecha_die"] = df["precio_die"] - df["costo_die"]
df["brecha_nga"] = df["precio_nga"] - df["costo_nga"]

print(f"Panel de análisis: {df.shape[0]} filas × {df.shape[1]} columnas")
print(df[["iso", "anio", "subsidio_pc_usd", "expl_share",
          "brecha_gso", "brecha_die", "brecha_nga"]].head(), "\n")

df.to_excel(os.path.join(PROC, "panel_pais_anio.xlsx"), index=False)
print("Panel guardado en data/processed/panel_pais_anio.xlsx")
