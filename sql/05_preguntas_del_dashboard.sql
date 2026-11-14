-- 
-- Proyecto: Banco Mezquite | Rentabilidad por cliente 2024-2025
-- Autora:   Brenda Sarahi Santoyo Cordova
-- Archivo:  05_preguntas_del_dashboard.sql
-- Qué hace: preguntas que surgieron al construir el dashboard en Power BI. Entre ellas el análisis de
-- débito vs nómina, origen del crecimiento 2025, clientes digitales vs sucursal, 
-- débito por canal, uso de canales digitales y región.


USE BancoRentabilidad;
GO

-- débito contra nómina en clientes de un solo producto

WITH ClientesUnProducto AS (
    -- Clientes que solo tienen un producto
    SELECT ClienteID
    FROM Rent_utilidad
    GROUP BY ClienteID
    HAVING COUNT(DISTINCT ProductoID) = 1
)
SELECT
    dp.NombreProducto,
    COUNT(DISTINCT ru.ClienteID) AS Clientes,
    SUM(ru.Utilidad) AS UtilidadTotal,
    SUM(ru.Utilidad) / COUNT(DISTINCT ru.ClienteID) AS UtilidadPorCliente
FROM Rent_utilidad ru
JOIN DimProducto dp ON ru.ProductoID = dp.ProductoID
WHERE ru.ClienteID IN (SELECT ClienteID FROM ClientesUnProducto)
GROUP BY dp.NombreProducto
ORDER BY UtilidadPorCliente;
-- Resultado: solo débito, -$427 por cliente (317 clientes); solo nómina, +$325 por cliente (101 clientes).

GO
--¿2025 creció por más clientes o por mejores clientes?

SELECT
    YEAR(Fecha)                                                AS Año,
    MONTH(Fecha)                                               AS Mes,
    COUNT(DISTINCT ClienteID)                                  AS ClientesActivos,
    SUM(Utilidad)                                              AS UtilidadTotal,
    SUM(Utilidad) / COUNT(DISTINCT ClienteID)                  AS UtilidadPorCliente
FROM Rent_utilidad
GROUP BY YEAR(Fecha), MONTH(Fecha)
ORDER BY Año, Mes;
-- Resultado: en 2025 la utilidad creció 13.1% con 9.5% más clientes activos; la utilidad por cliente subió 3.3%.

GO

-- ¿cuánto deja y cuánto cuesta un cliente digital comparado con uno de sucursal? --

-- Revisión rápida de las tablas
-- SELECT * FROM DimCliente;
-- SELECT * FROM DimSucursal;
-- SELECT * FROM Rent_utilidad;

SELECT ds.TipoSucursal,
SUM(ru.Utilidad)as Utilidad,
SUM(ru.CostoOperativo)as CostoOperativo,
COUNT(DISTINCT ru.ClienteID) NoClientes,
SUM(ru.Utilidad) / COUNT(DISTINCT ru.ClienteID) AS UtilidadporCliente,
SUM(ru.CostoOperativo)/COUNT(DISTINCT ru.ClienteID) AS CostoOperativoporCliente
FROM Rent_utilidad ru
LEFT JOIN DimSucursal ds ON ru.SucursalID= ds.SucursalID
GROUP BY ds.TipoSucursal;
-- Resultado: sucursal física 649 clientes, $3,734 de utilidad y $2,821 de costo por cliente; digital 346 clientes, $5,201 y $1,203.

GO

-- ¿cuánto deja un cliente de débito digital comparado con uno de débito en sucursal? ¿Los dos pierden dinero?
SELECT ds.TipoSucursal,
SUM(ru.Utilidad)as Utilidad,
SUM(ru.CostoOperativo)as CostoOperativo,
COUNT(DISTINCT ru.ClienteID) NoClientes,
SUM(ru.Utilidad) / COUNT(DISTINCT ru.ClienteID) AS UtilidadporCliente,
SUM(ru.CostoOperativo)/COUNT(DISTINCT ru.ClienteID) AS CostoOperativoporCliente
FROM Rent_utilidad ru
LEFT JOIN DimSucursal ds ON ru.SucursalID= ds.SucursalID
WHERE ru.ProductoID ='P01'   -- P01 = Cuenta de Débito
GROUP BY ds.TipoSucursal;
-- Resultado: débito en sucursal -$792 por cliente; débito digital +$556 por cliente.
GO

-- ¿qué tanto usan los canales digitales?

-- Revisión rápida de las tablas
-- SELECT * FROM DimCliente;
-- SELECT * FROM FactTransacciones;
-- SELECT DISTINCT Canal From FactTransacciones;
GO

SELECT 
dc.CanalAlta,
COUNT(CASE WHEN ft.Canal='App'OR ft.Canal='Comercio en línea' THEN ft.TransaccionID END) AS NoTransacciones,
COUNT(ft.TransaccionID) AS TotalNoTransacciones,
COUNT(CASE WHEN ft.Canal='App'OR ft.Canal='Comercio en línea' THEN ft.TransaccionID END)*100.0 /COUNT(ft.TransaccionID) AS PctTransaccionesDigitales
FROM FactTransacciones ft
LEFT JOIN DimCliente dc 
ON ft.ClienteID = dc.ClienteID
GROUP BY dc.CanalAlta;
-- Resultado: los clientes que se dieron de alta en la App hacen 42.3% de sus movimientos por canales digitales; los de sucursal, 15.5%.

GO
