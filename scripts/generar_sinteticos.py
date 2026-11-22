# -*- coding: utf-8 -*-
# =====================================================================
# Generador de datos sinteticos REALISTAS - Proyecto precios DIGEMID
# =====================================================================
# Que hace:
#   Toma datos_listos.csv (los 92 816 registros reales) y crea productos
#   nuevos a partir de productos reales, para llegar a N filas.
#   Conserva: laboratorio, pais, clasificacion (marca/generico), forma,
#   concentracion, los 6 meses y la forma en que cambia el precio mes a mes.
#   Cambia: el codigo del producto y el nivel de precio (factor aleatorio),
#   y el numero de establecimientos (variacion pequena).
#
# Como usarlo (solo Python, sin instalar nada):
#   OPCION A (doble clic): coloca este archivo junto a datos_listos.csv y
#     haz doble clic. Genera los 3 archivos (100k, 500k y 1M) y deja la
#     ventana abierta con la validacion para tomar la captura.
#   OPCION B (terminal), igual que la version original:
#     python generar_sinteticos.py datos_listos.csv 100000 sinteticos_100k.csv
#     python generar_sinteticos.py datos_listos.csv 500000 sinteticos_500k.csv
#     python generar_sinteticos.py datos_listos.csv 1000000 sinteticos_1m.csv
# Semilla fija (42): siempre genera lo mismo.
# La logica de generacion es identica a la original: produce los mismos CSV.
# =====================================================================
import csv, random, sys, os, math, time, statistics as st
from collections import defaultdict

SEMILLA = 42
SIGMA_PRECIO = 0.20   # desviacion del factor de precio (lognormal)

# Trabajos que se ejecutan al hacer doble clic (sin argumentos)
TRABAJOS = [
    (100000, "sinteticos_100k.csv"),
    (500000, "sinteticos_500k.csv"),
    (1000000, "sinteticos_1m.csv"),
]

def f(x):
    return float(x) if x not in ("", None) else None

def main(entrada, n_objetivo, salida):
    t0 = time.perf_counter()
    random.seed(SEMILLA)
    with open(entrada, encoding="utf-8-sig", newline="") as fh:
        rd = csv.DictReader(fh)
        cols = rd.fieldnames
        filas = list(rd)
    # series reales: un producto = codigo + titular + fabricante + clasificacion + pais
    series = defaultdict(list)
    for r in filas:
        k = (r["codigo_producto"], r["titular"], r["fabricante"], r["clasificacion"], r["pais"])
        series[k].append(r)
    for k in series:
        series[k].sort(key=lambda r: r["periodo"])
    claves = list(series)
    codigo_max = max(f(r["codigo_producto"]) for r in filas)
    escritos, nuevo = 0, 0
    with open(salida, "w", encoding="utf-8-sig", newline="") as out:
        w = csv.DictWriter(out, fieldnames=cols, lineterminator="\n")
        w.writeheader()
        while escritos < n_objetivo:
            molde = series[random.choice(claves)]
            nuevo += 1
            codigo = codigo_max + nuevo
            factor = math.exp(random.gauss(0, SIGMA_PRECIO))
            jit = random.choice([-1, 0, 0, 1])
            prev = None
            for r in molde:
                if escritos >= n_objetivo:
                    break
                s = dict(r)
                s["codigo_producto"] = repr(float(codigo))
                s["registro_sanitario"] = "SINT%07d" % nuevo
                for c in ("precio_media", "precio_mediana", "precio_moda"):
                    v = f(r[c])
                    s[c] = "" if v is None else repr(round(v * factor, 4))
                ne = f(r["n_establecimientos"])
                s["n_establecimientos"] = "" if ne is None else repr(float(max(1, int(ne) + jit)))
                act = f(s["precio_mediana"])
                if prev not in (None, 0) and act is not None:
                    s["variacion_mensual_pct"] = repr(round((act - prev) / prev * 100, 2))
                else:
                    s["variacion_mensual_pct"] = ""
                prev = act
                w.writerow(s)
                escritos += 1
    mb = os.path.getsize(salida) / (1024 * 1024)
    print("Listo:", salida, "-", escritos, "filas,", nuevo, "productos nuevos",
          "| tamano: %.1f MB | tiempo: %.1f s" % (mb, time.perf_counter() - t0))
    validar(filas, salida)

def resumen(rows, etiqueta):
    # Recorre las filas una sola vez (sirve para listas o para leer el archivo
    # fila por fila), asi el archivo de 1M no se carga completo en memoria.
    n = 0; n_marca = 0
    med = {"MARCA": [], "GENERICO": []}
    n_var = 0; n_alza = 0
    labs = set(); paises = set()
    for r in rows:
        n += 1
        c = r["clasificacion"]
        if c == "MARCA":
            n_marca += 1
        if c in med and r["precio_mediana"]:
            med[c].append(f(r["precio_mediana"]))
        if r["variacion_mensual_pct"]:
            n_var += 1
            if f(r["variacion_mensual_pct"]) > 5:
                n_alza += 1
        labs.add(r["titular"]); paises.add(r["pais"])
    print("%-10s filas=%8d | %%marca=%5.1f | mediana marca=%6.2f gen=%5.2f | %%alza>5=%4.1f | labs=%d paises=%d"
          % (etiqueta, n, n_marca / n * 100, st.median(med["MARCA"]), st.median(med["GENERICO"]),
             n_alza / n_var * 100, len(labs), len(paises)))

def validar(reales, salida):
    print("\nValidacion (real vs sintetico):")
    resumen(reales, "REAL")
    with open(salida, encoding="utf-8-sig", newline="") as fh:
        resumen(csv.DictReader(fh), "SINTETICO")
    print()

def pausa():
    try:
        input("Presiona Enter para cerrar esta ventana...")
    except EOFError:
        pass

if __name__ == "__main__":
    if len(sys.argv) == 4:
        # Modo terminal: igual que la version original
        main(sys.argv[1], int(sys.argv[2]), sys.argv[3])
    elif len(sys.argv) == 1:
        # Modo doble clic: trabaja en la carpeta donde esta este script
        try:
            os.chdir(os.path.dirname(os.path.abspath(__file__)))
            if not os.path.exists("datos_listos.csv"):
                print("ERROR: no se encontro datos_listos.csv en la carpeta:")
                print("  " + os.getcwd())
                print("Coloca este script en la misma carpeta que datos_listos.csv.")
            else:
                print("Generando los 3 archivos sinteticos en:", os.getcwd(), "\n")
                for n, salida in TRABAJOS:
                    main("datos_listos.csv", n, salida)
        except Exception as e:
            print("\nOcurrio un error:", repr(e))
        pausa()
    else:
        print("Uso: python generar_sinteticos.py datos_listos.csv N salida.csv")
        print("O haz doble clic en el archivo para generar los 3 archivos.")
        sys.exit(1)
