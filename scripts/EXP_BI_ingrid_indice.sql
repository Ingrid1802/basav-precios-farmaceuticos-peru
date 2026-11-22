/* =====================================================================
   EXPERIMENTO BI - Ingrid: indice vs. sin indice (SQL Server)
   Base: DW_PreciosDigemid | Tabla: HECHO_PRECIO_1M (1 000 000 de filas)
   Variable: indice no agrupado IX_1M_Producto sobre (ID_Producto) INCLUDE (Precio_Media)
   Control: mismas consultas, MAXDOP 1, 1 calentamiento descartado, 3 repeticiones, mediana.
   IMPORTANTE: ejecutar con el plan de ejecucion DESACTIVADO (Ctrl+M apagado);
   si esta activo, agrega 25-50 ms por consulta y falsea la medicion.
   Prerrequisito: haber ejecutado scripts/02_crear_y_cargar_base_datos.sql
   ===================================================================== */

/* ---------- PASO 1: crear HECHO_PRECIO_1M (replica HECHO_PRECIO 11 veces) ---------- */
USE DW_PreciosDigemid;
GO
IF OBJECT_ID('dbo.HECHO_PRECIO_1M') IS NOT NULL DROP TABLE dbo.HECHO_PRECIO_1M;
SELECT TOP (1000000)
       h.ID_Tiempo, h.ID_Producto + (n.k * 100000) AS ID_Producto,
       h.ID_Laboratorio, h.ID_Clasificacion, h.ID_Pais,
       h.Precio_Media, h.Precio_Mediana, h.Precio_Moda,
       h.N_Establecimientos_Reportantes, h.Variacion_Mensual_Pct
INTO dbo.HECHO_PRECIO_1M
FROM dbo.HECHO_PRECIO h
CROSS JOIN (SELECT TOP 11 ROW_NUMBER() OVER (ORDER BY (SELECT 1)) - 1 AS k
            FROM sys.all_objects) n
ORDER BY n.k, h.ID_Tiempo;
GO
SELECT COUNT(*) AS filas FROM dbo.HECHO_PRECIO_1M;          -- debe dar 1000000
EXEC sp_helpindex 'dbo.HECHO_PRECIO_1M';                    -- sin indices (heap)
EXEC sp_spaceused 'dbo.HECHO_PRECIO_1M';                    -- tamano antes del indice
SELECT TOP 10 ID_Producto, COUNT(*) AS n
FROM dbo.HECHO_PRECIO_1M GROUP BY ID_Producto ORDER BY n DESC;
GO

/* ---------- PASO 2: medicion (ejecutar una vez con @fase = 'sin_indice' y otra con 'con_indice') ---------- */
IF OBJECT_ID('dbo.EXP_BI_INDICE') IS NULL
    CREATE TABLE dbo.EXP_BI_INDICE (fase VARCHAR(12), consulta VARCHAR(12), repeticion INT, us BIGINT);
GO
SET NOCOUNT ON;
DECLARE @fase VARCHAR(12) = 'sin_indice';   -- cambiar a 'con_indice' despues de crear el indice
DECLARE @prod INT = 512010;                 -- producto con 6 filas
DECLARE @i INT, @t0 DATETIME2(7), @x DECIMAL(18,4), @n INT;
DELETE FROM dbo.EXP_BI_INDICE WHERE fase = @fase;

-- Q1: filtro por producto
SELECT @x = AVG(Precio_Media) FROM dbo.HECHO_PRECIO_1M WHERE ID_Producto = @prod OPTION (MAXDOP 1); -- calentamiento
SET @i = 1;
WHILE @i <= 3
BEGIN
    SET @t0 = SYSDATETIME();
    SELECT @x = AVG(Precio_Media) FROM dbo.HECHO_PRECIO_1M WHERE ID_Producto = @prod OPTION (MAXDOP 1);
    INSERT dbo.EXP_BI_INDICE VALUES (@fase, 'Q1_filtro', @i, DATEDIFF(MICROSECOND, @t0, SYSDATETIME()));
    SET @i += 1;
END;

-- Q2: promedio agrupado por producto
SELECT @n = COUNT(*) FROM (SELECT ID_Producto, AVG(Precio_Media) AS a FROM dbo.HECHO_PRECIO_1M GROUP BY ID_Producto) t OPTION (MAXDOP 1); -- calentamiento
SET @i = 1;
WHILE @i <= 3
BEGIN
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*) FROM (SELECT ID_Producto, AVG(Precio_Media) AS a FROM dbo.HECHO_PRECIO_1M GROUP BY ID_Producto) t OPTION (MAXDOP 1);
    INSERT dbo.EXP_BI_INDICE VALUES (@fase, 'Q2_grupo', @i, DATEDIFF(MICROSECOND, @t0, SYSDATETIME()));
    SET @i += 1;
END;
GO

/* ---------- PASO 3: crear el indice (entre la corrida sin_indice y con_indice) ---------- */
-- CREATE NONCLUSTERED INDEX IX_1M_Producto ON dbo.HECHO_PRECIO_1M (ID_Producto) INCLUDE (Precio_Media);
-- GO
-- EXEC sp_spaceused 'dbo.HECHO_PRECIO_1M';   -- espacio que ocupa el indice (30 792 KB en la corrida)

/* ---------- PASO 4: resumen con medianas (con 3 valores, mediana = suma - minimo - maximo) ---------- */
SELECT consulta, fase,
       MAX(CASE WHEN repeticion = 1 THEN us END) / 1000.0 AS rep1_ms,
       MAX(CASE WHEN repeticion = 2 THEN us END) / 1000.0 AS rep2_ms,
       MAX(CASE WHEN repeticion = 3 THEN us END) / 1000.0 AS rep3_ms,
       (SUM(us) - MIN(us) - MAX(us)) / 1000.0 AS mediana_ms
FROM dbo.EXP_BI_INDICE
GROUP BY consulta, fase
ORDER BY consulta, fase;
GO

/* ---------- PASO 5: lecturas logicas y plan (Ctrl+M para ver el plan) ---------- */
-- Con indice (Index Seek):
-- SET STATISTICS IO ON;
-- SELECT AVG(Precio_Media) FROM dbo.HECHO_PRECIO_1M WHERE ID_Producto = 512010 OPTION (MAXDOP 1);
-- Sin indice (Table Scan forzado, aunque el indice exista):
-- SELECT AVG(Precio_Media) FROM dbo.HECHO_PRECIO_1M WITH (INDEX(0)) WHERE ID_Producto = 512010 OPTION (MAXDOP 1);

/* ---------- PASO 6: dejar la base limpia ---------- */
-- DROP INDEX IX_1M_Producto ON dbo.HECHO_PRECIO_1M;
