# Guía paso a paso para replicar los experimentos

Esta guía es para alguien que nunca ha visto código. No hace falta saber programar: solo copiar, pegar y ejecutar en el orden indicado. Si algo no se parece a lo que ves en pantalla, mira las preguntas frecuentes del [README principal](../README.md).

**Palabras que aparecen en la guía**

| Palabra | Qué significa |
|---|---|
| **Repositorio** | La carpeta del proyecto en GitHub, con todos los archivos. |
| **Script** | Un archivo con instrucciones que el computador ejecuta (`.py` es de Python, `.sql` es de SQL Server). |
| **Notebook** | Un archivo (`.ipynb`) dividido en **celdas**; cada celda es un trozo de código que se ejecuta con un botón. |
| **Celda** | Un recuadro de un notebook. Se ejecuta con el botón ▶ o con `Shift + Enter`. |
| **SSMS** | SQL Server Management Studio: el programa donde se escriben y ejecutan los scripts `.sql`. |
| **Calentamiento** | Una primera ejecución que **no se cuenta**, porque suele ser más lenta (el sistema "se prepara"). |
| **Mediana** | De 3 mediciones, el valor del medio al ordenarlas de menor a mayor. |
| **Volume** | La "carpeta" de Databricks donde se guardan los archivos subidos. |

---

## Parte A. Preparar tu computador (una sola vez)

### A1. Instalar Python
1. Entra a <https://www.python.org/downloads/> y pulsa el botón amarillo **Download Python**.
2. Abre el instalador descargado.
3. **Marca la casilla "Add python.exe to PATH"** (abajo en la primera ventana). Es lo más importante.
4. Pulsa **Install Now** y espera a que diga *Setup was successful*.
5. Comprueba: pulsa la tecla Windows, escribe `powershell`, abre **Windows PowerShell** y escribe `py --version`. Debe aparecer algo como `Python 3.14.0`.

### A2. Instalar SQL Server Express y SSMS
1. Descarga **SQL Server Express** desde <https://www.microsoft.com/es-pe/sql-server/sql-server-downloads> (botón *Descargar ahora* en la edición **Express**).
2. Ábrelo y elige **Básica**. Acepta los términos y pulsa **Instalar**. Al terminar, **anota el nombre del servidor** que muestra (por ejemplo `localhost\SQLEXPRESS`).
3. Descarga e instala **SSMS** desde <https://learn.microsoft.com/es-es/sql/ssms/download-sql-server-management-studio-ssms> (pulsa *Descargar SSMS*, ábrelo, **Instalar**, reinicia si lo pide).
4. Abre **SSMS** (tecla Windows → escribe `SSMS`). En la ventana *Conectar con el servidor*:
   - **Tipo de servidor:** Motor de base de datos
   - **Nombre del servidor:** el que anotaste (`localhost\SQLEXPRESS`)
   - **Autenticación:** Autenticación de Windows
   - Marca **Confiar en el certificado del servidor** (en *Opciones* o en la ventana de conexión) y pulsa **Conectar**.
5. Si ves el servidor en el panel izquierdo (*Explorador de objetos*), todo está bien.

### A3. Instalar Power BI Desktop
Búscalo en la **Microsoft Store** como *Power BI Desktop* y pulsa **Obtener**.

### A4. Descargar el proyecto
1. Entra al repositorio en GitHub, pulsa el botón verde **Code → Download ZIP**.
2. Guarda el ZIP, haz clic derecho → **Extraer todo**. Elige una carpeta fácil, por ejemplo `C:\proyecto`.
3. Dentro verás las carpetas `bigdata`, `scripts`, `datos`, `Dashboard`, `evidencias`.

### A5. Crear la cuenta de Databricks (solo para Big Data)
1. Entra a <https://www.databricks.com/learn/free-edition> y pulsa **Sign up for Free Edition**.
2. Regístrate con tu correo (o Google) y confirma el correo.
3. Al entrar verás el espacio de trabajo (*Workspace*). No necesitas tarjeta de crédito.

---

## Parte B. Preparar los datos (una sola vez)

Se hace de la forma indicada en el README principal, **Pasos 1 a 7** (descomprimir Excel → `01_preparar_datos.py` → `02_crear_y_cargar_base_datos.sql`). Al final debes tener:
- el archivo `datos/datos_listos.csv` (92 816 registros), y
- la base de datos `DW_PreciosDigemid` en SSMS.

### B1. Crear los datos sintéticos (para los experimentos de volumen)
1. Abre la carpeta del proyecto en el Explorador de Windows.
2. En la barra de direcciones (arriba, donde sale la ruta) escribe `powershell` y pulsa Enter. Se abre una ventana negra o azul ubicada **dentro de la carpeta del proyecto**.
3. Copia y pega **una línea a la vez**, pulsando Enter, y espera a que termine (la última tarda ~1 minuto):
```
py scripts/generar_sinteticos.py datos/datos_listos.csv 100000 sinteticos_100k.csv
py scripts/generar_sinteticos.py datos/datos_listos.csv 500000 sinteticos_500k.csv
py scripts/generar_sinteticos.py datos/datos_listos.csv 1000000 sinteticos_1m.csv
```
4. Al terminar cada una verás una tabla de **validación** (real vs. sintético). Aparecen 3 archivos nuevos en la carpeta.
5. Copia `sinteticos_1m.csv` a `C:\datos\` (crea la carpeta `datos` en `C:\` si no existe). Lo usan los experimentos de SQL Server.

---

## Parte C. Experimentos de BI (SQL Server)

**Antes de medir en SSMS:** apaga el plan de ejecución (menú **Consulta → Incluir plan de ejecución real** debe estar **sin marca**; atajo `Ctrl + M`). Si está activo, suma tiempo y la medición sale más lenta de lo real. Tampoco actives *Statistics Time/IO* durante la medición.

### C1. E-BI-1: con índice frente a sin índice (`scripts/EXP_BI_ingrid_indice.sql`)
**Qué se compara:** el tiempo de dos consultas sobre una tabla de 1 000 000 de filas, primero sin índice y luego con índice.

1. En SSMS: **Archivo → Abrir → Archivo…** y elige `scripts/EXP_BI_ingrid_indice.sql`.
2. Selecciona **solo el bloque PASO 1** (con el mouse, desde `USE DW_PreciosDigemid;` hasta el último `GO` de ese paso) y pulsa **Ejecutar** (botón ▶ o tecla `F5`). Crea la tabla `HECHO_PRECIO_1M`. En la pestaña *Resultados* debe aparecer `1000000`.
3. Selecciona el **bloque PASO 2** y ejecútalo (por defecto mide la fase `'sin_indice'`). Tarda unos segundos.
4. Quita el comentario (`--`) de la línea `CREATE NONCLUSTERED INDEX IX_1M_Producto ...` del PASO 3, selecciónala y ejecútala. Esto crea el índice.
5. En el PASO 2 cambia `'sin_indice'` por `'con_indice'` y ejecútalo otra vez.
6. Ejecuta el **PASO 4**: muestra la tabla resumen con las medianas. Las medidas guardadas son microsegundos (`us`); divide entre 1 000 para obtener milisegundos.
7. **Qué debes ver:** la consulta de filtro (Q1) baja de decenas de milisegundos a menos de 1 ms; la consulta agrupada (Q2) mejora aproximadamente 2 veces.
8. Opcional: el PASO 5 muestra las lecturas lógicas y el plan de ejecución (para esto sí activa `Ctrl + M`, pero **solo después** de haber terminado las mediciones).
9. Para dejar la base limpia ejecuta el PASO 6 (`DROP INDEX ...`).

### C2. E-BI-2: carga masiva con `BULK INSERT` (`scripts/EXP_BI_ingrid_carga.sql`)
**Qué se compara:** cargar 1 000 000 de filas desde un CSV con y sin la opción `TABLOCK` y con lotes de 10 000 y de 100 000 filas.

1. Comprueba que existe `C:\datos\sinteticos_1m.csv` (paso B1.5). Si no, el error será *"Cannot bulk load… file does not exist"* (ver Preguntas frecuentes).
2. En SSMS abre `scripts/EXP_BI_ingrid_carga.sql`.
3. Ejecuta, en este orden y **bloque por bloque** (seleccionar → F5):
   1. Consulta de **entorno** (muestra tu versión de SQL Server y CPU; guárdala como captura).
   2. Creación de la base `ExpCarga` y de las tablas.
   3. Creación del procedimiento `sp_prueba_carga`.
   4. Prueba rápida (*smoke test*) con una sola carga; debe decir que cargó 1 000 000 de filas.
   5. **Bloque del experimento:** hace 4 calentamientos y luego 3 rondas de las 4 configuraciones. **Tarda varios minutos: no cierres SSMS.**
   6. Consulta de **detalle** (todas las corridas) y consulta de **resumen** (medianas).
4. **Qué debes ver:** `TABLOCK` con lote de 100 000 es la configuración más rápida (aprox. 1,3 veces) y usa mucho menos registro de transacciones (`log_usado_mb`).

### C3. Demás experimentos de BI
Funcionan igual: abres el script en SSMS, lo corres por bloques y lees el resumen con las medianas. El comentario del inicio de cada script dice qué mide:
- `scripts/Samuel_EXP_BI.sql` y `scripts/Samuel_EXP_BI_dev.sql`: paralelismo (`MAXDOP`).
- `scripts/EXP_BI_gonzalo_volumen.sql`: volumen de registros (pendiente de subir).
- Steve: abre `Dashboard/experimentos/dashboard_DirectQuery.pbix` en Power BI Desktop y mide con **Optimizar → Analizador de rendimiento → Iniciar grabación → cambiar un filtro → Detener**.

---

## Parte D. Experimentos de Big Data (Databricks)

### D1. Preparar Databricks (una sola vez)
1. Entra a tu espacio de Databricks.
2. **Importar los notebooks:** menú izquierdo **Workspace** → botón **⋮** (o *Create*) → **Import** → arrastra los `.ipynb` de la carpeta `bigdata/` (y de `bigdata/experimentos/`). Se importan uno por uno o todos a la vez.
3. **Ejecutar `00_configuracion.ipynb`:** ábrelo, arriba a la derecha elige **Connect → Serverless**, y pulsa **Run all**. Crea el esquema `ef_precios_medicamentos` y el volume `datos`.
4. **Subir los datos:** menú **Catalog** → **workspace** → **ef_precios_medicamentos** → **datos** → botón **Upload to this volume**, y sube `datos_listos.csv`, `sinteticos_100k.csv`, `sinteticos_500k.csv` y `sinteticos_1m.csv`. El de 1M tarda más.
5. Ejecuta `01_carga_eda.ipynb` (Connect → Serverless → Run all) para dejar listas las tablas Bronze, Silver y Gold.

### D2. Cómo ejecutar un notebook de experimento
1. Abre el notebook (por ejemplo `EF_exp_ingrid.ipynb`) y conéctalo a **Serverless**.
2. Ejecuta **celda por celda** de arriba hacia abajo: selecciona la celda y pulsa `Shift + Enter` (o ▶). **Espera a que termine** antes de pasar a la siguiente (aparece una marca verde y el tiempo).
3. Cada notebook usa una función `medir()` que hace **1 calentamiento (no se guarda) y 3 repeticiones**, y reporta la **mediana**.
4. La penúltima celda muestra la tabla de resultados; esa tabla es la evidencia (tómale captura).
5. **Query Profile (opcional, evidencia):** debajo de la celda, en el texto "Ran in…" pulsa **See performance → View query profile**. Muestra *Time spent*, *Memory peak* y *Rows*.

### D3. E-BD-1: volumen de datos (`EF_exp_ingrid.ipynb`)
Compara lectura, filtro y agrupaciones con 100k, 500k y 1M de filas. **Requiere** haber subido los 4 archivos CSV (D1.4). **Qué debes ver:** al multiplicar los datos por 10 el tiempo crece menos de 10 veces (crece menos que el volumen).

### D4. E-BD-2: tipo de operación (`EF_exp_ingrid_operaciones.ipynb`)
Ejecuta 10 operaciones sobre el dataset de 1M (lectura, transformaciones *narrow* y *wide*, resumen y escritura Delta) y guarda los tiempos en la tabla `exp_resultados`/`exp_operaciones_resultados`. **Requiere** `sinteticos_1m.csv` en el volume. Las tablas nuevas se crean en el esquema `default`; si una celda no encuentra una tabla, escríbela con su nombre completo `workspace.ef_precios_medicamentos.<tabla>`.

### D5. Demás experimentos de Big Data
- `EF_exp_samuel.ipynb`: número de particiones (1 a 32) con 1M de filas.
- `EF_exp_gonzalo.ipynb`: CSV frente a Parquet (pendiente de subir).
- `EF_exp_Steve.ipynb`: `inferSchema` frente a esquema explícito.

Todos se ejecutan igual que en D2.

---

## Parte E. Cómo comprobar que tu resultado es correcto

Los tiempos exactos cambian de un computador a otro (CPU, memoria, versión de SQL Server). Lo que debería repetirse es la tendencia:

| Experimento | Tendencia esperada |
|---|---|
| E-BI-1 | El índice acelera mucho la consulta de filtro y duplica la agrupada. |
| E-BI-2 | `TABLOCK` + lote de 100 000 es lo más rápido y usa menos registro de transacciones. |
| E-BD-1 | El tiempo crece menos que el volumen. |
| E-BD-2 | Escritura Delta y lectura del CSV son las operaciones más costosas. |

También puedes comparar con las capturas de la carpeta `evidencias/`.
