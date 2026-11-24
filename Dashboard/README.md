# Dashboard/: Power BI

| Archivo | Qué es |
|---|---|
| `proyecto.pbix` | Dashboard final. Tiene los 4 KPI con su objetivo (brecha marca/genérico, % de productos con alza > 5 %, variación mensual de genéricos y dispersión entre laboratorios), la evolución de precios, el precio por país y por laboratorio, y filtros por producto, clasificación y mes. |
| `experimentos/dashboard_DirectQuery.pbix` | Copia del dashboard con conexión DirectQuery, que usó Steve en su experimento (Importar frente a DirectQuery). No es el dashboard final. |

## Cómo abrirlo

1. Necesitas **Power BI Desktop** y la base `DW_PreciosDigemid` creada en tu SQL Server (script `scripts/02_crear_y_cargar_base_datos.sql`).
2. Abre el `.pbix`. Si te pide el origen de datos: **Transformar datos → Configuración de origen de datos** y escribe el nombre de **tu** servidor (el que usas en SSMS) y la base `DW_PreciosDigemid`.
3. Actualiza los datos (**Inicio → Actualizar**).

## Rendimiento

Medimos el rendimiento con el Analizador de rendimiento (pestaña Optimizar). En 11 cambios de segmentación, con 20 visuales que se actualizan cada vez, el máximo fue ≈ 466 ms y la mediana ≈ 430 ms. El criterio era menos de 5 s. Las capturas están en `evidencias/ingrid/Ingrid_20_*`.
