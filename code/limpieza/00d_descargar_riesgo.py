# Descarga del riesgo país (EMBIG)
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Descarga el EMBIG (riesgo país, spread soberano en puntos base) de la API
#   del Banco Central de Reserva del Perú para los países LATAM que lo publican,
#   y promedia los valores mensuales a anuales. El EMBIG solo existe para países
#   que emiten deuda en dólares, por eso no cubre a los 34 (las islas del Caribe
#   quedan sin dato). Es un proxy del costo de financiamiento soberano.
#
# Output: data/raw/riesgo_pais.csv

import os
import requests
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "raw", "riesgo_pais.csv")

# Código de serie BCRP -> país (ISO3)
SERIES = {
    "PN01129XM": "PER", "PN01130XM": "ARG", "PN01131XM": "BRA", "PN01132XM": "CHL",
    "PN01133XM": "COL", "PN01134XM": "ECU", "PN01135XM": "MEX", "PN01136XM": "VEN",
}
API = "https://estadisticas.bcrp.gob.pe/estadisticas/series/api/{serie}/json/2015-1/2023-12"
MESES = {"Ene": 1, "Feb": 2, "Mar": 3, "Abr": 4, "May": 5, "Jun": 6,
         "Jul": 7, "Ago": 8, "Set": 9, "Oct": 10, "Nov": 11, "Dic": 12}


def descargar(serie, iso):
    datos = requests.get(API.format(serie=serie)).json()["periods"]
    filas = []
    for p in datos:
        valor = p["values"][0]
        if valor not in ("", "n.d."):
            anio = int(p["name"].split(".")[1])
            filas.append({"iso": iso, "anio": anio, "embig": float(valor)})
    return pd.DataFrame(filas)


# Descargar cada país y promediar los meses a valor anual
mensual = pd.concat([descargar(s, iso) for s, iso in SERIES.items()])
riesgo = mensual.groupby(["iso", "anio"], as_index=False)["embig"].mean().round(1)
riesgo.to_csv(OUT, index=False)

print(f"Descargado EMBIG para {riesgo.iso.nunique()} países, {len(riesgo)} registros país-año")
print(riesgo.query("anio >= 2021").pivot(index="iso", columns="anio", values="embig"))
print(f"Guardado en {OUT}")
