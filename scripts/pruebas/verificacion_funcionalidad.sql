USE DW_PreciosDigemid;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SELECT
    COUNT_BIG(*) AS TotalFilas,
    AVG(Precio_Media) AS PrecioPromedio
FROM dbo.HECHO_PRECIO_PRUEBA
OPTION (MAXDOP 1);
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

Verificación de funcionalidad y completitud
USE DW_PreciosDigemid;
GO

SELECT
    Escenario,
    FilasEsperadas,
    FilasObtenidas,
    PrecioPromedio,
    CASE
        WHEN FilasObtenidas = FilasEsperadas
             AND PrecioPromedio IS NOT NULL
        THEN 'CUMPLE'
        ELSE 'NO CUMPLE'
    END AS Estado
FROM
(
    SELECT
        'BI-01' AS Escenario,
        CAST(100000 AS BIGINT) AS FilasEsperadas,
        COUNT_BIG(*) AS FilasObtenidas,
        AVG(Precio_Media) AS PrecioPromedio
    FROM dbo.HECHO_PRECIO_PRUEBA

    UNION ALL

    SELECT
        'BI-02',
        CAST(500000 AS BIGINT),
        COUNT_BIG(*),
        AVG(Precio_Media)
    FROM dbo.HECHO_PRECIO_500K

    UNION ALL

    SELECT
        'BI-03',
        CAST(1000000 AS BIGINT),
        COUNT_BIG(*),
        AVG(Precio_Media)
    FROM dbo.HECHO_PRECIO_1M
) AS Validacion;
GO