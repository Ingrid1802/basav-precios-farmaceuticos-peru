# basav-precios-farmaceuticos-peru

Proyecto final de Base de Datos Avanzadas y Big Data — Análisis de Inteligencia de Negocios (BI) sobre precios de productos farmacéuticos en Perú, usando los datos públicos del Observatorio Peruano de Productos Farmacéuticos (DIGEMID).

El proyecto consolida los precios reportados mensualmente por DIGEMID (enero a junio de 2026), los organiza en un modelo dimensional en SQL Server, y los visualiza en un dashboard de Power BI que permite comparar precios entre productos, laboratorios, y entre medicamentos de marca y genéricos.

## Estructura del repositorio

```
scripts/      -> Scripts de Python y SQL para preparar y cargar los datos
datos/        -> Archivos Excel originales de DIGEMID y el CSV ya procesado
evidencias/   -> Diagramas y capturas de pantalla del proyecto
README.md     -> Este archivo, con las instrucciones de instalación
```

## Dependencias

- Windows con Python 3.14.7 (no requiere instalar bibliotecas adicionales; el script usa solo la librería estándar de Python).
- SQL Server 2022 (edición Express).
- SQL Server Management Studio (SSMS).
- Power BI Desktop.

## Cómo replicar el proyecto, paso a paso

### 1. Descomprimir los archivos del proyecto

Descomprimir el archivo `datos/EXCEL-BASE DE DATOS.zip`, que contiene los seis archivos Excel originales de DIGEMID (`MTC 202601.xlsx` a `MTC 202606.xlsx`).

### 2. Preparar los datos

Copiar el archivo `scripts/01_preparar_datos.py` dentro de la misma carpeta donde quedó descomprimida `EXCEL-BASE DE DATOS`. Ejecutarlo con doble clic y esperar a que finalice. Al terminar, presionar Enter para cerrar la ventana. El script genera el archivo `datos_listos.csv` con 92,816 registros.

### 3. Copiar la ruta de los datos preparados

Localizar el archivo `datos_listos.csv` recién generado y copiar la ruta de la carpeta que lo contiene, usando la barra de direcciones del Explorador de Windows.

### 4. Abrir el script SQL y conectarse a SQL Server

Abrir SQL Server Management Studio (SSMS). En la ventana de conexión, ingresar el nombre del servidor y elegir el método de autenticación (Windows o SQL Server, según la instalación). Después de conectarse, abrir el archivo `scripts/02_crear_y_cargar_base_datos.sql`.

### 5. Configurar la ruta del archivo CSV

Dentro del script, buscar la línea:

```sql
FROM 'CAMBIAR_RUTA\datos_listos.csv'
```

Reemplazar `CAMBIAR_RUTA` por la ruta copiada en el paso 3.

### 6. Crear y cargar la base de datos

Ejecutar el script completo con F5. El proceso crea la base de datos `DW_PreciosDigemid`, con las cinco tablas de dimensión (tiempo, producto, laboratorio, clasificación, país de origen) y la tabla de hechos, y carga los 92,816 registros.

### 7. Conectar Power BI con SQL Server

Abrir Power BI Desktop → Inicio → Obtener datos → SQL Server. Ingresar el nombre del servidor (el mismo usado en el paso 4) y el nombre de la base de datos: `DW_PreciosDigemid`. Elegir el modo de conexión "Importar", y seleccionar las tablas `HECHO_PRECIO`, `DIM_TIEMPO`, `DIM_PRODUCTO`, `DIM_LABORATORIO`, `DIM_CLASIFICACION` y `DIM_PAIS_ORIGEN`.

### 8. Verificar la conexión

Confirmar que las seis tablas aparecen en el panel de datos de Power BI Desktop, listas para construir el dashboard.

## Equipo

- Preparación de datos y ETL (scripts): Samuel Gutierrez, Ingrid Aybar
- Base de datos: Samuel Gutierrez, Ingrid Aybar
- Dashboard de Power BI: Cristofer Buleje , Samuel Gutierrez, Ingrid Aybar
- Documentación: todo el equipo (Ingrid A., Samuel G. , Cristofer B., Gonzalo E., Steve T. )
- Repositorio (GitHub): Ingrid Aybar, Samuel Gutierre
## Fuente de datos

Dirección General de Medicamentos, Insumos y Drogas (DIGEMID). *Indicador de precios de productos farmacéuticos*. Ministerio de Salud del Perú.