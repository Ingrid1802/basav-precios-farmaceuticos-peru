SET NOEXEC OFF;
GO
USE master;
GO

IF DB_ID('DW_PreciosDigemid') IS NOT NULL
BEGIN
    ALTER DATABASE DW_PreciosDigemid SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_PreciosDigemid;
END
GO

CREATE DATABASE DW_PreciosDigemid;
GO

USE DW_PreciosDigemid;
GO

IF DB_NAME() <> N'DW_PreciosDigemid'
BEGIN
    RAISERROR('DETENIDO: no se pudo entrar a DW_PreciosDigemid (esta en uso o en modo single-user). Cierra las otras ventanas de consulta o reinicia el servicio de SQL Server y vuelve a ejecutar.', 16, 1);
    SET NOEXEC ON;
END
GO


CREATE TABLE STG_PRECIOS (
    codigo_producto        FLOAT,
    nombre_comercial       VARCHAR(300),
    concentracion          VARCHAR(100) NULL,
    forma_farmaceutica     VARCHAR(150),
    presentacion           VARCHAR(300),
    registro_sanitario     VARCHAR(100),
    ifa                    VARCHAR(MAX),   
    titular                VARCHAR(300),
    fabricante             VARCHAR(300),
    pais                   VARCHAR(100),
    clasificacion          VARCHAR(20),
    n_establecimientos     FLOAT,          
    precio_media           DECIMAL(12,4),
    precio_mediana         DECIMAL(12,4),
    precio_moda            DECIMAL(12,4),
    periodo                CHAR(7),
    mes                    TINYINT,
    nombre_mes             VARCHAR(15),
    trimestre               TINYINT,
    anio                   SMALLINT,
    variacion_mensual_pct  DECIMAL(12,2) NULL
);
GO


CREATE TABLE DIM_TIEMPO (
    ID_Tiempo   INT NOT NULL PRIMARY KEY,   
    Mes         TINYINT NOT NULL,
    Nombre_Mes  VARCHAR(15) NOT NULL,
    Trimestre   TINYINT NOT NULL,
    Anio        SMALLINT NOT NULL
);
GO

CREATE TABLE DIM_PRODUCTO (
    ID_Producto         INT IDENTITY(1,1) PRIMARY KEY,
    Codigo_Producto     FLOAT NOT NULL UNIQUE,
    Nombre_Producto     VARCHAR(300) NOT NULL,
    Principio_Activo    VARCHAR(MAX) NULL,   
    Concentracion       VARCHAR(100) NULL,
    Forma_Farmaceutica  VARCHAR(150) NULL,
    Presentacion        VARCHAR(300) NULL
);
GO

CREATE TABLE DIM_LABORATORIO (
    ID_Laboratorio              INT IDENTITY(1,1) PRIMARY KEY,
    Titular_Registro_Sanitario  VARCHAR(300) NOT NULL,
    Fabricante                  VARCHAR(300) NULL,
    CONSTRAINT UQ_LABORATORIO UNIQUE (Titular_Registro_Sanitario, Fabricante)
);
GO

CREATE TABLE DIM_CLASIFICACION (
    ID_Clasificacion  INT IDENTITY(1,1) PRIMARY KEY,
    Clasificacion     VARCHAR(20) NOT NULL UNIQUE
);
GO

CREATE TABLE DIM_PAIS_ORIGEN (
    ID_Pais     INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Pais VARCHAR(100) NOT NULL UNIQUE
);
GO


CREATE TABLE HECHO_PRECIO (
    ID_Tiempo               INT NOT NULL,
    ID_Producto             INT NOT NULL,
    ID_Laboratorio          INT NOT NULL,
    ID_Clasificacion        INT NOT NULL,
    ID_Pais                 INT NOT NULL,
    Precio_Media             DECIMAL(12,4) NOT NULL,
    Precio_Mediana            DECIMAL(12,4) NOT NULL,
    Precio_Moda              DECIMAL(12,4) NOT NULL,
    N_Establecimientos_Reportantes INT NOT NULL,
    Variacion_Mensual_Pct    DECIMAL(12,2) NULL,

    CONSTRAINT PK_HECHO_PRECIO PRIMARY KEY
        (ID_Tiempo, ID_Producto, ID_Laboratorio, ID_Clasificacion, ID_Pais),
    CONSTRAINT FK_Hecho_Tiempo        FOREIGN KEY (ID_Tiempo)        REFERENCES DIM_TIEMPO(ID_Tiempo),
    CONSTRAINT FK_Hecho_Producto      FOREIGN KEY (ID_Producto)      REFERENCES DIM_PRODUCTO(ID_Producto),
    CONSTRAINT FK_Hecho_Laboratorio   FOREIGN KEY (ID_Laboratorio)   REFERENCES DIM_LABORATORIO(ID_Laboratorio),
    CONSTRAINT FK_Hecho_Clasificacion FOREIGN KEY (ID_Clasificacion) REFERENCES DIM_CLASIFICACION(ID_Clasificacion),
    CONSTRAINT FK_Hecho_Pais          FOREIGN KEY (ID_Pais)          REFERENCES DIM_PAIS_ORIGEN(ID_Pais)
);
GO

PRINT 'Base de datos y tablas creadas.';
GO


BULK INSERT STG_PRECIOS
FROM 'CAMBIAR_RUTA\datos_listos.csv'                -- Ruta
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO

PRINT 'Datos cargados a STG_PRECIOS.';
SELECT COUNT(*) AS filas_en_staging FROM STG_PRECIOS;
GO


IF (SELECT COUNT(*) FROM STG_PRECIOS) = 0
BEGIN
    RAISERROR('DETENIDO: el BULK INSERT no cargo filas. Revisa la ruta del CSV y el primer error de arriba.', 16, 1);
    SET NOEXEC ON;
END
GO


INSERT INTO DIM_TIEMPO (ID_Tiempo, Mes, Nombre_Mes, Trimestre, Anio)
SELECT DISTINCT anio * 100 + mes, mes, nombre_mes, trimestre, anio
FROM STG_PRECIOS;
GO

INSERT INTO DIM_PRODUCTO (Codigo_Producto, Nombre_Producto, Principio_Activo,
                           Concentracion, Forma_Farmaceutica, Presentacion)
SELECT codigo_producto,
       MIN(nombre_comercial), MIN(ifa), MIN(concentracion),
       MIN(forma_farmaceutica), MIN(presentacion)
FROM STG_PRECIOS
GROUP BY codigo_producto;
GO

INSERT INTO DIM_LABORATORIO (Titular_Registro_Sanitario, Fabricante)
SELECT DISTINCT titular, fabricante FROM STG_PRECIOS;
GO

INSERT INTO DIM_CLASIFICACION (Clasificacion)
SELECT DISTINCT clasificacion FROM STG_PRECIOS;
GO

INSERT INTO DIM_PAIS_ORIGEN (Nombre_Pais)
SELECT DISTINCT pais FROM STG_PRECIOS;
GO

PRINT 'Dimensiones pobladas.';
GO


INSERT INTO HECHO_PRECIO (ID_Tiempo, ID_Producto, ID_Laboratorio, ID_Clasificacion, ID_Pais,
                           Precio_Media, Precio_Mediana, Precio_Moda,
                           N_Establecimientos_Reportantes, Variacion_Mensual_Pct)
SELECT
    s.anio * 100 + s.mes,
    p.ID_Producto,
    l.ID_Laboratorio,
    c.ID_Clasificacion,
    pa.ID_Pais,
    s.precio_media,
    s.precio_mediana,
    s.precio_moda,
    CAST(s.n_establecimientos AS INT),
    s.variacion_mensual_pct
FROM STG_PRECIOS s
JOIN DIM_PRODUCTO p       ON p.Codigo_Producto = s.codigo_producto
JOIN DIM_LABORATORIO l    ON l.Titular_Registro_Sanitario = s.titular
                           AND ISNULL(l.Fabricante,'') = ISNULL(s.fabricante,'')
JOIN DIM_CLASIFICACION c  ON c.Clasificacion = s.clasificacion
JOIN DIM_PAIS_ORIGEN pa   ON pa.Nombre_Pais = s.pais;
GO

PRINT 'Tabla de hechos poblada.';
GO


SELECT 'DIM_TIEMPO' AS Tabla, COUNT(*) AS Filas FROM DIM_TIEMPO
UNION ALL SELECT 'DIM_PRODUCTO', COUNT(*) FROM DIM_PRODUCTO
UNION ALL SELECT 'DIM_LABORATORIO', COUNT(*) FROM DIM_LABORATORIO
UNION ALL SELECT 'DIM_CLASIFICACION', COUNT(*) FROM DIM_CLASIFICACION
UNION ALL SELECT 'DIM_PAIS_ORIGEN', COUNT(*) FROM DIM_PAIS_ORIGEN
UNION ALL SELECT 'HECHO_PRECIO', COUNT(*) FROM HECHO_PRECIO;
GO


SELECT TOP 20
    t.Nombre_Mes, t.Anio, pr.Nombre_Producto, l.Titular_Registro_Sanitario,
    c.Clasificacion, h.Precio_Mediana, h.Variacion_Mensual_Pct
FROM HECHO_PRECIO h
JOIN DIM_TIEMPO t        ON t.ID_Tiempo = h.ID_Tiempo
JOIN DIM_PRODUCTO pr     ON pr.ID_Producto = h.ID_Producto
JOIN DIM_LABORATORIO l   ON l.ID_Laboratorio = h.ID_Laboratorio
JOIN DIM_CLASIFICACION c ON c.ID_Clasificacion = h.ID_Clasificacion
ORDER BY t.ID_Tiempo DESC;
GO

SET NOEXEC OFF;
GO
