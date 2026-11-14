-- Proyecto: Banco Mezquite | Rentabilidad por cliente 2024-2025
-- Autora:   Brenda Sarahi Santoyo Cordova
-- Archivo:  01_crear_base_y_tablas.sql
-- Qué hace: crea la base BancoRentabilidad y las 6 tablas del modelo
-- estrella (4 dimensiones y 2 tablas de hechos) con sus llaves primarias y foráneas.



IF DB_ID('BancoRentabilidad') IS NULL
    CREATE DATABASE BancoRentabilidad;
GO
-- Borrar tablas que ya existan con estos nombres
DROP TABLE IF EXISTS FactTransacciones;
DROP TABLE IF EXISTS FactRentabilidadMensual;
DROP TABLE IF EXISTS DimCliente;
DROP TABLE IF EXISTS DimProducto;
DROP TABLE IF EXISTS DimSucursal;
DROP TABLE IF EXISTS DimCalendario;
GO

-- Crear tablas de tipo dimensión
CREATE TABLE DimCliente (
    ClienteID               CHAR(5)        NOT NULL PRIMARY KEY,
    NombreCliente           NVARCHAR(80)   NOT NULL,
    EstadoCivil             NVARCHAR(20)   NOT NULL,
    EstatusEmpleo           NVARCHAR(20)   NOT NULL,
    IngresoMensualDeclarado DECIMAL(12,2)  NULL,      -- vacío si no se declaró
    FechaAlta               DATE           NOT NULL,
    CanalAlta               NVARCHAR(10)   NOT NULL,
    Estado                  NVARCHAR(30)   NOT NULL,  -- estandarizado con Mapa_Estados
    FechaNacimiento         DATE           NULL,      -- vacía si venía inválida
    Obs_Ingreso             NVARCHAR(30)   NOT NULL,
    EdadAlta                DECIMAL(10,4)  NULL       -- vacía si no hay fecha de nacimiento
);

CREATE TABLE DimProducto (
    ProductoID              CHAR(3)        NOT NULL PRIMARY KEY,
    NombreProducto          NVARCHAR(50)   NOT NULL,
    TipoProducto            NVARCHAR(20)   NOT NULL,
    Familia                 NVARCHAR(20)   NOT NULL,
    TasaAnual               DECIMAL(6,4)   NULL,      -- variable en Inversión a Plazo
    Anualidad               DECIMAL(10,2)  NOT NULL,
    CostoOperativoMensual   DECIMAL(10,2)  NOT NULL
);

CREATE TABLE DimSucursal (
    SucursalID              CHAR(3)        NOT NULL PRIMARY KEY,
    NombreSucursal          NVARCHAR(50)   NOT NULL,
    Ciudad                  NVARCHAR(50)   NOT NULL,
    Estado                  NVARCHAR(30)   NOT NULL,
    Region                  NVARCHAR(20)   NOT NULL,
    TipoSucursal            NVARCHAR(10)   NOT NULL
);

CREATE TABLE DimCalendario (
    Fecha                   DATE           NOT NULL PRIMARY KEY,
    Año                     INT            NOT NULL,
    Trimestre               CHAR(2)        NOT NULL,
    MesNumero               INT            NOT NULL,
    MesNombre               NVARCHAR(15)   NOT NULL,
    AñoMes                  CHAR(7)        NOT NULL,
    Dia                     INT            NOT NULL,
    DiaSemanaNumero         INT            NOT NULL,
    DiaSemana               NVARCHAR(15)   NOT NULL,
    EsFinDeSemana           NVARCHAR(15)   NOT NULL
);
GO

-- Crear tablas de tipo hecho
CREATE TABLE FactRentabilidadMensual (
    RegistroID              CHAR(7)        NOT NULL PRIMARY KEY,
    ClienteID               CHAR(5)        NOT NULL,
    ProductoID              CHAR(3)        NOT NULL,
    SucursalID              CHAR(3)        NOT NULL,
    Fecha                   DATE           NOT NULL,
    SaldoPromedio           DECIMAL(14,2)  NOT NULL,
    LimiteCredito           DECIMAL(14,2)  NULL,      -- solo tarjetas
    IngresoFinanciero       DECIMAL(12,2)  NOT NULL,
    CostoFinanciero         DECIMAL(12,2)  NOT NULL,
    Comisiones              DECIMAL(12,2)  NOT NULL,
    IngresoIntercambio      DECIMAL(12,2)  NOT NULL,
    IngresoSeguros          DECIMAL(12,2)  NOT NULL,
    CostoOperativo          DECIMAL(12,2)  NOT NULL,
    PerdidaCredito          DECIMAL(12,2)  NOT NULL,
    DiasAtraso              INT            NOT NULL,
    CONSTRAINT FK_Rent_Cliente    FOREIGN KEY (ClienteID)  REFERENCES DimCliente(ClienteID),
    CONSTRAINT FK_Rent_Producto   FOREIGN KEY (ProductoID) REFERENCES DimProducto(ProductoID),
    CONSTRAINT FK_Rent_Sucursal   FOREIGN KEY (SucursalID) REFERENCES DimSucursal(SucursalID),
    CONSTRAINT FK_Rent_Calendario FOREIGN KEY (Fecha)      REFERENCES DimCalendario(Fecha)
);

CREATE TABLE FactTransacciones (
    TransaccionID           CHAR(8)        NOT NULL PRIMARY KEY,
    ClienteID               CHAR(5)        NOT NULL,
    ProductoID              CHAR(3)        NOT NULL,
    Fecha                   DATE           NOT NULL,
    TipoMovimiento          NVARCHAR(30)   NOT NULL,
    Canal                   NVARCHAR(30)   NOT NULL,
    Monto                   DECIMAL(14,2)  NOT NULL,
    ComisionCobrada         DECIMAL(10,2)  NOT NULL,
    EsMovimientoReal        NVARCHAR(2)    NOT NULL,  -- 'Sí' / 'No'
    CONSTRAINT FK_Trans_Cliente    FOREIGN KEY (ClienteID)  REFERENCES DimCliente(ClienteID),
    CONSTRAINT FK_Trans_Producto   FOREIGN KEY (ProductoID) REFERENCES DimProducto(ProductoID),
    CONSTRAINT FK_Trans_Calendario FOREIGN KEY (Fecha)      REFERENCES DimCalendario(Fecha)
);
GO