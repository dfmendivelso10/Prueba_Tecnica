# Procesamiento de datos IMF - Subsidios a combustibles fósiles
# Autor: Daniel Mendivelso
# Fecha: 2026-06-13
#
# Descripcion:
#   Extrae del .xlsb del IMF (escenario baseline U1) las variables crudas
#   y arma dos paneles base (sin variables derivadas, esas van en 01_variables.py):
#     Panel base:        país × año con las variables tal cual del IMF
#     Panel combustible: país × año × combustible (explícito/implícito/total)
#
# Input:  data/raw/imffossilfuelsubsidiesdata.xlsb
#         brent_anual.csv, fiscal_wb.csv, riesgo_pais.csv (fuentes complementarias)
# Output: data/processed/panel_base.xlsx
#         data/processed/panel_pais_anio_combustible.xlsx

import os
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
XLSB = os.path.join(ROOT, "data", "raw", "imffossilfuelsubsidiesdata.xlsb")
PROC = os.path.join(ROOT, "data", "processed")
os.makedirs(PROC, exist_ok=True)

LAC_ISO = {"ATG","ARG","ABW","BHS","BRB","BLZ","BOL","BRA","CHL","COL","CRI",
           "DMA","DOM","ECU","SLV","GRD","GTM","GUY","HTI","HND","JAM","MEX",
           "NIC","PAN","PRY","PER","PRI","KNA","LCA","VCT","SUR","TTO","URY","VEN"}

# Variables a extraer: nombre legible -> código del IMF (ver docs/diccionario)
VARS = {
    "expl_total": "mit.expsub.con.all.all.1", "impl_total": "mit.impsub.con.all.all.1",
    "tot_total": "mit.allsub.con.all.all.1", "expl_pctgdp": "mit.expsubgdp.con.all.all.1",
    "impl_pctgdp": "mit.impsubgdp.con.all.all.1", "tot_pctgdp": "mit.allsubgdp.con.all.all.1",
    "gdp": "mit.gdp.pre.lvl.1", "pop": "mit.pop.mn",
    "rev_usd": "mit.rev.new.usd.1", "rev_pctgdp": "mit.rev.new.pct.1",
    "eff_cost_usd": "mit.wel.eco.dwl.usd", "eff_cost_pctgdp": "mit.wel.eco.dwl.pct",
    "expl_oil": "mit.expsub.con.oil.all.1", "expl_nga": "mit.expsub.con.nga.all.1",
    "expl_ecy": "mit.expsub.con.ecy.all.1", "impl_oil": "mit.impsub.con.oil.all.1",
    "impl_nga": "mit.impsub.con.nga.all.1",
    "precio_gso": "mit.rp.gso.all.1", "precio_die": "mit.rp.die.all.1",
    "precio_nga": "mit.rp.nga.res.1", "costo_gso": "mit.sup.cost.gso.all.1",
    "costo_die": "mit.sup.cost.die.all.1", "costo_nga": "mit.sup.cost.nga.res.1",
}

# Combustibles para el panel largo, con su código explícito e implícito
# (la electricidad no tiene subsidio implícito en la base del IMF)
FUELS = [
    {"nombre": "Petróleo",     "explicito": "mit.expsub.con.oil.all.1", "implicito": "mit.impsub.con.oil.all.1"},
    {"nombre": "Gas natural",  "explicito": "mit.expsub.con.nga.all.1", "implicito": "mit.impsub.con.nga.all.1"},
    {"nombre": "Electricidad", "explicito": "mit.expsub.con.ecy.all.1", "implicito": None},
    {"nombre": "Carbón",       "explicito": "mit.expsub.con.coa.all.1", "implicito": "mit.impsub.con.coa.all.1"},
]

# Leer la hoja: el header del .xlsb está corrido, así que renombramos por posición
raw = pd.read_excel(XLSB, sheet_name="data", engine="pyxlsb")
raw.columns = ["pais", "scenario", "_d", "_c", "iso", "incomelevel", "region",
               "mtcode", "_s"] + list(raw.columns[9:])
anios = {2015: 24, 2016: 25, 2017: 26, 2018: 27, 2019: 28, 2020: 29,
         2021: 9, 2022: 10, 2023: 11}

# El mapeo es posicional; verificamos por contenido para fallar si el IMF reordena columnas
assert raw.scenario.dropna().isin(["U1", "U2", "U3", "U4"]).all(), "col 'scenario' no contiene U1..U4"
assert raw.iso.str.match(r"^[A-Z]{3}$").any(), "col 'iso' no contiene códigos ISO3"
assert raw.mtcode.str.startswith("mit.").any(), "col 'mtcode' no contiene códigos mit.*"
assert all(raw.columns[c] == a for a, c in anios.items()), "columnas de año no coinciden con su header"

# Avisar si algún código pedido no existe en el archivo, pero seguir
codigos_archivo = set(raw.mtcode.dropna())
for cod in VARS.values():
    if cod not in codigos_archivo:
        print(f"  Advertencia: el código {cod} no está en el archivo del IMF")

# Pasar a formato largo (país-variable-año), solo escenario baseline y LATAM
ids = ["pais", "iso", "region", "incomelevel", "mtcode"]
df = (raw[(raw.scenario == "U1") & raw.iso.isin(LAC_ISO)]
      .melt(id_vars=ids, value_vars=[raw.columns[c] for c in anios.values()],
            var_name="col", value_name="valor"))
df["anio"] = df["col"].map({raw.columns[c]: a for a, c in anios.items()})
df["valor"] = pd.to_numeric(df["valor"], errors="coerce")   # "0x2a" del IMF -> NA

# Panel base: una columna por variable, identificadores + año
sub = df[df.mtcode.isin(VARS.values())].assign(var=lambda x: x.mtcode.map({v: k for k, v in VARS.items()}))
base = sub.pivot_table(index=["iso", "pais", "region", "incomelevel", "anio"],
                       columns="var", values="valor", aggfunc="first").reset_index()

# Añadir el precio internacional del petróleo (Brent), fuente complementaria al IMF
brent = pd.read_csv(os.path.join(ROOT, "data", "raw", "brent_anual.csv"))
base = base.merge(brent, on="anio", how="left")

# Añadir indicadores fiscales del Banco Mundial (balance, deuda, ingreso público)
fiscal = pd.read_csv(os.path.join(ROOT, "data", "raw", "fiscal_wb.csv"))
base = base.merge(fiscal, on=["iso", "anio"], how="left")

# Nota: el riesgo país (EMBIG, data/raw/riesgo_pais.csv) se excluye del panel:
# solo cubre 8 países que emiten deuda en USD (70/306), sesgaría la muestra.

# Panel por combustible: relacionar cada código con su combustible y componente
filas_mapa = []
for fuel in FUELS:
    for componente in ["explicito", "implicito"]:
        codigo = fuel[componente]
        if codigo:
            filas_mapa.append({"mtcode": codigo, "combustible": fuel["nombre"],
                               "componente": componente})
mapa = pd.DataFrame(filas_mapa)

pf = df.merge(mapa, on="mtcode").pivot_table(
    index=["iso", "anio", "combustible"], columns="componente",
    values="valor", aggfunc="first").reset_index()
pf["total"] = pf[["explicito", "implicito"]].sum(axis=1, min_count=1)

# Resumen y guardado
print(f"Panel base:        {base.shape[0]} filas × {base.shape[1]} columnas")
print(base.head(), "\n")
print(f"Panel combustible: {pf.shape[0]} filas × {pf.shape[1]} columnas")
print(pf.head(), "\n")
col22 = base.query("iso == 'COL' and anio == 2022")["expl_total"].iloc[0]
assert abs(col22 - 8.29) < 0.1, "Check Colombia 2022 falló"

base.to_excel(os.path.join(PROC, "panel_base.xlsx"), index=False)
pf.to_excel(os.path.join(PROC, "panel_pais_anio_combustible.xlsx"), index=False)
print("Paneles guardados en data/processed/")
