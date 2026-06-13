# Descarga de indicadores fiscales del Banco Mundial
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Descarga tres indicadores fiscales de la API del Banco Mundial para los
#   34 países de LATAM, 2015-2023, y los guarda como fuente complementaria:
#     balance fiscal, deuda pública e ingreso público (todos en % del PIB).
#   Sirven para discutir las implicaciones fiscales del choque.
#
# Output: data/raw/fiscal_wb.csv

import os
import requests
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "raw", "fiscal_wb.csv")

LAC_ISO = ["ATG","ARG","ABW","BHS","BRB","BLZ","BOL","BRA","CHL","COL","CRI",
           "DMA","DOM","ECU","SLV","GRD","GTM","GUY","HTI","HND","JAM","MEX",
           "NIC","PAN","PRY","PER","PRI","KNA","LCA","VCT","SUR","TTO","URY","VEN"]

INDICADORES = {
    "balance_fiscal": "GC.NLD.TOTL.GD.ZS",   # balance fiscal, % PIB
    "deuda_publica": "GC.DOD.TOTL.GD.ZS",    # deuda del gobierno central, % PIB
    "ingreso_publico": "GC.REV.XGRT.GD.ZS",  # ingreso público, % PIB
}
API = "https://api.worldbank.org/v2/country/{paises}/indicator/{ind}"


def descargar(indicador):
    url = API.format(paises=";".join(LAC_ISO), ind=indicador)
    r = requests.get(url, params={"format": "json", "date": "2015:2023", "per_page": 1000})
    datos = r.json()[1]
    return pd.DataFrame([
        {"iso": d["countryiso3code"], "anio": int(d["date"]), "valor": d["value"]}
        for d in datos
    ])


# Una columna por indicador, unidas por país-año
fiscal = None
for nombre, codigo in INDICADORES.items():
    serie = descargar(codigo).rename(columns={"valor": nombre})
    fiscal = serie if fiscal is None else fiscal.merge(serie, on=["iso", "anio"], how="outer")

fiscal = fiscal.sort_values(["iso", "anio"])
fiscal.to_csv(OUT, index=False)

print(f"Descargados {len(fiscal)} registros país-año para {fiscal.iso.nunique()} países")
print(fiscal.query("iso == 'COL' and anio >= 2021"))
print(f"Guardado en {OUT}")
