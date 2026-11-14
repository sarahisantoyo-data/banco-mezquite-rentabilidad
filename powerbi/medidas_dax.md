# Medidas DAX · Banco Mezquite

Medidas del dashboard de Power BI, organizadas por página. Las fórmulas se exportaron directamente del modelo (`_Medidas`).

**Convención de variaciones vs año anterior (AA):** en % para comparar ritmos de crecimiento, en puntos porcentuales cuando el dato ya es un porcentaje, y en pesos para repartir un cambio entre partes. Las variaciones con `HASONEVALUE` solo se calculan cuando hay un año seleccionado.

## Medidas base

Sumas y conteos que usan todas las demás medidas.

```dax
UtilidadTotal =
SUM(FactRentabilidad[Utilidad])

TotalIngresoFinanciero =
SUM(FactRentabilidad[IngresoFinanciero])

TotalCostoFinanciero =
SUM(FactRentabilidad[CostoFinanciero])

TotalMargenFinanciero =
[TotalIngresoFinanciero]-[TotalCostoFinanciero]

TotalComisiones =
SUM(FactRentabilidad[Comisiones])

TotalIngresoIntercambio =
SUM(FactRentabilidad[IngresoIntercambio])

TotalSegurosIngreso =
SUM(FactRentabilidad[IngresoSeguros])

TotalCostoOperativo =
SUM(FactRentabilidad[CostoOperativo])

TotalPerdidaCredito =
SUM(FactRentabilidad[PerdidaCredito])

TotalClientesActivos =
DISTINCTCOUNT(FactRentabilidad[ClienteID])

TotalMovimientos =
COUNTROWS( FactTransacciones )
```

## Panorama

Variación contra el año anterior y puente de utilidad 2024 → 2025 (cascada con la tabla desconectada Conceptos).

```dax
%VarUtilidadvsAA =
VAR Actual   = [UtilidadTotal]
VAR Anterior = CALCULATE( [UtilidadTotal], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
    DIVIDE( Actual - Anterior, Anterior )

%VarMargenvsAA =
VAR Actual   = [TotalMargenFinanciero]
VAR Anterior = CALCULATE( [TotalMargenFinanciero], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
    DIVIDE( Actual - Anterior, Anterior )

%VarPerdidaCreditovsAA =
VAR Actual   = [TotalPerdidaCredito]
VAR Anterior = CALCULATE( [TotalPerdidaCredito], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
    DIVIDE( Actual - Anterior, Anterior )

%VarClientesActvsAA =
VAR Actual   = [TotalClientesActivos]
VAR Anterior = CALCULATE( [TotalClientesActivos], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
    DIVIDE( Actual - Anterior, Anterior )

VarConceptovsAA =
VAR AnioAnt = SAMEPERIODLASTYEAR( DimCalendario[Fecha] )
RETURN
SWITCH( SELECTEDVALUE( Conceptos[Concepto] ),
    "Utilidad 2024",        CALCULATE( [UtilidadTotal], AnioAnt ),
    "Ingreso financiero",   [TotalIngresoFinanciero]  - CALCULATE( [TotalIngresoFinanciero], AnioAnt ),
    "Comisiones",           [TotalComisiones]         - CALCULATE( [TotalComisiones], AnioAnt ),
    "Intercambio",          [TotalIngresoIntercambio] - CALCULATE( [TotalIngresoIntercambio], AnioAnt ),
    "Seguros",              [TotalSegurosIngreso]     - CALCULATE( [TotalSegurosIngreso], AnioAnt ),
    "Costo financiero",   -( [TotalCostoFinanciero]   - CALCULATE( [TotalCostoFinanciero], AnioAnt ) ),
    "Costo operativo",    -( [TotalCostoOperativo]    - CALCULATE( [TotalCostoOperativo], AnioAnt ) ),
    "Pérdida por crédito",-( [TotalPerdidaCredito]    - CALCULATE( [TotalPerdidaCredito], AnioAnt ) )
)
```

## Clientes

Utilidad por cliente, concentración y segmentación dinámica: los grupos y el número de productos se recalculan con el periodo filtrado (tablas desconectadas Grupos y Aux_NumProductos).

```dax
UtilidadPromedioCliente =
DIVIDE([UtilidadTotal],[TotalClientesActivos],0)

%VarUtilidadPromediovsAA =
VAR Actual = [UtilidadPromedioCliente]
VAR Anterior = CALCULATE( [UtilidadPromedioCliente], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN DIVIDE( Actual - Anterior, Anterior )

UtilidadMedianaCliente =
MEDIANX(VALUES( FactRentabilidad[ClienteID] ),[UtilidadTotal])

ClientesUtilidadNegativa =
COUNTROWS(FILTER(VALUES( FactRentabilidad[ClienteID] ),[UtilidadTotal]<0))

% Clientes con Perdida =
DIVIDE( [ClientesUtilidadNegativa], [TotalClientesActivos] )

VarClientesPerdidavsAA =
VAR Actual = [% Clientes con Perdida]
VAR Anterior = CALCULATE( [% Clientes con Perdida], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN Actual - Anterior

% Utilidad Top 20% =
VAR NumTop =
    ROUND( [TotalClientesActivos] * 0.2, 0 )
VAR ClientesTop =
    TOPN( NumTop, VALUES( FactRentabilidad[ClienteID] ), [UtilidadTotal], DESC )
RETURN
    DIVIDE( SUMX( ClientesTop, [UtilidadTotal] ), [UtilidadTotal] )

UtilidadGrupo =
VAR Clientes =
    ADDCOLUMNS( VALUES( FactRentabilidad[ClienteID] ), "@Utilidad", [UtilidadTotal] )
VAR NumTop = ROUND( COUNTROWS( Clientes ) * 0.2, 0 )
VAR ClientesTop = TOPN( NumTop, Clientes, [@Utilidad], DESC )
VAR UtilTop = SUMX( ClientesTop, [@Utilidad] )
VAR UtilPerdida = SUMX( FILTER( Clientes, [@Utilidad] < 0 ), [@Utilidad] )
VAR UtilResto = SUMX( Clientes, [@Utilidad] ) - UtilTop - UtilPerdida
RETURN
SWITCH( SELECTEDVALUE( Grupos[Grupo] ),
    "Top 20%",            UtilTop,
    "Resto con ganancia", UtilResto,
    "Con pérdida",        UtilPerdida
)

VarUtilidadGrupovsAA =
VAR Actual = [UtilidadGrupo]
VAR Anterior = CALCULATE( [UtilidadGrupo], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
IF( HASONEVALUE( DimCalendario[Año] ), Actual - Anterior )

UtilidadPromNumProd =
VAR N = SELECTEDVALUE( Aux_NumProductos[NumProductos] )
VAR Clientes =
    ADDCOLUMNS(
        VALUES( FactRentabilidad[ClienteID] ),
        "@NumProd", CALCULATE( DISTINCTCOUNT( FactRentabilidad[ProductoID] ) ),
        "@Utilidad", [UtilidadTotal]
    )
VAR ClientesN = FILTER( Clientes, [@NumProd] = N )
RETURN AVERAGEX( ClientesN, [@Utilidad] )

ClientesNumProd =
VAR N = SELECTEDVALUE( Aux_NumProductos[NumProductos] )
VAR Clientes =
    ADDCOLUMNS(
        VALUES( FactRentabilidad[ClienteID] ),
        "@NumProd", CALCULATE( DISTINCTCOUNT( FactRentabilidad[ProductoID] ) )
    )
RETURN COUNTROWS( FILTER( Clientes, [@NumProd] = N ) )
```

## Riesgo

Incumplimiento (90 días o más de atraso) e IMOR. Las variaciones van en puntos porcentuales.

```dax
ClientesIncumplidos =
CALCULATE(COUNTROWS(VALUES(FactRentabilidad[ClienteID])),FactRentabilidad[DiasAtraso]>=90)

ClientesConCredito =
CALCULATE(COUNTROWS(VALUES(FactRentabilidad[ClienteID])),DimProducto[TipoProducto]= "Crédito")

TasaIncumplimiento =
DIVIDE([ClientesIncumplidos],[ClientesConCredito],0)

VarTasaIncumplimientovsAA =
VAR Actual = [TasaIncumplimiento]
VAR Anterior = CALCULATE( [TasaIncumplimiento], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
IF( HASONEVALUE( DimCalendario[Año] ), Actual - Anterior )

IMOR =
DIVIDE(CALCULATE(SUM(FactRentabilidad[SaldoPromedio]),FactRentabilidad[DiasAtraso]>=90),CALCULATE(SUM(FactRentabilidad[SaldoPromedio]),DimProducto[TipoProducto]="Crédito"),0)

VarIMORvsAA =
VAR Actual = [IMOR]
VAR Anterior = CALCULATE( [IMOR], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
IF( HASONEVALUE( DimCalendario[Año] ), Actual - Anterior )
```

## Canales

Clientes digitales vs sucursal, costo de atención y utilidad del débito en sucursal.

```dax
%ClientesDigitales =
DIVIDE(CALCULATE([TotalClientesActivos],DimSucursal[TipoSucursal]="Digital"),[TotalClientesActivos])

VarClientesDigitalesvsAA =
VAR Actual = [%ClientesDigitales]
VAR Anterior = CALCULATE( [%ClientesDigitales], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
IF( HASONEVALUE( DimCalendario[Año] ), Actual - Anterior )

CostoOperativoporCliente =
DIVIDE([TotalCostoOperativo],[TotalClientesActivos],0)

%VarCostoOpClientevsAA =
VAR Actual = [CostoOperativoporCliente]
VAR Anterior = CALCULATE( [CostoOperativoporCliente], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
IF( HASONEVALUE( DimCalendario[Año] ), DIVIDE( Actual - Anterior, Anterior ) )

% Movimientos Digitales =
DIVIDE(
   CALCULATE( COUNTROWS( FactTransacciones ),
    FactTransacciones[Canal] IN { "App", "Comercio en línea" } ),
    COUNTROWS( FactTransacciones )
)

VarMovDigitalesvsAA =
VAR Actual = [% Movimientos Digitales]
VAR Anterior = CALCULATE( [% Movimientos Digitales], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
IF( HASONEVALUE( DimCalendario[Año] ), Actual - Anterior )

UtilidadDebitoSucursal =
CALCULATE(
    [UtilidadTotal],
    DimProducto[NombreProducto] = "Cuenta de Débito",
    DimSucursal[TipoSucursal] = "Física"
)

%VarDebitoSucursalvsAA =
VAR Actual = [UtilidadDebitoSucursal]
VAR Anterior = CALCULATE( [UtilidadDebitoSucursal], SAMEPERIODLASTYEAR( DimCalendario[Fecha] ) )
RETURN
IF( HASONEVALUE( DimCalendario[Año] ), DIVIDE( Actual - Anterior, ABS( Anterior ) ) )
```
