# Descarga de reservas internacionales del Banco Mundial
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Descarga dos métricas de reservas internacionales de la API del Banco
#   Mundial para los 34 países de LATAM, 2015-2023:
#     reservas_usd:    reservas totales (incl. oro) en USD corrientes
#     reservas_meses:  reservas en meses de importaciones (holgura externa)
#   Las reservas conectan el choque con la dimensión de balanza de pagos:
#   importadores netos pierden divisas al sostener el subsidio con Brent alto,
#   exportadores netos las acumulan.
#
# Output: data/raw/reservas_wb.csv

import os
import time
import requests
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "raw", "reservas_wb.csv")

LAC_ISO = ["ATG","ARG","ABW","BHS","BRB","BLZ","BOL","BRA","CHL","COL","CRI",
           "DMA","DOM","ECU","SLV","GRD","GTM","GUY","HTI","HND","JAM","MEX",
           "NIC","PAN","PRY","PER","PRI","KNA","LCA","VCT","SUR","TTO","URY","VEN"]

INDICADORES = {
    "reservas_usd": "FI.RES.TOTL.CD",     # reservas totales (incl. oro), USD corrientes
    "reservas_meses": "FI.RES.TOTL.MO",   # reservas en meses de importaciones
}
API = "https://api.worldbank.org/v2/country/{paises}/indicator/{ind}"


def descargar(indicador):
    url = API.format(paises=";".join(LAC_ISO), ind=indicador)
    params = {"format": "json", "date": "2015:2023", "per_page": 1000}
    for intento in range(3):                       # el WB a veces responde vacío; reintentar
        r = requests.get(url, params=params)
        try:
            datos = r.json()[1]
            break
        except (ValueError, KeyError, IndexError):
            time.sleep(2)
    else:
        raise RuntimeError(f"World Bank no devolvió datos para {indicador}")
    return pd.DataFrame([
        {"iso": d["countryiso3code"], "anio": int(d["date"]), "valor": d["value"]}
        for d in datos
    ])


# Una columna por indicador, unidas por país-año
reservas = None
for nombre, codigo in INDICADORES.items():
    serie = descargar(codigo).rename(columns={"valor": nombre})
    reservas = serie if reservas is None else reservas.merge(serie, on=["iso", "anio"], how="outer")

reservas = reservas.sort_values(["iso", "anio"])
reservas.to_csv(OUT, index=False)

print(f"Descargados {len(reservas)} registros país-año para {reservas.iso.nunique()} países")
print(f"Completitud: reservas_usd {reservas.reservas_usd.notna().sum()}, "
      f"reservas_meses {reservas.reservas_meses.notna().sum()}")
print(reservas.query("iso == 'COL' and anio >= 2021"))
print(f"Guardado en {OUT}")
