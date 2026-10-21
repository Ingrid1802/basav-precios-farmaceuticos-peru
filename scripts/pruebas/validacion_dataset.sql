USE DW_PreciosDigemid;
GO

SELECT
    'STG_PRECIOS' AS Tabla,
    COUNT_BIG(*) AS TotalRegistros
FROM dbo.STG_PRECIOS

UNION ALL

SELECT
    'HECHO_PRECIO',
    COUNT_BIG(*)
FROM dbo.HECHO_PRECIO;
GO

Verificar valores nulos en los campos revisados
USE DW_PreciosDigemid;
GO

SELECT
    COUNT_BIG(*) AS TotalRegistros,
    SUM(CASE WHEN Precio_Media IS NULL THEN 1 ELSE 0 END) AS Nulos_Precio_Media,
    SUM(CASE WHEN Precio_Mediana IS NULL THEN 1 ELSE 0 END) AS Nulos_Precio_Mediana,
    SUM(CASE WHEN Precio_Moda IS NULL THEN 1 ELSE 0 END) AS Nulos_Precio_Moda,
    SUM(CASE WHEN ID_Producto IS NULL THEN 1 ELSE 0 END) AS Nulos_ID_Producto
FROM dbo.HECHO_PRECIO;
GO

Verificar duplicados en la clave compuesta
USE DW_PreciosDigemid;
GO

SELECT
    ID_Tiempo,
    ID_Producto,
    ID_Laboratorio,
    ID_Clasificacion,
    ID_Pais,
    COUNT_BIG(*) AS Cantidad
FROM dbo.HECHO_PRECIO
GROUP BY
    ID_Tiempo,
    ID_Producto,
    ID_Laboratorio,
    ID_Clasificacion,
    ID_Pais
HAVING COUNT_BIG(*) > 1;
GO

Verificar registros huérfanos en las dimensiones
USE DW_PreciosDigemid;
GO

SELECT 'Producto' AS Relacion, COUNT_BIG(*) AS Huerfanos
FROM dbo.HECHO_PRECIO h
LEFT JOIN dbo.DIM_PRODUCTO d
    ON h.ID_Producto = d.ID_Producto
WHERE d.ID_Producto IS NULL

UNION ALL

SELECT 'Laboratorio', COUNT_BIG(*)
FROM dbo.HECHO_PRECIO h
LEFT JOIN dbo.DIM_LABORATORIO d
    ON h.ID_Laboratorio = d.ID_Laboratorio
WHERE d.ID_Laboratorio IS NULL

UNION ALL

SELECT 'Clasificacion', COUNT_BIG(*)
FROM dbo.HECHO_PRECIO h
LEFT JOIN dbo.DIM_CLASIFICACION d
    ON h.ID_Clasificacion = d.ID_Clasificacion
WHERE d.ID_Clasificacion IS NULL

UNION ALL

SELECT 'Pais', COUNT_BIG(*)
FROM dbo.HECHO_PRECIO h
LEFT JOIN dbo.DIM_PAIS_ORIGEN d
    ON h.ID_Pais = d.ID_Pais
WHERE d.ID_Pais IS NULL;
GO
