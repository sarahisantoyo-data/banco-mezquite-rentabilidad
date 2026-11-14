-- Proyecto: Banco Mezquite | Rentabilidad por cliente 2024-2025
-- Autora:   Brenda Sarahi Santoyo Cordova
-- Archivo:  02_cargar_datos.sql
-- Qué hace: carga los 6 CSV limpios (generados por la macro de Excel) con BULK INSERT


USE BancoRentabilidad;
GO

-- Vaciar las tablas antes de cargar, para poder volver a ejecutar el script sin duplicar datos
-- Primero las de hechos y luego las dimensiones, por las llaves foráneas
DELETE FROM FactTransacciones;
DELETE FROM FactRentabilidadMensual;
DELETE FROM DimCliente;
DELETE FROM DimProducto;
DELETE FROM DimSucursal;
DELETE FROM DimCalendario;
GO

-- Cargar datos con los archivos csv limpios, empezando con tablas de tipo dimensión porque las tablas de hechos dependen de ellas por sus llaves foráneas
BULK INSERT DimCliente    FROM 'RUTA'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001', TABLOCK);

BULK INSERT DimProducto   FROM 'RUTA'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001', TABLOCK);

BULK INSERT DimSucursal   FROM 'RUTA'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001', TABLOCK);

BULK INSERT DimCalendario FROM 'RUTA'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001', TABLOCK);
GO

-- Cargar datos con los archivos csv limpios,  con tablas de tipo hecho
BULK INSERT FactRentabilidadMensual FROM 'RUTA'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001', TABLOCK);

BULK INSERT FactTransacciones FROM 'RUTA'
WITH (FORMAT = 'CSV', FIRSTROW = 2, CODEPAGE = '65001', TABLOCK);
GO
