# -*- coding: utf-8 -*-
# =====================================================================
# PASO 1: Preparar los datos  (VERSION SIN INSTALACIONES)
# Proyecto: Precios de Productos Farmaceuticos - DIGEMID
# =====================================================================
# Que hace este script:
#   1. Lee los Excel de DIGEMID (carpeta "EXCEL-BASE DE DATOS")
#   2. Los limpia (quita filas que no son datos, corrige texto)
#   3. Calcula la variacion mensual de precio de cada producto
#   4. Genera UN SOLO archivo: datos_listos.csv
#
# Como usarlo:
#   - Solo necesitas Python instalado. NO hace falta instalar pandas
#     ni openpyxl (lee los .xlsx con librerias que ya trae Python).
#   - Pon este archivo junto a la carpeta "EXCEL-BASE DE DATOS" y
#     dale doble clic. La ventana NO se cierra sola: al final te
#     muestra el resultado (o el error) y espera un ENTER.
#   - El archivo datos_listos.csv se crea al lado de este script.
#   - Si el CSV esta abierto en Excel, cierralo antes de correr esto.
# =====================================================================

import csv
import re
import sys
import traceback
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

BASE = Path(__file__).resolve().parent
NOMBRE_CARPETA = "EXCEL-BASE DE DATOS"
SALIDA = BASE / "datos_listos.csv"

NOMBRES_MES = {
    1: "Enero", 2: "Febrero", 3: "Marzo", 4: "Abril", 5: "Mayo", 6: "Junio",
    7: "Julio", 8: "Agosto", 9: "Setiembre", 10: "Octubre",
    11: "Noviembre", 12: "Diciembre",
}

# Nombre en el Excel  ->  nombre en la base de datos
RENOMBRAR = {
    "Código de Producto": "codigo_producto",
    "Nombre Comercial": "nombre_comercial",
    "Concentración": "concentracion",
    "Forma Farmacéutica": "forma_farmaceutica",
    "Presentación": "presentacion",
    "Registro Sanitario": "registro_sanitario",
    "Titular de Registro Sanitario": "titular",
    "Fabricante": "fabricante",
    "País": "pais",
    "IFA": "ifa",
    "Clasificación": "clasificacion",
    "Cantidad de establecimientos reportantes por producto": "n_establecimientos",
    "media": "precio_media",
    "mediana": "precio_mediana",
    "moda": "precio_moda",
}
COLUMNAS_TEXTO = ["nombre_comercial", "forma_farmaceutica", "presentacion",
                  "clasificacion", "titular", "fabricante", "pais", "ifa",
                  "concentracion", "registro_sanitario"]
COLUMNAS_NUM = ["codigo_producto", "n_establecimientos",
                "precio_media", "precio_mediana", "precio_moda"]

COLUMNAS_FINALES = [
    "codigo_producto", "nombre_comercial", "concentracion",
    "forma_farmaceutica", "presentacion", "registro_sanitario",
    "ifa", "titular", "fabricante", "pais", "clasificacion",
    "n_establecimientos", "precio_media", "precio_mediana", "precio_moda",
    "periodo", "mes", "nombre_mes", "trimestre", "anio",
]


# ---------------------------------------------------------------------
# Lector de .xlsx (solo libreria estandar de Python)
# ---------------------------------------------------------------------
def _tag(e):
    return e.tag.rsplit("}", 1)[-1]


def _texto_si(nodo):
    """Texto de un <si> o <is> (une los pedazos, ignora fonetica)."""
    partes = []

    def rec(n):
        for h in n:
            t = _tag(h)
            if t == "t":
                partes.append(h.text or "")
            elif t in ("rPh", "phoneticPr"):
                continue
            else:
                rec(h)
    rec(nodo)
    return "".join(partes)


def _leer_shared(z):
    try:
        f = z.open("xl/sharedStrings.xml")
    except KeyError:
        return []
    out = []
    with f:
        for _, el in ET.iterparse(f):
            if _tag(el) == "si":
                out.append(_texto_si(el))
                el.clear()
    return out


def _ruta_primera_hoja(z):
    try:
        wb = ET.fromstring(z.read("xl/workbook.xml"))
        rels = ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
        rid = None
        for el in wb.iter():
            if _tag(el) == "sheet":
                for k, v in el.attrib.items():
                    if k.endswith("}id"):
                        rid = v
                break
        for r in rels:
            if r.attrib.get("Id") == rid:
                t = r.attrib["Target"].lstrip("/")
                return t if t.startswith("xl/") else "xl/" + t
    except Exception:
        pass
    hojas = sorted(n for n in z.namelist()
                   if n.startswith("xl/worksheets/") and n.endswith(".xml"))
    return hojas[0]


def _col_idx(ref):
    n = 0
    for ch in re.match(r"[A-Za-z]+", ref).group().upper():
        n = n * 26 + ord(ch) - 64
    return n - 1


def leer_filas(ruta):
    """Devuelve la primera hoja del Excel como lista de filas (listas)."""
    filas = []
    with zipfile.ZipFile(ruta) as z:
        shared = _leer_shared(z)
        with z.open(_ruta_primera_hoja(z)) as f:
            for _, el in ET.iterparse(f):
                if _tag(el) != "row":
                    continue
                fila = []
                for c in el:
                    if _tag(c) != "c":
                        continue
                    ref = c.attrib.get("r")
                    idx = _col_idx(ref) if ref else len(fila)
                    t = c.attrib.get("t")
                    v, nodo_is = None, None
                    for h in c:
                        if _tag(h) == "v":
                            v = h.text
                        elif _tag(h) == "is":
                            nodo_is = h
                    valor = None
                    if t == "s" and v is not None:
                        valor = shared[int(v)]
                    elif t == "inlineStr" and nodo_is is not None:
                        valor = _texto_si(nodo_is)
                    elif t == "str":
                        valor = v
                    elif t == "b":
                        valor = "TRUE" if v == "1" else "FALSE"
                    elif t == "e":
                        valor = None
                    elif v not in (None, ""):
                        try:
                            valor = float(v)
                        except ValueError:
                            valor = v
                    while len(fila) <= idx:
                        fila.append(None)
                    fila[idx] = valor
                filas.append(fila)
                el.clear()
    return filas


# ---------------------------------------------------------------------
# Limpieza
# ---------------------------------------------------------------------
def limpiar_texto(v):
    if v is None:
        return None
    if isinstance(v, float):
        v = str(int(v)) if v == int(v) else repr(v)
    s = str(v).strip().upper()
    return None if s in ("", "NAN") else s


def a_numero(v):
    if v is None:
        return None
    if isinstance(v, float):
        return v
    try:
        return float(str(v).strip())
    except ValueError:
        return None


def _nombre_col(x):
    return str(x).strip().replace("º", "°") if x is not None else ""


def procesar_archivo(ruta, periodo):
    filas = leer_filas(ruta)

    # el encabezado real es la fila que tiene la columna "N°"
    pos = None
    for i, f in enumerate(filas[:60]):
        if any(_nombre_col(x) == "N°" for x in f):
            pos = i
            break
    if pos is None:
        raise ValueError(f"No encontre la columna 'N°' en {ruta.name}. "
                         "Revisa que sea el Excel original de DIGEMID.")

    cols = {}
    for j, x in enumerate(filas[pos]):
        cols.setdefault(_nombre_col(x), j)
    faltan = [c for c in RENOMBRAR if c not in cols]
    if faltan:
        raise ValueError(f"En {ruta.name} faltan estas columnas: {faltan}\n"
                         f"Columnas encontradas: {list(cols)}")

    registros = []
    crudas = 0
    for f in filas[pos + 1:]:
        if not any(x not in (None, "") for x in f):
            continue                      # fila totalmente vacia
        crudas += 1
        n = f[cols["N°"]] if cols["N°"] < len(f) else None
        if a_numero(n) is None:
            continue                      # fila que no es dato (notas, totales)
        reg = {}
        for origen, destino in RENOMBRAR.items():
            j = cols[origen]
            reg[destino] = f[j] if j < len(f) else None
        for c in COLUMNAS_TEXTO:
            reg[c] = limpiar_texto(reg[c])
        for c in COLUMNAS_NUM:
            reg[c] = a_numero(reg[c])
        reg["periodo"] = periodo
        registros.append(reg)
    return registros, crudas


# ---------------------------------------------------------------------
# Utilidades de formato
# ---------------------------------------------------------------------
def fmt_entero(x):
    return "" if x is None else str(int(x))


def fmt_decimal(x):
    return "" if x is None else repr(x)


def _clave_orden(v):
    return (v is None, v if v is not None else (0 if not isinstance(v, str) else ""))


# ---------------------------------------------------------------------
# Programa principal
# ---------------------------------------------------------------------
def buscar_excels():
    candidatas = [BASE / NOMBRE_CARPETA, Path.cwd() / NOMBRE_CARPETA, BASE]
    for carpeta in candidatas:
        if not carpeta.is_dir():
            continue
        por_periodo = {}
        for p in carpeta.glob("*.xlsx"):
            if p.name.startswith("~$"):
                continue
            m = re.search(r"(20\d{2})(0[1-9]|1[0-2])", p.stem)
            if not m:
                continue
            per = f"{m.group(1)}-{m.group(2)}"
            if per not in por_periodo or p.stat().st_mtime > por_periodo[per].stat().st_mtime:
                por_periodo[per] = p
        if por_periodo:
            return carpeta, dict(sorted(por_periodo.items()))
    raise FileNotFoundError(
        f"No encontre los Excel. Deben estar en una carpeta llamada "
        f"'{NOMBRE_CARPETA}' junto a este script, con nombres como "
        f"'MTC 202601.xlsx'.\nBuscado en: {BASE}")


def main():
    try:
        sys.stdout.reconfigure(errors="replace")
    except Exception:
        pass

    carpeta, archivos = buscar_excels()
    print(f"Carpeta de Excel: {carpeta}")
    print(f"Se encontraron {len(archivos)} archivos:")
    todos, total_crudo = [], 0
    for per, ruta in archivos.items():
        print(f"  Leyendo {per}  ->  {ruta.name} ...")
        regs, crudas = procesar_archivo(ruta, per)
        print(f"     filas de datos: {len(regs)}")
        todos.extend(regs)
        total_crudo += crudas
    print(f"  Filas leidas (crudo): {total_crudo}")

    # mes / trimestre / anio
    for r in todos:
        r["anio"] = int(r["periodo"][:4])
        r["mes"] = int(r["periodo"][5:7])
        r["nombre_mes"] = NOMBRES_MES[r["mes"]]
        r["trimestre"] = (r["mes"] - 1) // 3 + 1

    # quitar duplicados exactos
    vistos, unicos = set(), []
    for r in todos:
        k = tuple(r[c] for c in COLUMNAS_FINALES)
        if k not in vistos:
            vistos.add(k)
            unicos.append(r)
    print(f"  Filas despues de limpiar: {len(unicos)}")

    # variacion mensual (%) contra el mes anterior del mismo producto
    clave_prod = ["codigo_producto", "titular", "fabricante",
                  "clasificacion", "pais"]
    unicos.sort(key=lambda r: tuple(_clave_orden(r[c]) for c in
                                    clave_prod + ["anio", "mes"]))
    anterior = {}
    for r in unicos:
        k = tuple(r[c] for c in clave_prod)
        r["variacion_mensual_pct"] = None
        if None not in k:
            prev = anterior.get(k)
            act = r["precio_mediana"]
            if prev not in (None, 0) and act is not None:
                r["variacion_mensual_pct"] = round((act - prev) / prev * 100 * 100) / 100
            anterior[k] = act

    # escribir CSV
    try:
        with open(SALIDA, "w", encoding="utf-8-sig", newline="") as f:
            w = csv.writer(f, lineterminator="\n")
            w.writerow(COLUMNAS_FINALES + ["variacion_mensual_pct"])
            for r in unicos:
                fila = []
                for c in COLUMNAS_FINALES:
                    v = r[c]
                    if c in ("codigo_producto", "n_establecimientos"):
                        fila.append(fmt_entero(v))
                    elif c in ("precio_media", "precio_mediana", "precio_moda"):
                        fila.append(fmt_decimal(v))
                    else:
                        fila.append("" if v is None else v)
                vm = r["variacion_mensual_pct"]
                fila.append("" if vm is None else repr(float(vm)))
                w.writerow(fila)
    except PermissionError:
        raise PermissionError(
            f"No pude escribir {SALIDA.name}. Si lo tienes abierto en Excel, "
            "cierralo y vuelve a correr el script.")

    print(f"\nListo. Se genero el archivo: {SALIDA}")
    print(f"Total de registros: {len(unicos)}")
    print("\nRegistros por mes:")
    conteo = {}
    for r in unicos:
        conteo[r["periodo"]] = conteo.get(r["periodo"], 0) + 1
    for per in sorted(conteo):
        print(f"  {per}  {conteo[per]}")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("\n==================== ERROR ====================")
        traceback.print_exc()
        print("===============================================")
        print("Copia este mensaje y mandaselo a quien te ayuda.")
    try:
        input("\nPresiona ENTER para cerrar esta ventana...")
    except (EOFError, RuntimeError):
        pass
