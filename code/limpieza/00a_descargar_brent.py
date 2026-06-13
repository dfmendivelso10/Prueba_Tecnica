# Descarga del precio del petróleo Brent
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Descarga el precio anual del crudo Brent (promedio, USD por barril) de
#   datahub.io (serie basada en datos de la EIA) y lo guarda como fuente
#   complementaria. Es la variable del choque de precios internacional;
#   el IMF no incluye el precio del barril.
#
# Output: data/raw/brent_anual.csv

import os
import requests
import pandas as pd
from io import StringIO

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "raw", "brent_anual.csv")
URL = "https://datahub.io/core/oil-prices/r/brent-year.csv"

datos = pd.read_csv(StringIO(requests.get(URL).text))
datos["anio"] = pd.to_datetime(datos["Date"]).dt.year
brent = (datos[datos.anio.between(2015, 2023)]
         .rename(columns={"Price": "brent_usd"})[["anio", "brent_usd"]]
         .sort_values("anio"))
brent.to_csv(OUT, index=False)

print(f"Descargados {len(brent)} años de precio Brent")
print(brent.to_string(index=False))
print(f"Guardado en {OUT}")
