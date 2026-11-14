--
-- Proyecto: Banco Mezquite | Rentabilidad por cliente 2024-2025
-- Autora:   Brenda Sarahi Santoyo Cordova
-- Archivo:  04_analisis_exploratorio.sql
-- Qué hace: análisis exploratorio previo al dashboard. 
-- Analisis de utilidad por producto y por mes, vista Rent_utilidad, tipos de cliente, concentración
-- de la utilidad, número de productos, incumplimiento y estadística.
--

USE BancoRentabilidad;



-- Revisión rápida de las tablas
-- SELECT * FROM FactRentabilidadMensual;
-- SELECT * FROM DimProducto;

GO
-- ¿Cuánta utilidad generó el banco en 2024–2025 con cada producto, y cuáles le dejan más?
SELECT 
dp.NombreProducto,
ROUND(SUM(fr.IngresoFinanciero-fr.CostoFinanciero+fr.Comisiones+fr.IngresoIntercambio+fr.IngresoSeguros-fr.CostoOperativo-fr.PerdidaCredito),0) AS Utilidad
FROM FactRentabilidadMensual fr
JOIN  DimProducto dp ON fr.ProductoID=dp.ProductoID
GROUP BY dp.NombreProducto
ORDER BY Utilidad DESC;
-- Resultado: la Cuenta de Débito es el único producto con utilidad negativa (-$206,083).

-- ¿qué concepto es el que hace que la cuenta de débito termine en negativo?
SELECT SUM(IngresoFinanciero) AS IngresoFinanciero ,SUM(CostoFinanciero)AS CostoFinanciero,  
SUM(Comisiones) AS Comisiones,SUM(IngresoIntercambio)AS IngresoIntercambio,SUM(IngresoSeguros)AS IngresoSeguros,
SUM(CostoOperativo)AS CostoOperativo,SUM(PerdidaCredito)AS PerdidaCredito,ProductoID FROM FactRentabilidadMensual
WHERE ProductoID = 'P01'   -- P01 = Cuenta de Débito
GROUP BY ProductoID
;

-- ¿Cómo se comportó la utilidad del banco mes a mes durante 2024 y 2025?

SELECT YEAR(Fecha)AS año,MONTH(Fecha) AS mes, ROUND(SUM(IngresoFinanciero-CostoFinanciero+Comisiones+
IngresoIntercambio+IngresoSeguros-CostoOperativo-PerdidaCredito),0) AS Utilidad
FROM FactRentabilidadMensual
GROUP BY YEAR(Fecha), MONTH(Fecha)
ORDER BY YEAR(Fecha),MONTH(Fecha) ASC
;

-- Ahora vamos a entender que factor causó la caida y el crecimiento de cada mes desglosando la utilidad

SELECT YEAR(Fecha) AS Año, MONTH(Fecha)AS Mes, 
SUM(IngresoFinanciero) AS IngresoFinanciero ,SUM(CostoFinanciero)AS CostoFinanciero,  
SUM(Comisiones) AS Comisiones,SUM(IngresoIntercambio)AS IngresoIntercambio,SUM(IngresoSeguros)AS IngresoSeguros,
SUM(CostoOperativo)AS CostoOperativo,SUM(PerdidaCredito)AS PerdidaCredito
FROM FactRentabilidadMensual
GROUP BY YEAR(Fecha), MONTH(Fecha)
ORDER BY YEAR(Fecha),MONTH(Fecha) 
;
GO

-- Hacemos una vista para dejar de repetir la formula de utilidad cada vez
CREATE OR ALTER VIEW Rent_utilidad AS
SELECT
   *,
    (IngresoFinanciero-CostoFinanciero+Comisiones+
	IngresoIntercambio+IngresoSeguros-CostoOperativo-PerdidaCredito) AS Utilidad
	FROM FactRentabilidadMensual;
GO


-- Que tipo de cliente le deja más utilidad al banco?
SELECT * FROM DimProducto;
SELECT * FROM DimCliente;
SELECT * FROM Rent_utilidad;
--Empezando por Estatus de empleo

-- Revisión rápida de las tablas
-- SELECT DISTINCT(EstatusEmpleo) FROM DimCliente;
-- --
SELECT dc.EstatusEmpleo,
SUM(ru.Utilidad) AS Utilidad,
COUNT(DISTINCT(ru.ClienteID)) AS conteo,
COUNT(DISTINCT(ru.ClienteID))*100.0/SUM(COUNT(DISTINCT ru.ClienteID))OVER() AS MixClientes,
SUM(ru.Utilidad)*100/ SUM(SUM(ru.Utilidad))OVER() AS PctUtilidad,
SUM(ru.Utilidad)/COUNT(DISTINCT(ru.ClienteID)) AS UtilidadporCliente
FROM Rent_utilidad ru 
LEFT JOIN DimCliente dc ON ru.ClienteID = dc.ClienteID
GROUP BY dc.EstatusEmpleo
ORDER BY Utilidad DESC;

-- En la consulta anterior solo obtuvimos 995 en conteo porque los siguientes 5 clientes no están 
--en la tabla de rentabilidad
SELECT dc.*
FROM DimCliente dc
WHERE NOT EXISTS (
    SELECT 1 
    FROM Rent_utilidad ru 
    WHERE dc.ClienteID = ru.ClienteID);
GO

-- ¿Qué tan concentrada está la utilidad? ¿Cuánto aporta el 20% de clientes más rentable?
SELECT * FROM DimCliente;
SELECT * FROM Rent_utilidad;
GO
-- Ejercicio con el 20%
WITH RankingClientes AS (
SELECT  ClienteID,SUM(Utilidad) AS Utilidad,
ROW_NUMBER() OVER(ORDER BY SUM(Utilidad) DESC) AS Ranking
FROM Rent_utilidad
GROUP BY ClienteID
)
SELECT 
SUM(Utilidad) AS UtilidadTotal,
SUM(CASE WHEN Ranking <=199 THEN Utilidad END) AS SumaUtilidad_20Pct,
SUM(CASE WHEN Ranking <=199 THEN Utilidad END)/ SUM(Utilidad)*100 AS PorcentajeUtilidad_20Pct,
SUM(CASE WHEN Utilidad <0 THEN 1 END) AS ClientesUtilidadNegativa
FROM RankingClientes
;
GO
-- Ejercicio con el restante 80%
WITH RankingClientes AS (
SELECT  ClienteID,SUM(Utilidad) AS Utilidad,
ROW_NUMBER() OVER(ORDER BY SUM(Utilidad) DESC) AS Ranking
FROM Rent_utilidad
GROUP BY ClienteID
)
SELECT 
SUM(Utilidad) AS UtilidadTotal,
SUM(CASE WHEN Ranking >199 THEN Utilidad END) AS SumaUtilidad_80Pct,
SUM(CASE WHEN Ranking >199 THEN Utilidad END)/ SUM(Utilidad)*100 AS PorcentajeUtilidad_80Pct,
SUM(CASE WHEN Utilidad <0 THEN 1 END) AS ClientesUtilidadNegativa
FROM RankingClientes
-- Resultado: el 20% de los clientes genera el 95% de la utilidad y 321 clientes tienen utilidad negativa.
;
GO

-- ¿Los clientes que tienen más productos con el banco dejan más utilidad? --
-- ¿la utilidad por cliente sube conforme aumenta el número de productos? --

WITH UtilidadporNumeroProductos AS(
SELECT COUNT( DISTINCT ProductoID) AS NoProductos, ClienteID,
SUM(Utilidad) AS Utilidad
FROM Rent_utilidad
GROUP BY ClienteID)

SELECT NoProductos, SUM(Utilidad) AS UtilidadTotal,
COUNT(ClienteID) AS ConteoClientes,
SUM(Utilidad)/COUNT( ClienteID) AS UtilidadporCliente
FROM UtilidadporNumeroProductos
GROUP BY NoProductos
ORDER BY UtilidadTotal DESC;

GO
-- ¿qué producto suelen tener los clientes de un solo producto? -- 

WITH ClientesUnProducto AS (
    -- Filtrar por clientes con un solo producto
    SELECT ClienteID
    FROM Rent_utilidad
    GROUP BY ClienteID
    HAVING COUNT(DISTINCT ProductoID) = 1
),
FrecuenciaProductos AS (
    -- Contar qué productos compraron esos clientes específicos
    SELECT 
        ProductoID,
        COUNT(DISTINCT ClienteID) AS Frecuencia
    FROM Rent_utilidad
    WHERE ClienteID IN (SELECT ClienteID FROM ClientesUnProducto)
    GROUP BY ProductoID
)
-- Obtener el producto con la mayor frecuencia
SELECT ProductoID, Frecuencia
FROM FrecuenciaProductos
WHERE Frecuencia = (SELECT MAX(Frecuencia) FROM FrecuenciaProductos);

GO
-- Da P01 que es el débito

-- ¿Qué tipo de cliente con crédito tiene más probabilidad de caer en cartera vencida? --
SELECT * FROM Rent_utilidad;
SELECT * FROM DimCliente;
SELECT * FROM DimProducto;
GO
SELECT 
dc.EstatusEmpleo,
COUNT(DISTINCT ru.ClienteID) AS NoClientes,
COUNT(DISTINCT CASE WHEN DiasAtraso >= 90 THEN ru.ClienteID END) AS ClientesIncumplidos,
COUNT(DISTINCT CASE WHEN DiasAtraso >= 90 THEN ru.ClienteID END)*100.0/COUNT(DISTINCT ru.ClienteID) AS TasaIncumplimiento
FROM Rent_utilidad ru
LEFT JOIN Dimproducto dp ON ru.ProductoID = dp.ProductoID
LEFT JOIN DimCliente dc ON ru.ClienteID = dc.ClienteID
WHERE dp.TipoProducto = 'Crédito'
GROUP BY dc.EstatusEmpleo
;

-- Calcular promedio y mediana de utilidad de clientes

SELECT  ClienteID,SUM(Utilidad) AS Utilidad,
ROW_NUMBER() OVER(ORDER BY SUM(Utilidad) DESC) AS Ranking
FROM Rent_utilidad
GROUP BY ClienteID;




WITH RankingClientes AS (
SELECT  ClienteID,SUM(Utilidad) AS Utilidad,
ROW_NUMBER() OVER(ORDER BY SUM(Utilidad) DESC) AS Ranking
FROM Rent_utilidad
GROUP BY ClienteID
)
SELECT DISTINCT
AVG(Utilidad)OVER() AS Promedio,
-- Revisión rápida de las tablas
-- PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Utilidad) OVER () AS MedianaUtilidadPorCliente,
-- PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Utilidad) OVER () AS UtilidadPercentil25,
-- PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Utilidad) OVER () AS UtilidadPercentil75,
PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Utilidad) OVER () AS UtilidadPercentil90
FROM RankingClientes
;
GO

-- Prueba t en excel 
SELECT * FROM DimCliente;
GO

SELECT  ru.ClienteID,SUM(ru.Utilidad) AS Utilidad,
ROW_NUMBER() OVER(ORDER BY SUM(ru.Utilidad) DESC) AS Ranking,
dc.EstatusEmpleo

FROM Rent_utilidad ru
LEFT JOIN DimCliente dc ON ru.ClienteID = dc.ClienteID
GROUP BY ru.ClienteID,dc.EstatusEmpleo
HAVING dc.EstatusEmpleo = 'Independiente' OR dc.EstatusEmpleo = 'Asalariado'
;

-- Resultado (Excel): p = 0.11, la diferencia de promedios no es significativa; por eso comparo medianas.
