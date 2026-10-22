# basav-precios-farmaceuticos-peru

Proyecto final del curso **Base de Datos Avanzadas y Big Data** — Análisis de Inteligencia de Negocios (BI) sobre precios de productos farmacéuticos en Perú, usando los datos públicos del **Observatorio Peruano de Productos Farmacéuticos (DIGEMID)**.

El proyecto consolida los precios reportados mensualmente por DIGEMID (enero a junio de 2026), los organiza en un modelo dimensional en SQL Server, y los visualiza en un dashboard de Power BI que permite comparar precios entre productos, laboratorios, y entre medicamentos de marca y genéricos.

---

## Tabla de contenidos

- [Estructura del repositorio](#estructura-del-repositorio)
- [Dependencias](#dependencias)
- [Cómo replicar el proyecto, paso a paso](#cómo-replicar-el-proyecto-paso-a-paso)
- [Preguntas frecuentes y solución de problemas](#preguntas-frecuentes-y-solución-de-problemas)
- [Equipo](#equipo)
- [Fuente de datos](#fuente-de-datos)

---

## Estructura del repositorio

```
basav-precios-farmaceuticos-peru/
│
├── scripts/
│   ├── 01_preparar_datos.py              Extrae y limpia los datos (no requiere instalar nada)
│   ├── 02_crear_y_cargar_base_datos.sql  Crea la base de datos y la carga con los datos limpios
│   └── pruebas/                          Scripts de validación y del experimento de rendimiento
│
├── datos/
│   ├── EXCEL-BASE DE DATOS.zip           Los 6 archivos Excel originales de DIGEMID
│   └── datos_listos.csv                  El archivo ya limpio, generado por el script de Python
│
├── dashboard/
│   └── (archivo .pbix del dashboard de Power BI)
│
├── evidencias/
│   └── (pendiente: capturas y diagramas se agregarán en la siguiente entrega)
│
└── README.md                             Este archivo
```

---

## Dependencias

Antes de empezar, asegúrate de tener instalado en tu computadora (con Windows):

| Programa | Para qué sirve | Dónde descargarlo |
|---|---|---|
| **Python 3.14.7** (o cualquier versión 3.x reciente) | Correr el script que limpia los datos | [python.org/downloads](https://www.python.org/downloads/) |
| **SQL Server 2022 Express** | Guardar los datos en una base de datos | [Microsoft SQL Server Downloads](https://www.microsoft.com/es-pe/sql-server/sql-server-downloads) |
| **SQL Server Management Studio (SSMS)** | Abrir y ejecutar el script de SQL | [Descarga de SSMS](https://learn.microsoft.com/es-es/sql/ssms/download-sql-server-management-studio-ssms) |
| **Power BI Desktop** | Ver el dashboard final | [Microsoft Store o powerbi.microsoft.com](https://www.microsoft.com/es-pe/power-platform/products/power-bi/downloads) |

---

## Cómo replicar el proyecto, paso a paso

Sigue los pasos en orden, sin saltarte ninguno.

### Paso 1: Descargar el repositorio completo

1. En la página de este repositorio en GitHub, haz clic en el botón verde **"Code"**.
2. Haz clic en **"Download ZIP"**.
3. Ve a tu carpeta de Descargas, haz clic derecho sobre el archivo ZIP descargado y elige **"Extraer todo..."**.
4. Elige una carpeta fácil de encontrar (por ejemplo, el Escritorio) y extrae ahí.

### Paso 2: Descomprimir los archivos Excel originales

1. Entra a la carpeta que acabas de extraer, y luego a la subcarpeta `datos`.
2. Ahí vas a ver un archivo llamado `EXCEL-BASE DE DATOS.zip`.
3. Haz clic derecho sobre él → **"Extraer todo..."** → Extraer en esa misma carpeta.
4. Debería aparecer una carpeta llamada **`EXCEL-BASE DE DATOS`**, con 6 archivos Excel adentro (`MTC 202601.xlsx` hasta `MTC 202606.xlsx`).

### Paso 3: Preparar los datos con el script de Python

1. Ve a la carpeta `scripts` y copia el archivo `01_preparar_datos.py`.
2. Pégalo **dentro** de la carpeta `EXCEL-BASE DE DATOS` (debe quedar en el mismo lugar que los 6 Excel, no afuera).
3. Haz doble clic sobre `01_preparar_datos.py`.
4. Se va a abrir una ventana negra (la consola de Windows). **No la cierres.** Vas a ver mensajes como:
   ```
   Carpeta de Excel: ...
   Se encontraron 6 archivos:
     Leyendo 2026-01  ->  MTC 202601.xlsx ...
        filas de datos: 15266
   ...
   Listo. Se genero el archivo: datos_listos.csv
   Total de registros: 92816
   ```
5. Al final, la ventana te pide presionar **Enter** para cerrarse. Puedes hacerlo una vez que confirmes que no hubo errores.
6. Dentro de la carpeta `EXCEL-BASE DE DATOS` debería haber aparecido un nuevo archivo: **`datos_listos.csv`**.

**Si te sale un mensaje de ERROR en la consola:** significa que algo no se pudo procesar (por ejemplo, falta algún Excel, o el CSV ya estaba abierto en Excel). Lee el mensaje de error, que explica qué pasó, ciérralo si está abierto en otro programa, y vuelve a intentar.

### Paso 4: Copiar la ruta de los datos preparados

1. Dentro de la carpeta `EXCEL-BASE DE DATOS`, haz clic una vez sobre la barra de direcciones de arriba (donde se ve la ruta de la carpeta).
2. Se va a seleccionar todo el texto de la ruta. Cópialo (Ctrl+C). Guárdalo en algún lugar (por ejemplo, pégalo en el Bloc de notas) para usarlo en el siguiente paso.

### Paso 5: Abrir SQL Server Management Studio y conectarte

1. Abre **SQL Server Management Studio (SSMS)**.
2. Te va a aparecer una ventana llamada "Conectar al servidor". Tienes 2 formas de conectarte, según cómo esté configurado tu SQL Server:
   - **Autenticación de Windows** (la más común en instalaciones personales): deja la opción tal como está y haz clic en **"Conectar"**.
   - **Autenticación de SQL Server**: si tu instalación te pide usuario y contraseña, selecciona esa opción e ingresa tus credenciales.
3. Una vez conectado, ve a **Archivo → Abrir → Archivo...**, y busca `scripts/02_crear_y_cargar_base_datos.sql` dentro de la carpeta que descargaste.

### Paso 6: Configurar la ruta del archivo CSV dentro del script

1. Con el script ya abierto en SSMS, usa **Ctrl+F** (Buscar) y escribe: `CAMBIAR_RUTA`
2. Vas a encontrar esta línea:
   ```sql
   FROM 'CAMBIAR_RUTA\datos_listos.csv'
   ```
3. Reemplaza únicamente la palabra `CAMBIAR_RUTA` por la ruta que copiaste en el Paso 4, dejando `\datos_listos.csv` al final. Por ejemplo, si tu ruta era `C:\Users\Juan\Desktop\basav-precios-farmaceuticos-peru\datos\EXCEL-BASE DE DATOS`, la línea debería quedar así:
   ```sql
   FROM 'C:\Users\Juan\Desktop\basav-precios-farmaceuticos-peru\datos\EXCEL-BASE DE DATOS\datos_listos.csv'
   ```

### Paso 7: Ejecutar el script y crear la base de datos

1. Con el cursor en cualquier parte del script, presiona la tecla **F5** (o el botón "Ejecutar" en la barra de herramientas de SSMS).
2. El script va a tardar unos segundos. Observa el panel de **"Mensajes"**, abajo. Deberías ver, en orden:
   ```
   Base de datos y tablas creadas.
   Datos cargados a STG_PRECIOS.
   Dimensiones pobladas.
   Tabla de hechos poblada.
   ```
3. Después de eso, van a aparecer 2 tablas de resultados en el panel de **"Resultados"**: una con el conteo de filas de cada tabla (deberías ver `HECHO_PRECIO` con 92,816 filas), y otra con 20 registros de ejemplo, ya combinados.

**El script tiene protecciones automáticas:** si algo sale mal (por ejemplo, la ruta del CSV está mal escrita y no carga ningún dato), el script se detiene solo y te muestra un mensaje de error en rojo explicando qué pasó, en vez de seguir con datos incompletos.

**Si necesitas repetir este paso** (por ejemplo, te equivocaste en algo), no hay problema: el script siempre borra la base de datos anterior y la vuelve a crear desde cero al principio, así que puedes ejecutarlo las veces que quieras sin preocuparte por duplicados.

### Paso 8: Conectar Power BI a la base de datos

1. Abre **Power BI Desktop**.
2. Ve a **Inicio → Obtener datos → SQL Server**.
3. En la ventana que aparece:
   - **Servidor:** escribe el mismo nombre de servidor que usaste para conectarte en SSMS (Paso 5). Si no lo recuerdas, ábrelo de nuevo en SSMS y fíjate en el campo "Nombre del servidor" de la ventana de conexión.
   - **Base de datos:** escribe `DW_PreciosDigemid`
4. Haz clic en **"Aceptar"**.
5. Si te pide el método de autenticación, elige el mismo que usaste en el Paso 5 (Windows o SQL Server) y confirma.
6. Se va a abrir el **"Navegador"**, con la lista de tablas disponibles. Marca las casillas de estas 6 tablas:
   - `HECHO_PRECIO`
   - `DIM_TIEMPO`
   - `DIM_PRODUCTO`
   - `DIM_LABORATORIO`
   - `DIM_CLASIFICACION`
   - `DIM_PAIS_ORIGEN`
7. Elige el modo de conexión **"Importar"** y haz clic en **"Cargar"**.

### Paso 9: Verificar que todo quedó bien

1. En el panel derecho de Power BI (**"Datos"**), deberías ver las 6 tablas que acabas de cargar, cada una con sus columnas.
2. Si las ves todas, ¡el proceso está completo! Ya puedes construir o abrir el dashboard.

---

## Preguntas frecuentes y solución de problemas

**"Al correr el Python me sale 'No encontre los Excel'."**
Verifica que el script `01_preparar_datos.py` esté **dentro** de la carpeta `EXCEL-BASE DE DATOS`, al mismo nivel que los 6 archivos `.xlsx`, no en la carpeta de afuera.

**"Al correr el SQL me sale 'el BULK INSERT no cargo filas'."**
Revisa que la ruta que pusiste en el Paso 6 sea exactamente correcta, con `\datos_listos.csv` al final, y que el archivo realmente exista ahí.

**"No sé cuál es el nombre de mi servidor de SQL Server."**
Ábrelo desde SSMS: al abrir el programa, la ventana de conexión ya trae escrito el nombre correcto en el campo "Nombre del servidor" (frecuentemente es `localhost` o `NOMBRE-DE-TU-PC\SQLEXPRESS`).

**"¿Por qué el script de Python no usa pandas?"**
A propósito: así el script corre en cualquier computadora con Python instalado, sin tener que instalar ninguna librería adicional, lo cual reduce el riesgo de que algo falle durante una demostración en vivo.

---

## Equipo

| Integrante | Aporte |
|---|---|
| Ingrid Aybar | Preparación de datos y ETL, base de datos, dashboard, documentación, repositorio |
| Samuel Gutiérrez | Preparación de datos y ETL, base de datos, dashboard, documentación, repositorio |
| Cristofer Buleje | Dashboard de Power BI, documentación |
| Alvaro Gonzalo Espinoza | Experimento de rendimiento, resultados, documentación |
| Steve Tirado |  Preparación de datos y ETL y Documentación |

---

## Fuente de datos

Dirección General de Medicamentos, Insumos y Drogas (DIGEMID). *Indicador de precios de productos farmacéuticos*. Ministerio de Salud del Perú.
