# Descarga de indicadores fiscales del FMI (WEO, via IMF DataMapper API)
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Descarga tres indicadores fiscales del World Economic Outlook (FMI) para
#   los 34 paises de LATAM, 2015-2023, via la IMF DataMapper API:
#     balance fiscal (net lending/borrowing), deuda publica bruta e ingreso
#     publico (todos del gobierno general, en % del PIB).
#   Se usa el WEO y no el Banco Mundial porque el WEO cubre los 34 paises sin
#   huecos (el BM dejaba 50-79% de NA, sobre todo en el Caribe), lo que permite
#   usar las variables fiscales en el analisis cuantitativo y no solo en prosa.
#   El reto sugiere explicitamente complementar con WEO.
#
# Output: data/raw/fiscal_weo.xlsx
#
# Indicadores WEO (DataMapper):
#   GGXCNL_NGDP     balance fiscal = net lending/borrowing del gob. general, % PIB
#   GGXWDG_NGDP     deuda publica bruta del gob. general, % PIB
#   GGR_G01_GDP_PT  ingreso del gob. general, % PIB

import os
import requests
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data", "raw", "fiscal_weo.xlsx")

LAC_ISO = ["ATG","ARG","ABW","BHS","BRB","BLZ","BOL","BRA","CHL","COL","CRI",
           "DMA","DOM","ECU","SLV","GRD","GTM","GUY","HTI","HND","JAM","MEX",
           "NIC","PAN","PRY","PER","PRI","KNA","LCA","VCT","SUR","TTO","URY","VEN"]

INDICADORES = {
    "balance_fiscal": "GGXCNL_NGDP",     # net lending/borrowing, % PIB
    "deuda_publica": "GGXWDG_NGDP",      # deuda bruta gob. general, % PIB
    "ingreso_publico": "GGR_G01_GDP_PT", # ingreso gob. general, % PIB
}
API = "https://www.imf.org/external/datamapper/api/v1/{ind}"
ANIOS = range(2015, 2024)


def descargar(indicador):
    r = requests.get(API.format(ind=indicador), timeout=30)
    valores = r.json().get("values", {}).get(indicador, {})
    filas = []
    for iso in LAC_ISO:
        serie = valores.get(iso, {})
        for anio in ANIOS:
            v = serie.get(str(anio))
            if v is not None:
                filas.append({"iso": iso, "anio": anio, "valor": float(v)})
    return pd.DataFrame(filas)


# Una columna por indicador, unidas por pais-anio
fiscal = None
for nombre, codigo in INDICADORES.items():
    serie = descargar(codigo).rename(columns={"valor": nombre})
    fiscal = serie if fiscal is None else fiscal.merge(serie, on=["iso", "anio"], how="outer")

fiscal = fiscal.sort_values(["iso", "anio"])
fiscal.to_excel(OUT, index=False)

n_obs = len(fiscal)
print(f"Descargados {n_obs} registros pais-anio para {fiscal.iso.nunique()} paises")
for c in INDICADORES:
    print(f"  {c}: {fiscal[c].notna().sum()}/{n_obs} no-NA")
print(fiscal.query("iso == 'COL' and anio >= 2021"))
print(f"Guardado en {OUT}")
