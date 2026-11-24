SELECT CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(30)) AS Version,
       CAST(SERVERPROPERTY('Edition') AS VARCHAR(60)) AS Edicion,
       @@SERVERNAME AS Instancia;
SELECT cpu_count AS cpu_logicos FROM sys.dm_os_sys_info;
GO

USE master;
GO
IF DB_ID('ExpCarga') IS NULL CREATE DATABASE ExpCarga;
GO
ALTER DATABASE ExpCarga SET RECOVERY SIMPLE;
GO
USE ExpCarga;
GO
IF OBJECT_ID('dbo.sinteticos') IS NOT NULL DROP TABLE dbo.sinteticos;
CREATE TABLE dbo.sinteticos (
    codigo_producto       FLOAT NULL,
    nombre_comercial      NVARCHAR(400) NULL,
    concentracion         NVARCHAR(400) NULL,
    forma_farmaceutica    NVARCHAR(400) NULL,
    presentacion          NVARCHAR(600) NULL,
    registro_sanitario    NVARCHAR(200) NULL,
    ifa                   NVARCHAR(MAX) NULL,
    titular               NVARCHAR(400) NULL,
    fabricante            NVARCHAR(600) NULL,
    pais                  NVARCHAR(200) NULL,
    clasificacion         NVARCHAR(100) NULL,
    n_establecimientos    FLOAT NULL,
    precio_media          FLOAT NULL,
    precio_mediana        FLOAT NULL,
    precio_moda           FLOAT NULL,
    periodo               VARCHAR(20) NULL,
    mes                   INT NULL,
    nombre_mes            NVARCHAR(40) NULL,
    trimestre             INT NULL,
    anio                  INT NULL,
    variacion_mensual_pct FLOAT NULL
);
IF OBJECT_ID('dbo.resultados_carga') IS NOT NULL DROP TABLE dbo.resultados_carga;
CREATE TABLE dbo.resultados_carga (
    id INT IDENTITY PRIMARY KEY,
    corrida INT,                    
    tablock VARCHAR(12), batchsize INT,
    filas BIGINT, duracion_ms INT, log_usado_mb DECIMAL(18,2),
    fecha DATETIME2 DEFAULT SYSDATETIME()
);
GO
CREATE OR ALTER PROCEDURE dbo.sp_prueba_carga
    @ruta NVARCHAR(400), @tablock BIT, @batchsize INT, @corrida INT
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dbo.sinteticos;
    CHECKPOINT;
    DECLARE @sql NVARCHAR(MAX) = N'BULK INSERT dbo.sinteticos FROM ''' + @ruta + N'''
        WITH (FORMAT = ''CSV'', FIELDQUOTE = ''"'', FIELDTERMINATOR = '','',
              ROWTERMINATOR = ''0x0a'', FIRSTROW = 2, CODEPAGE = ''65001'', KEEPNULLS,
              BATCHSIZE = ' + CAST(@batchsize AS NVARCHAR(20))
        + CASE WHEN @tablock = 1 THEN N', TABLOCK' ELSE N'' END + N');';
    DECLARE @l0 DECIMAL(18,2), @l1 DECIMAL(18,2);
    SELECT @l0 = used_log_space_in_bytes / 1048576.0 FROM sys.dm_db_log_space_usage;
    DECLARE @t0 DATETIME2 = SYSDATETIME();
    EXEC sys.sp_executesql @sql;
    DECLARE @ms INT = DATEDIFF(MILLISECOND, @t0, SYSDATETIME());
    SELECT @l1 = used_log_space_in_bytes / 1048576.0 FROM sys.dm_db_log_space_usage;
    INSERT dbo.resultados_carga (corrida, tablock, batchsize, filas, duracion_ms, log_usado_mb)
    SELECT @corrida, CASE WHEN @tablock = 1 THEN 'TABLOCK' ELSE 'SIN TABLOCK' END, @batchsize,
           (SELECT COUNT_BIG(*) FROM dbo.sinteticos), @ms, @l1 - @l0;
    PRINT CONCAT(CASE WHEN @corrida = 0 THEN 'CALENTAMIENTO' ELSE CONCAT('Ronda ', @corrida) END,
                 ' | ', CASE WHEN @tablock = 1 THEN 'TABLOCK' ELSE 'SIN TABLOCK' END,
                 ' | batch ', @batchsize, ' | ', @ms, ' ms | log ', @l1 - @l0, ' MB');
END
GO


USE ExpCarga;
GO
DELETE FROM dbo.resultados_carga;
GO
DECLARE @ruta NVARCHAR(400) = N'C:\datos\sinteticos_1m.csv';

EXEC dbo.sp_prueba_carga @ruta, 0, 10000,  0;  
EXEC dbo.sp_prueba_carga @ruta, 1, 10000,  0;
EXEC dbo.sp_prueba_carga @ruta, 0, 100000, 0;
EXEC dbo.sp_prueba_carga @ruta, 1, 100000, 0;

DECLARE @r INT = 1;
WHILE @r <= 3
BEGIN
    EXEC dbo.sp_prueba_carga @ruta, 0, 10000,  @r; 
    EXEC dbo.sp_prueba_carga @ruta, 1, 10000,  @r;  
    EXEC dbo.sp_prueba_carga @ruta, 0, 100000, @r;   
    EXEC dbo.sp_prueba_carga @ruta, 1, 100000, @r;
    SET @r += 1;
END

TRUNCATE TABLE dbo.sinteticos;
GO


SELECT id, corrida, tablock, batchsize, filas, duracion_ms, log_usado_mb
FROM dbo.resultados_carga
ORDER BY tablock, batchsize, corrida;
GO

WITH r AS (
    SELECT tablock, batchsize, COUNT(*) AS repeticiones,
           MIN(duracion_ms) AS min_ms, AVG(duracion_ms) AS prom_ms,
           SUM(duracion_ms) - MIN(duracion_ms) - MAX(duracion_ms) AS mediana_ms,
           MAX(duracion_ms) AS max_ms, AVG(log_usado_mb) AS log_prom_mb
    FROM dbo.resultados_carga WHERE corrida > 0
    GROUP BY tablock, batchsize)
SELECT tablock, batchsize, repeticiones, min_ms, prom_ms, mediana_ms, max_ms,
       ROUND(log_prom_mb, 2) AS log_prom_mb,
       CAST(1000000.0 / (mediana_ms / 1000.0) AS INT) AS filas_por_segundo,
       ROUND(CAST(FIRST_VALUE(mediana_ms) OVER (ORDER BY tablock, batchsize) AS FLOAT) / mediana_ms, 2) AS aceleracion_vs_base
FROM r ORDER BY tablock DESC, batchsize;
GO
