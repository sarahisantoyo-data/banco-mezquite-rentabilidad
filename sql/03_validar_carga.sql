-- Proyecto: Banco Mezquite | Rentabilidad por cliente 2024-2025
-- Autora:   Brenda Sarahi Santoyo Cordova
-- Archivo:  03_validar_carga.sql
-- Qué hace: confirma que la carga en SQL coincide con las cifras de control dadas en Excel

-- Validacion de dato en SQL 

USE BancoRentabilidad;

-- Comparar contra datos de conciliacion

SELECT COUNT(ClienteID) AS Cantidad_clientes FROM DimCliente;                              -- Esperado: 1,000
SELECT COUNT(RegistroID) AS Cantidad_RegistrosRentabilidad FROM FactRentabilidadMensual;   -- Esperado: 30,932
SELECT COUNT(TransaccionID) AS Cantidad_Transacciones FROM FactTransacciones;              -- Esperado: 167,700
SELECT MIN(Fecha) AS Fecha_minima FROM FactRentabilidadMensual;                            -- Esperado: 2024-01-01
SELECT MAX(Fecha) AS Fecha_maxima FROM FactRentabilidadMensual;                            -- Esperado: 2025-12-01