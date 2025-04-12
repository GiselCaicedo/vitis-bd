-- Crear tabla Usuarios
CREATE TABLE Usuarios (
    ID_usuario SERIAL PRIMARY KEY,
    Nombre_usuario VARCHAR(100),
    Correo_electronico VARCHAR(100) UNIQUE,
    Contraseña VARCHAR(100),
    Rol VARCHAR(50) CHECK (Rol IN ('Admin'))
);

-- Crear tabla Productos
CREATE TABLE Productos (
    ID_producto SERIAL PRIMARY KEY,
    Nombre VARCHAR(100),
    Descripcion TEXT,
    Precio DECIMAL(10, 2),
    Stock INT,
    Activo BOOLEAN DEFAULT TRUE
);

-- Crear tabla Clientes
CREATE TABLE Clientes (
    ID_cliente SERIAL PRIMARY KEY,
    Nombre VARCHAR(100),
    Cedula VARCHAR(20) UNIQUE,
    Correo VARCHAR(100),
    Telefono VARCHAR(20)
);

-- Crear tabla Ventas
CREATE TABLE Ventas (
    ID_venta SERIAL PRIMARY KEY,
    ID_cliente INT REFERENCES Clientes(ID_cliente),
    Fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Total DECIMAL(10, 2)
);

-- Crear tabla DetallesVenta
CREATE TABLE DetallesVenta (
    ID_detalle SERIAL PRIMARY KEY,
    ID_venta INT REFERENCES Ventas(ID_venta),
    ID_producto INT REFERENCES Productos(ID_producto),
    Cantidad INT,
    Precio_unitario DECIMAL(10, 2)
);

-- Crear tabla Pagos
CREATE TABLE Pagos (
    ID_pago SERIAL PRIMARY KEY,
    ID_venta INT REFERENCES Ventas(ID_venta),
    Metodo_pago VARCHAR(50),
    Monto DECIMAL(10, 2),
    Fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla Proveedores
CREATE TABLE Proveedores (
    ID_proveedor SERIAL PRIMARY KEY,
    Nombre VARCHAR(100),
    Telefono VARCHAR(20),
    Correo VARCHAR(100)
);

-- Crear tabla Compras
CREATE TABLE Compras (
    ID_compra SERIAL PRIMARY KEY,
    ID_proveedor INT REFERENCES Proveedores(ID_proveedor),
    Fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Total DECIMAL(10, 2)
);

-- Crear tabla DetallesCompra
CREATE TABLE DetallesCompra (
    ID_detalle SERIAL PRIMARY KEY,
    ID_compra INT REFERENCES Compras(ID_compra),
    ID_producto INT REFERENCES Productos(ID_producto),
    Cantidad INT,
    Precio_unitario DECIMAL(10, 2)
);

-- Crear vista para inventario
CREATE VIEW Vista_Inventario AS
SELECT 
    p.ID_producto,
    p.Nombre,
    p.Descripcion,
    p.Stock,
    p.Precio,
    p.Activo
FROM Productos p;

-- Crear vista para ventas detalladas
CREATE VIEW Vista_Ventas_Detalladas AS
SELECT 
    v.ID_venta,
    v.Fecha,
    c.Nombre AS Cliente,
    dv.Cantidad,
    p.Nombre AS Producto,
    dv.Precio_unitario,
    (dv.Cantidad * dv.Precio_unitario) AS Subtotal,
    v.Total
FROM Ventas v
JOIN Clientes c ON v.ID_cliente = c.ID_cliente
JOIN DetallesVenta dv ON v.ID_venta = dv.ID_venta
JOIN Productos p ON dv.ID_producto = p.ID_producto;

-- Datos de prueba
-- Usuario administrador
INSERT INTO Usuarios (Nombre_usuario, Correo_electronico, Contraseña, Rol)
VALUES 
('admin', 'admin@vitisstore.com', 'admin123', 'Admin');

-- Productos
INSERT INTO Productos (Nombre, Descripcion, Precio, Stock)
VALUES
('Uva Isabela', 'Uva morada para vino', 2500.00, 100),
('Uva Thompson', 'Uva verde sin semilla', 2800.00, 80);

-- Clientes
INSERT INTO Clientes (Nombre, Cedula, Correo, Telefono)
VALUES 
('Carlos Pérez', '1002003001', 'carlos@example.com', '3101234567'),
('Lucía Gómez', '1002003002', 'lucia@example.com', '3109876543');

-- Proveedores
INSERT INTO Proveedores (Nombre, Telefono, Correo)
VALUES 
('AgroUvas SAS', '3134567890', 'contacto@agrouvas.com');

-- Compra de prueba
INSERT INTO Compras (ID_proveedor, Total)
VALUES (1, 500000);

INSERT INTO DetallesCompra (ID_compra, ID_producto, Cantidad, Precio_unitario)
VALUES 
(1, 1, 100, 2500);

-- Venta de prueba
INSERT INTO Ventas (ID_cliente, Total)
VALUES (1, 5000);

INSERT INTO DetallesVenta (ID_venta, ID_producto, Cantidad, Precio_unitario)
VALUES 
(1, 1, 2, 2500);

INSERT INTO Pagos (ID_venta, Metodo_pago, Monto)
VALUES 
(1, 'Efectivo', 5000);
