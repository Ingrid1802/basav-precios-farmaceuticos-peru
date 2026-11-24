/* =====================================================================
   EXPERIMENTO BI - Gonzalo: volumen de registros (SQL Server)
   Base: DW_PreciosDigemid
   Tablas: HECHO_PRECIO_PRUEBA (100 000), HECHO_PRECIO_500K (500 000)
           y HECHO_PRECIO_1M (1 000 000 de filas)
   Variable: numero de filas de la tabla de hechos.
   Control: misma consulta (COUNT(*) y AVG(Precio_Media)), OPTION (MAXDOP 1),
            1 calentamiento descartado, 3 repeticiones y mediana.
   Medicion: SIN SET STATISTICS TIME/IO y asignando el resultado a variables,
            para que el tiempo no incluya mensajes ni el envio de filas a SSMS.
            Tiempo en microsegundos con DATEDIFF(MICROSECOND, ...).
            Las lecturas logicas se obtienen en una corrida aparte (PASO 5).

   COMO EJECUTARLO EN SSMS
   * Plan de ejecucion DESACTIVADO (Ctrl+M apagado): si esta activo, suma tiempo.
   * Ejecutar cada PASO por separado: seleccionar desde su titulo hasta su
     ultimo GO y presionar F5. Tomar la captura indicada en cada paso.
   * Prerrequisito: haber ejecutado scripts/02_crear_y_cargar_base_datos.sql
     (tabla HECHO_PRECIO con 92 816 filas).
   ===================================================================== */

USE DW_PreciosDigemid;
GO

/* ---------------------------------------------------------------------
   PASO 0. ENTORNO
   Captura: Gonzalo_BI_entorno.png (pestana Resultados)
   --------------------------------------------------------------------- */
SELECT  SERVERPROPERTY('ProductVersion')  AS version_producto,
        SERVERPROPERTY('ProductLevel')    AS nivel,
        SERVERPROPERTY('Edition')         AS edicion,
        @@SERVERNAME                      AS instancia,
        DB_NAME()                         AS base_datos,
        si.cpu_count                      AS cpu_count,
        si.scheduler_count                AS schedulers,
        si.physical_memory_kb / 1024      AS memoria_fisica_mb,
        si.committed_target_kb / 1024     AS memoria_objetivo_sql_mb
FROM sys.dm_os_sys_info AS si;

SELECT @@VERSION AS version_completa;
GO

/* ---------------------------------------------------------------------
   PASO 1. CREACION DE LAS TABLAS DE PRUEBA
   Metodo del equipo: se replica HECHO_PRECIO (92 816 filas) 11 veces,
   desplazando ID_Producto en cada copia, y se conservan las primeras N filas
   en un orden fijo. Las tres tablas quedan como heap (sin indices).
   --------------------------------------------------------------------- */
SET NOCOUNT ON;

IF OBJECT_ID('dbo.HECHO_PRECIO_PRUEBA') IS NOT NULL DROP TABLE dbo.HECHO_PRECIO_PRUEBA;
IF OBJECT_ID('dbo.HECHO_PRECIO_500K')   IS NOT NULL DROP TABLE dbo.HECHO_PRECIO_500K;
IF OBJECT_ID('dbo.HECHO_PRECIO_1M')     IS NOT NULL DROP TABLE dbo.HECHO_PRECIO_1M;

-- 1 000 000 de filas
SELECT TOP (1000000)
       h.ID_Tiempo, h.ID_Producto + (n.k * 100000) AS ID_Producto,
       h.ID_Laboratorio, h.ID_Clasificacion, h.ID_Pais,
       h.Precio_Media, h.Precio_Mediana, h.Precio_Moda,
       h.N_Establecimientos_Reportantes, h.Variacion_Mensual_Pct
INTO dbo.HECHO_PRECIO_1M
FROM dbo.HECHO_PRECIO AS h
CROSS JOIN (SELECT TOP (11) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) - 1 AS k
            FROM sys.all_objects) AS n
ORDER BY n.k, h.ID_Tiempo, h.ID_Producto;

-- 500 000 filas
SELECT TOP (500000)
       h.ID_Tiempo, h.ID_Producto + (n.k * 100000) AS ID_Producto,
       h.ID_Laboratorio, h.ID_Clasificacion, h.ID_Pais,
       h.Precio_Media, h.Precio_Mediana, h.Precio_Moda,
       h.N_Establecimientos_Reportantes, h.Variacion_Mensual_Pct
INTO dbo.HECHO_PRECIO_500K
FROM dbo.HECHO_PRECIO AS h
CROSS JOIN (SELECT TOP (11) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) - 1 AS k
            FROM sys.all_objects) AS n
ORDER BY n.k, h.ID_Tiempo, h.ID_Producto;

-- 100 000 filas
SELECT TOP (100000)
       h.ID_Tiempo, h.ID_Producto + (n.k * 100000) AS ID_Producto,
       h.ID_Laboratorio, h.ID_Clasificacion, h.ID_Pais,
       h.Precio_Media, h.Precio_Mediana, h.Precio_Moda,
       h.N_Establecimientos_Reportantes, h.Variacion_Mensual_Pct
INTO dbo.HECHO_PRECIO_PRUEBA
FROM dbo.HECHO_PRECIO AS h
CROSS JOIN (SELECT TOP (11) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) - 1 AS k
            FROM sys.all_objects) AS n
ORDER BY n.k, h.ID_Tiempo, h.ID_Producto;
GO

/* ---------------------------------------------------------------------
   PASO 2. VERIFICACION DE LAS TABLAS
   Captura: Gonzalo_BI_tablas.png (pestana Resultados: conteos y sp_spaceused)
   --------------------------------------------------------------------- */
SELECT 'HECHO_PRECIO_PRUEBA' AS tabla, COUNT(*) AS filas FROM dbo.HECHO_PRECIO_PRUEBA
UNION ALL SELECT 'HECHO_PRECIO_500K', COUNT(*) FROM dbo.HECHO_PRECIO_500K
UNION ALL SELECT 'HECHO_PRECIO_1M',   COUNT(*) FROM dbo.HECHO_PRECIO_1M;

EXEC sp_spaceused 'dbo.HECHO_PRECIO_PRUEBA';
EXEC sp_spaceused 'dbo.HECHO_PRECIO_500K';
EXEC sp_spaceused 'dbo.HECHO_PRECIO_1M';
GO

/* ---------------------------------------------------------------------
   PASO 3. MEDICION (sin STATISTICS; resultado asignado a variables)
   Tarda pocos segundos. No muestra nada; los tiempos quedan en
   dbo.EXP_BI_VOLUMEN.
   --------------------------------------------------------------------- */
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
SET NOCOUNT ON;

IF OBJECT_ID('dbo.EXP_BI_VOLUMEN') IS NULL
    CREATE TABLE dbo.EXP_BI_VOLUMEN (escala VARCHAR(10), filas INT, repeticion INT, us BIGINT, fecha DATETIME2(0));
DELETE FROM dbo.EXP_BI_VOLUMEN;

DECLARE @i INT, @t0 DATETIME2(7), @n INT, @prom DECIMAL(18,4);

-- 100 000 filas
SELECT @n = COUNT(*), @prom = AVG(Precio_Media) FROM dbo.HECHO_PRECIO_PRUEBA OPTION (MAXDOP 1);  -- calentamiento
SET @i = 1;
WHILE @i <= 3
BEGIN
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*), @prom = AVG(Precio_Media) FROM dbo.HECHO_PRECIO_PRUEBA OPTION (MAXDOP 1);
    INSERT dbo.EXP_BI_VOLUMEN VALUES ('100k', 100000, @i, DATEDIFF(MICROSECOND, @t0, SYSDATETIME()), SYSDATETIME());
    SET @i += 1;
END;

-- 500 000 filas
SELECT @n = COUNT(*), @prom = AVG(Precio_Media) FROM dbo.HECHO_PRECIO_500K OPTION (MAXDOP 1);    -- calentamiento
SET @i = 1;
WHILE @i <= 3
BEGIN
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*), @prom = AVG(Precio_Media) FROM dbo.HECHO_PRECIO_500K OPTION (MAXDOP 1);
    INSERT dbo.EXP_BI_VOLUMEN VALUES ('500k', 500000, @i, DATEDIFF(MICROSECOND, @t0, SYSDATETIME()), SYSDATETIME());
    SET @i += 1;
END;

-- 1 000 000 de filas
SELECT @n = COUNT(*), @prom = AVG(Precio_Media) FROM dbo.HECHO_PRECIO_1M OPTION (MAXDOP 1);      -- calentamiento
SET @i = 1;
WHILE @i <= 3
BEGIN
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*), @prom = AVG(Precio_Media) FROM dbo.HECHO_PRECIO_1M OPTION (MAXDOP 1);
    INSERT dbo.EXP_BI_VOLUMEN VALUES ('1m', 1000000, @i, DATEDIFF(MICROSECOND, @t0, SYSDATETIME()), SYSDATETIME());
    SET @i += 1;
END;
GO

/* ---------------------------------------------------------------------
   PASO 4. RESULTADOS: repeticiones, mediana y throughput
   Captura: Gonzalo_BI_resultados.png (pestana Resultados)
   Con 3 valores, la mediana es el del medio: suma - minimo - maximo.
   --------------------------------------------------------------------- */
SELECT  escala, filas,
        MAX(CASE WHEN repeticion = 1 THEN us END) AS rep_1_us,
        MAX(CASE WHEN repeticion = 2 THEN us END) AS rep_2_us,
        MAX(CASE WHEN repeticion = 3 THEN us END) AS rep_3_us,
        SUM(us) - MIN(us) - MAX(us)                AS mediana_us,
        CAST((SUM(us) - MIN(us) - MAX(us)) / 1000.0 AS DECIMAL(10,3)) AS mediana_ms,
        CAST(filas / ((SUM(us) - MIN(us) - MAX(us)) / 1000000.0) AS DECIMAL(18,0)) AS filas_por_s,
        MIN(fecha) AS inicio, MAX(fecha) AS fin
FROM dbo.EXP_BI_VOLUMEN
GROUP BY escala, filas
ORDER BY filas;
GO

/* ---------------------------------------------------------------------
   PASO 5. LECTURAS LOGICAS (corrida aparte, no cuenta para el tiempo)
   Captura: Gonzalo_BI_lecturas_logicas.png (pestana Mensajes)
   --------------------------------------------------------------------- */
SET STATISTICS IO ON;
SELECT COUNT(*) AS filas, AVG(Precio_Media) AS precio_promedio FROM dbo.HECHO_PRECIO_PRUEBA OPTION (MAXDOP 1);
SELECT COUNT(*) AS filas, AVG(Precio_Media) AS precio_promedio FROM dbo.HECHO_PRECIO_500K   OPTION (MAXDOP 1);
SELECT COUNT(*) AS filas, AVG(Precio_Media) AS precio_promedio FROM dbo.HECHO_PRECIO_1M     OPTION (MAXDOP 1);
SET STATISTICS IO OFF;
GO
