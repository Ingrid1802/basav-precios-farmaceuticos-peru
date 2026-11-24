/* =====================================================================
   EXPERIMENTO BI - Samuel: PARALELISMO EN SQL SERVER
   Pregunta: cuanto mejora la consulta de agregacion al dejar usar
   varios nucleos (paralelismo por defecto) frente a un solo nucleo
   (OPTION (MAXDOP 1)), con 1 000 000 de filas.

   Tabla: dbo.HECHO_PRECIO_1M (base DW_PreciosDigemid)
   Consulta: la misma del equipo (EXP-01): COUNT_BIG(*) y AVG(Precio_Media)
     Caso A: con OPTION (MAXDOP 1)  -> un solo nucleo
     Caso B: sin OPTION              -> paralelismo por defecto
   Control: SET STATISTICS TIME ON y SET STATISTICS IO ON, 1 calentamiento
   que NO se cuenta y 3 repeticiones por caso; se reporta la mediana.

   COMO USARLO EN SQL SERVER MANAGEMENT STUDIO
   1. Ejecuta el PASO 0 completo (selecciona hasta su GO y presiona F5).
   2. Activa el plan real UNA vez: Consulta > Incluir plan de ejecucion
      real (Ctrl + M).
   3. Ejecuta cada bloque A0, A1, A2, A3, B0, B1, B2 y B3 POR SEPARADO:
      selecciona desde su comentario hasta su GO y presiona F5.
      En la pestana "Mensajes" anota la linea
         SQL Server Execution Times: CPU time = ... ms, elapsed time = ... ms.
      (la que aparece despues de "Table 'HECHO_PRECIO_1M'..."),
      y las "logical reads" de esa misma linea de Table.
   4. Ejecuta el PASO FINAL 1 (grado de paralelismo usado).
   5. Escribe tus 12 valores en el PASO FINAL 2 y ejecutalo (medianas).
   ===================================================================== */

USE DW_PreciosDigemid;
GO

/* ---------------------------------------------------------------------
   PASO 0. ENTORNO Y DATOS
   Captura: Samuel_BI_entorno.png (pestana Resultados)
   --------------------------------------------------------------------- */
SET NOCOUNT ON;

-- Si la tabla de prueba no existe en esta instancia, se crea copiando
-- HECHO_PRECIO (92 816 filas) 11 veces y conservando 1 000 000 de filas.
-- (La creacion va dentro de EXEC para que SQL Server no marque error
--  "ya existe un objeto" cuando la tabla ya fue creada antes.)
IF OBJECT_ID('dbo.HECHO_PRECIO_1M', 'U') IS NULL
BEGIN
    PRINT 'HECHO_PRECIO_1M no existia: se crea a partir de HECHO_PRECIO.';
    EXEC (N'
    WITH copias AS (
        SELECT TOP (11) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS copia
        FROM sys.all_objects
    )
    SELECT TOP (1000000)
           h.ID_Tiempo, h.ID_Producto, h.ID_Laboratorio, h.ID_Clasificacion, h.ID_Pais,
           h.Precio_Media, h.Precio_Mediana, h.Precio_Moda,
           h.N_Establecimientos_Reportantes, h.Variacion_Mensual_Pct
    INTO dbo.HECHO_PRECIO_1M
    FROM dbo.HECHO_PRECIO AS h
    CROSS JOIN copias AS c
    ORDER BY c.copia, h.ID_Tiempo, h.ID_Producto;');
END
ELSE
    PRINT 'HECHO_PRECIO_1M ya existia: se usa la tabla actual.';

SELECT SERVERPROPERTY('Edition')        AS Edicion,
       SERVERPROPERTY('ProductVersion') AS Version,
       SERVERPROPERTY('ProductLevel')   AS Nivel,
       @@SERVERNAME                     AS Instancia;

SELECT cpu_count       AS procesadores_logicos,
       scheduler_count AS planificadores_SQL
FROM sys.dm_os_sys_info;

SELECT name AS configuracion, value_in_use AS valor
FROM sys.configurations
WHERE name IN ('max degree of parallelism', 'cost threshold for parallelism');

SELECT COUNT_BIG(*) AS filas_HECHO_PRECIO_1M
FROM dbo.HECHO_PRECIO_1M;
GO


/* =====================================================================
   CASO A: OPTION (MAXDOP 1) - un solo nucleo
   ===================================================================== */

/* A0. Calentamiento: NO se cuenta ni se captura */
SET STATISTICS TIME ON; SET STATISTICS IO ON;
SELECT /* EXP_SAMUEL_BI A0 */ COUNT_BIG(*) AS TotalFilas, AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_1M
OPTION (MAXDOP 1);
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
GO

/* A1. Repeticion 1  ->  Captura: Samuel_BI_01.png (pestana Mensajes) */
SET STATISTICS TIME ON; SET STATISTICS IO ON;
SELECT /* EXP_SAMUEL_BI A1 */ COUNT_BIG(*) AS TotalFilas, AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_1M
OPTION (MAXDOP 1);
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
GO

/* A2. Repeticion 2  ->  Captura: Samuel_BI_02.png (pestana Mensajes) */
SET STATISTICS TIME ON; SET STATISTICS IO ON;
SELECT /* EXP_SAMUEL_BI A2 */ COUNT_BIG(*) AS TotalFilas, AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_1M
OPTION (MAXDOP 1);
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
GO

/* A3. Repeticion 3  ->  Captura: Samuel_BI_03.png (pestana Mensajes)
       y Samuel_BI_plan_A.png (pestana Plan de ejecucion) */
SET STATISTICS TIME ON; SET STATISTICS IO ON;
SELECT /* EXP_SAMUEL_BI A3 */ COUNT_BIG(*) AS TotalFilas, AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_1M
OPTION (MAXDOP 1);
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
GO


/* =====================================================================
   CASO B: PARALELISMO POR DEFECTO - sin OPTION
   ===================================================================== */

/* B0. Calentamiento: NO se cuenta ni se captura */
SET STATISTICS TIME ON; SET STATISTICS IO ON;
SELECT /* EXP_SAMUEL_BI B0 */ COUNT_BIG(*) AS TotalFilas, AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_1M;
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
GO

/* B1. Repeticion 1  ->  Captura: Samuel_BI_04.png (pestana Mensajes) */
SET STATISTICS TIME ON; SET STATISTICS IO ON;
SELECT /* EXP_SAMUEL_BI B1 */ COUNT_BIG(*) AS TotalFilas, AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_1M;
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
GO

/* B2. Repeticion 2  ->  Captura: Samuel_BI_05.png (pestana Mensajes) */
SET STATISTICS TIME ON; SET STATISTICS IO ON;
SELECT /* EXP_SAMUEL_BI B2 */ COUNT_BIG(*) AS TotalFilas, AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_1M;
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
GO

/* B3. Repeticion 3  ->  Captura: Samuel_BI_06.png (pestana Mensajes)
       y Samuel_BI_plan_B.png (pestana Plan de ejecucion).
       Si hubo paralelismo, el plan muestra el operador "Parallelism
       (Gather Streams)" y los iconos llevan flechas amarillas. */
SET STATISTICS TIME ON; SET STATISTICS IO ON;
SELECT /* EXP_SAMUEL_BI B3 */ COUNT_BIG(*) AS TotalFilas, AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_1M;
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;
GO


/* ---------------------------------------------------------------------
   PASO FINAL 1. GRADO DE PARALELISMO REALMENTE USADO
   Lee de la cache de SQL Server cuantos hilos uso cada ejecucion.
   grado_paralelismo = 1 significa un solo nucleo (sin paralelismo).
   Captura: Samuel_BI_dop.png (pestana Resultados)
   --------------------------------------------------------------------- */
SET STATISTICS TIME OFF; SET STATISTICS IO OFF;

WITH s AS (
    SELECT SUBSTRING(t.text, qs.statement_start_offset / 2 + 1,
               (CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(t.text)
                     ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2 + 1) AS sentencia,
           qs.last_dop, qs.last_logical_reads, qs.last_execution_time
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
)
SELECT SUBSTRING(sentencia, CHARINDEX('EXP_SAMUEL_BI ', sentencia) + 14, 2) AS ejecucion,
       CASE WHEN sentencia LIKE '%MAXDOP 1%' THEN 'A. MAXDOP 1' ELSE 'B. Paralelismo por defecto' END AS caso,
       last_dop           AS grado_paralelismo,
       last_logical_reads AS lecturas_logicas,
       last_execution_time AS hora_ejecucion
FROM s
WHERE sentencia LIKE '%EXP_SAMUEL_BI [AB][0-3]%'
ORDER BY ejecucion;
GO


/* ---------------------------------------------------------------------
   PASO FINAL 2. TABLA DE RESULTADOS CON MEDIANAS
   (Valores ya registrados de la ejecucion del 22/11/2026 en
    DESKTOP-D36BRCM\SQLEXPRESS, tomados de Samuel_BI_01 a Samuel_BI_06.)
   Reemplaza cada NULL por el valor que anotaste de la pestana Mensajes
   (elapsed time y CPU time en ms) de cada repeticion. No uses los
   calentamientos A0 ni B0.
   Captura: Samuel_BI_resumen.png (pestana Resultados)
   --------------------------------------------------------------------- */
DECLARE @r TABLE (caso VARCHAR(30), repeticion INT, elapsed_ms INT, cpu_ms INT);
INSERT INTO @r (caso, repeticion, elapsed_ms, cpu_ms) VALUES
    ('A. MAXDOP 1',                1, 485, 468),   -- Samuel_BI_01.png
    ('A. MAXDOP 1',                2, 371, 375),   -- Samuel_BI_02.png
    ('A. MAXDOP 1',                3, 369, 375),   -- Samuel_BI_03.png
    ('B. Paralelismo por defecto', 1, 419, 422),   -- Samuel_BI_04.png
    ('B. Paralelismo por defecto', 2, 443, 454),   -- Samuel_BI_05.png
    ('B. Paralelismo por defecto', 3, 413, 375);   -- Samuel_BI_06.png

WITH m AS (
    SELECT caso,
           MAX(CASE WHEN repeticion = 1 THEN elapsed_ms END) AS rep_1_ms,
           MAX(CASE WHEN repeticion = 2 THEN elapsed_ms END) AS rep_2_ms,
           MAX(CASE WHEN repeticion = 3 THEN elapsed_ms END) AS rep_3_ms,
           -- con 3 valores, la mediana es el del medio: suma - minimo - maximo
           SUM(elapsed_ms) - MIN(elapsed_ms) - MAX(elapsed_ms) AS mediana_elapsed_ms,
           SUM(cpu_ms) - MIN(cpu_ms) - MAX(cpu_ms)             AS mediana_cpu_ms
    FROM @r
    GROUP BY caso
)
SELECT m.*,
       CAST(1000000 / NULLIF(m.mediana_elapsed_ms / 1000.0, 0) AS DECIMAL(18, 0)) AS filas_por_s,
       CAST((SELECT mediana_elapsed_ms FROM m WHERE caso LIKE 'A%') * 1.0
            / NULLIF(m.mediana_elapsed_ms, 0) AS DECIMAL(6, 2))                    AS veces_mas_rapido_que_A
FROM m
ORDER BY caso;
GO
