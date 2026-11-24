# scripts/: Python y SQL

## Pipeline BI (ejecutar en este orden)

| Orden | Script | Qué hace |
|---|---|---|
| 1 | `01_preparar_datos.py` | Lee los 6 Excel de DIGEMID y genera `datos_listos.csv` (92 816 registros). Solo necesita Python. |
| 2 | `02_crear_y_cargar_base_datos.sql` | Se abre en SSMS. Crea la base `DW_PreciosDigemid`, carga el CSV en una tabla de paso y llena las dimensiones y la tabla de hechos. Antes hay que cambiar `CAMBIAR_RUTA` por la ruta de tu CSV. |

## Datos sintéticos

| Script | Qué hace |
|---|---|
| `generar_sinteticos.py` | Genera datasets de N filas a partir de los datos reales (semilla 42) y al final compara lo real con lo sintético. Uso: `py scripts/generar_sinteticos.py datos/datos_listos.csv 1000000 sinteticos_1m.csv` |

## Experimentos BI (SQL Server, ejecutar después del paso 2)

| Script | Responsable | Qué mide |
|---|---|---|
| `EXP_BI_ingrid_indice.sql` | Ingrid | Consulta con y sin índice no agrupado sobre `HECHO_PRECIO_1M` (1M de filas). Crea esa tabla en el paso 1. |
| `EXP_BI_ingrid_carga.sql` | Ingrid | `BULK INSERT` de 1M filas: TABLOCK × BATCHSIZE. Necesita `C:\datos\sinteticos_1m.csv`. |
| `Samuel_EXP_BI.sql` | Samuel | Paralelismo: `MAXDOP 1` frente al valor por defecto (SQL Server Express). |
| `Samuel_EXP_BI_dev.sql` | Samuel | Mismo experimento repetido en SQL Server Developer. |
| `EXP_BI_gonzalo_volumen.sql` | Gonzalo | Volumen de registros: 100k, 500k y 1M. |
| `pruebas/` | Equipo | Validación del dataset y pruebas iniciales sobre `HECHO_PRECIO_PRUEBA`. |
| `pruebas/registro_ejecuciones.sql` | Equipo | Mide con `STATISTICS TIME/IO` un conteo y un promedio de `Precio_Media` sobre `HECHO_PRECIO_PRUEBA` (100k), `HECHO_PRECIO_500K` (500k) y 1M de filas, con `MAXDOP 1`. Son las pruebas iniciales de volumen. |
| `pruebas/validacion_dataset.sql` | Equipo | Revisa que los datos estén completos: compara las filas de `STG_PRECIOS` con las de `HECHO_PRECIO` y cuenta los nulos en los campos de precio. |
| `pruebas/verificacion_funcionalidad.sql` | Equipo | Comprueba que la tabla de prueba `HECHO_PRECIO_PRUEBA` funciona y que cada escenario tiene las filas esperadas. |

Los tres se corren después del paso 2, en SSMS, sobre la base `DW_PreciosDigemid`. `registro_ejecuciones.sql` y `verificacion_funcionalidad.sql` necesitan que existan las tablas `HECHO_PRECIO_PRUEBA` y `HECHO_PRECIO_500K`; las crea el script de volumen de Gonzalo.

Todos los experimentos descartan 1 calentamiento, repiten 3 veces y reportan la mediana. Córrelos con el plan de ejecución apagado: si está activo, suma tiempo y las mediciones salen más lentas.
