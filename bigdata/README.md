# bigdata/: Notebooks de Databricks (PySpark)

Aquí están los notebooks de Big Data. Se corren en Databricks Free Edition con cómputo Serverless (Apache Spark 4.2.0). Los archivos de datos van en el volume `workspace.ef_precios_medicamentos.datos`.

## Notebooks base (correrlos en este orden)

| Notebook | Qué hace |
|---|---|
| `00_configuracion.ipynb` | Crea el esquema `workspace.ef_precios_medicamentos` y el volume `datos`. |
| `01_carga_eda.ipynb` | Carga `datos_listos.csv`, análisis exploratorio (describe, nulos, duplicados, periodos), limpieza, tablas Bronze y Silver, KPI en Gold (`gold_kpis`) y gráficos. |

## Experimentos (`experimentos/`)

Hay un notebook por experimento. Todos descartan 1 calentamiento, repiten 3 veces y reportan la mediana. Necesitan los datos sintéticos ya subidos al volume (mira el README principal).

| Notebook | Responsable | Qué compara |
|---|---|---|
| `EF_exp_ingrid.ipynb` | Ingrid | Volumen de datos: 100k, 500k y 1M filas (lectura, filtro, agrupaciones) |
| `EF_exp_ingrid_operaciones.ipynb` | Ingrid | Tipo de operación en Spark (lectura CSV, narrow, wide, resumen, escritura Delta) |
| `EF_exp_samuel.ipynb` (y `.html`) | Samuel | Número de particiones (1 a 32) con 1M de filas |
| `EF_exp_gonzalo.ipynb` | Gonzalo | CSV frente a Parquet (tamaño en disco y tiempo) |
| `EF_exp_Steve.ipynb` | Steve | `inferSchema` frente a esquema explícito |

## Cómo importar un notebook

1. En Databricks: **Workspace → Import** y elige el archivo `.ipynb`.
2. Conéctalo a **Serverless**.
3. Revisa que la ruta (`/Volumes/workspace/ef_precios_medicamentos/datos/...`) sea la de tu cuenta y corre las celdas una por una.

Cada cuenta de Databricks es independiente, así que las tablas y archivos no se comparten entre integrantes.
