-- Script de Base de Datos PostgreSQL para Comercializadora Vitis Store SAS (Completo)

-- Crear tablas

-- Usuarios - Para el Módulo de Autenticación
CREATE TABLE Usuarios (
    ID_usuario SERIAL PRIMARY KEY,
    Nombre_usuario VARCHAR(100) NOT NULL,
    Rol VARCHAR(20) CHECK (Rol IN ('Admin', 'Empleado')),
    Fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE,
    Contraseña VARCHAR(255) NOT NULL,
    Correo VARCHAR(100) UNIQUE NOT NULL,
    Activo BOOLEAN DEFAULT TRUE,
    Ultimo_acceso TIMESTAMP,
    Token_recuperacion VARCHAR(255),
    Token_expiracion TIMESTAMP
);

-- Sesiones_usuario - Para el Módulo de Autenticación
CREATE TABLE Sesiones_usuario (
    ID_sesion SERIAL PRIMARY KEY,
    ID_usuario INTEGER NOT NULL REFERENCES Usuarios(ID_usuario),
    Token_sesion VARCHAR(255) NOT NULL,
    Fecha_inicio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Fecha_expiracion TIMESTAMP NOT NULL,
    IP_cliente VARCHAR(45),
    Agente_usuario TEXT
);

-- Categorias - Para el Módulo de Catálogo
CREATE TABLE Categorias (
    ID_categoria SERIAL PRIMARY KEY,
    Nombre_categoria VARCHAR(100) NOT NULL,
    Descripción TEXT,
    Activo BOOLEAN DEFAULT TRUE
);

-- Productos - Para los Módulos de Catálogo e Inventario
CREATE TABLE Productos (
    ID_producto SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Descripción TEXT,
    Precio DECIMAL(10, 2) NOT NULL CHECK (Precio >= 0),
    Precio_compra DECIMAL(10, 2) NOT NULL CHECK (Precio_compra >= 0),
    Stock_actual INTEGER NOT NULL DEFAULT 0 CHECK (Stock_actual >= 0),
    Stock_minimo INTEGER NOT NULL DEFAULT 0 CHECK (Stock_minimo >= 0),
    Fecha_creación DATE NOT NULL DEFAULT CURRENT_DATE,
    Ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ID_categoria INTEGER REFERENCES Categorias(ID_categoria),
    Codigo_barras VARCHAR(50),
    Imagen_url VARCHAR(255),
    Activo BOOLEAN DEFAULT TRUE
);

-- Ventas - Para el Módulo de Ventas
CREATE TABLE Ventas (
    ID_venta SERIAL PRIMARY KEY,
    Fecha_venta DATE NOT NULL DEFAULT CURRENT_DATE,
    Fecha_hora_venta TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Total_venta DECIMAL(10, 2) NOT NULL CHECK (Total_venta >= 0),
    ID_usuario INTEGER NOT NULL REFERENCES Usuarios(ID_usuario),
    Estado VARCHAR(20) CHECK (Estado IN ('Completada', 'Cancelada', 'Pendiente')),
    Metodo_pago VARCHAR(50),
    Notas TEXT
);

-- Detalles_venta - Para el Módulo de Ventas
CREATE TABLE Detalles_venta (
    ID_detalle SERIAL PRIMARY KEY,
    ID_venta INTEGER NOT NULL REFERENCES Ventas(ID_venta),
    ID_producto INTEGER NOT NULL REFERENCES Productos(ID_producto),
    Cantidad INTEGER NOT NULL CHECK (Cantidad > 0),
    Precio_unitario DECIMAL(10, 2) NOT NULL CHECK (Precio_unitario >= 0),
    Subtotal DECIMAL(10, 2) NOT NULL CHECK (Subtotal >= 0),
    Número_detalle INTEGER NOT NULL,
    Descuento DECIMAL(10, 2) DEFAULT 0
);

-- Historial_actualizaciones - Para el Módulo de Auditoría
CREATE TABLE Historial_actualizaciones (
    ID_actualizacion SERIAL PRIMARY KEY,
    ID_usuario INTEGER NOT NULL REFERENCES Usuarios(ID_usuario),
    ID_producto INTEGER NOT NULL REFERENCES Productos(ID_producto),
    Fecha_actualización TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Cambio_realizado TEXT NOT NULL,
    Valor_anterior TEXT,
    Valor_nuevo TEXT,
    Tipo_cambio VARCHAR(50)
);

-- Movimientos_inventario - Para el Módulo de Inventario
CREATE TABLE Movimientos_inventario (
    ID_movimiento SERIAL PRIMARY KEY,
    Tipo_movimiento VARCHAR(20) NOT NULL CHECK (Tipo_movimiento IN ('Entrada', 'Salida', 'Ajuste')),
    Cantidad INTEGER NOT NULL CHECK (Cantidad > 0),
    Fecha_movimiento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ID_usuario INTEGER NOT NULL REFERENCES Usuarios(ID_usuario),
    ID_producto INTEGER NOT NULL REFERENCES Productos(ID_producto),
    Observaciones TEXT,
    Documento_referencia VARCHAR(100),
    ID_venta INTEGER REFERENCES Ventas(ID_venta)
);

-- Alertas_stock - Para el Módulo de Alertas de Inventario
CREATE TABLE Alertas_stock (
    ID_alerta SERIAL PRIMARY KEY,
    ID_producto INTEGER NOT NULL REFERENCES Productos(ID_producto),
    Fecha_alerta TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Estado VARCHAR(20) NOT NULL CHECK (Estado IN ('Pendiente', 'Resuelto', 'Ignorado')),
    Prioridad_alerta VARCHAR(20) CHECK (Prioridad_alerta IN ('Alta', 'Media', 'Baja')),
    Mensaje TEXT,
    Fecha_resolucion TIMESTAMP
);

-- Configuracion_sistema - Para el Módulo de Configuración
CREATE TABLE Configuracion_sistema (
    ID_configuracion SERIAL PRIMARY KEY,
    Nombre_parametro VARCHAR(100) NOT NULL UNIQUE,
    Valor TEXT,
    Descripción TEXT,
    Fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reportes_guardados - Para el Módulo de Reportes
CREATE TABLE Reportes_guardados (
    ID_reporte SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Descripción TEXT,
    Parametros JSON,
    ID_usuario INTEGER NOT NULL REFERENCES Usuarios(ID_usuario),
    Fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Tipo_reporte VARCHAR(50) NOT NULL
);

-- Índices para optimización de rendimiento
CREATE INDEX idx_productos_categoria ON Productos(ID_categoria);
CREATE INDEX idx_productos_stock_minimo ON Productos(Stock_minimo);
CREATE INDEX idx_ventas_usuario ON Ventas(ID_usuario);
CREATE INDEX idx_ventas_fecha ON Ventas(Fecha_venta);
CREATE INDEX idx_detalles_venta ON Detalles_venta(ID_venta);
CREATE INDEX idx_detalles_producto ON Detalles_venta(ID_producto);
CREATE INDEX idx_movimientos_producto ON Movimientos_inventario(ID_producto);
CREATE INDEX idx_movimientos_fecha ON Movimientos_inventario(Fecha_movimiento);
CREATE INDEX idx_alertas_producto ON Alertas_stock(ID_producto);
CREATE INDEX idx_alertas_estado ON Alertas_stock(Estado);
CREATE INDEX idx_historial_producto ON Historial_actualizaciones(ID_producto);
CREATE INDEX idx_historial_usuario ON Historial_actualizaciones(ID_usuario);

-- Vistas

-- Vista para estado de stock de productos
CREATE OR REPLACE VIEW vista_estado_stock AS
SELECT 
    p.ID_producto,
    p.Nombre,
    p.Stock_actual,
    p.Stock_minimo,
    c.Nombre_categoria,
    CASE 
        WHEN p.Stock_actual <= p.Stock_minimo THEN 'Bajo'
        WHEN p.Stock_actual <= (p.Stock_minimo * 1.5) THEN 'Medio'
        ELSE 'Adecuado'
    END AS Nivel_stock,
    p.Precio,
    p.Precio_compra,
    (p.Stock_actual * p.Precio) AS Valor_inventario
FROM 
    Productos p
LEFT JOIN 
    Categorias c ON p.ID_categoria = c.ID_categoria;

-- Vista para resumen de ventas
CREATE OR REPLACE VIEW vista_resumen_ventas AS
SELECT 
    v.ID_venta,
    v.Fecha_venta,
    u.Nombre_usuario AS Vendedor,
    v.Total_venta,
    COUNT(d.ID_detalle) AS Cantidad_productos,
    STRING_AGG(p.Nombre, ', ') AS Productos_vendidos,
    v.Estado,
    v.Metodo_pago
FROM 
    Ventas v
JOIN 
    Usuarios u ON v.ID_usuario = u.ID_usuario
JOIN 
    Detalles_venta d ON v.ID_venta = d.ID_venta
JOIN 
    Productos p ON d.ID_producto = p.ID_producto
GROUP BY 
    v.ID_venta, v.Fecha_venta, u.Nombre_usuario, v.Total_venta, v.Estado, v.Metodo_pago;

-- Vista para productos más vendidos
CREATE OR REPLACE VIEW vista_productos_mas_vendidos AS
SELECT 
    p.ID_producto,
    p.Nombre,
    c.Nombre_categoria AS Categoria,
    SUM(d.Cantidad) AS Total_vendido,
    SUM(d.Subtotal) AS Total_ingresos
FROM 
    Productos p
JOIN 
    Detalles_venta d ON p.ID_producto = d.ID_producto
JOIN 
    Ventas v ON d.ID_venta = v.ID_venta
LEFT JOIN 
    Categorias c ON p.ID_categoria = c.ID_categoria
WHERE 
    v.Estado = 'Completada'
GROUP BY 
    p.ID_producto, p.Nombre, c.Nombre_categoria
ORDER BY 
    Total_vendido DESC;

-- Vista para alertas activas
CREATE OR REPLACE VIEW vista_alertas_activas AS
SELECT 
    a.ID_alerta,
    p.Nombre AS Producto,
    a.Fecha_alerta,
    a.Prioridad_alerta,
    p.Stock_actual,
    p.Stock_minimo,
    a.Mensaje
FROM 
    Alertas_stock a
JOIN 
    Productos p ON a.ID_producto = p.ID_producto
WHERE 
    a.Estado = 'Pendiente'
ORDER BY 
    CASE 
        WHEN a.Prioridad_alerta = 'Alta' THEN 1
        WHEN a.Prioridad_alerta = 'Media' THEN 2
        WHEN a.Prioridad_alerta = 'Baja' THEN 3
        ELSE 4
    END;

-- Funciones y Triggers

-- Función para actualizar stock tras una venta
CREATE OR REPLACE FUNCTION fn_actualizar_stock_venta()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar stock del producto
    UPDATE Productos 
    SET Stock_actual = Stock_actual - NEW.Cantidad
    WHERE ID_producto = NEW.ID_producto;
    
    -- Crear registro de movimiento de inventario
    INSERT INTO Movimientos_inventario (
        Tipo_movimiento, 
        Cantidad, 
        ID_usuario, 
        ID_producto, 
        Observaciones,
        ID_venta
    )
    SELECT 
        'Salida', 
        NEW.Cantidad, 
        v.ID_usuario, 
        NEW.ID_producto, 
        'Venta ID: ' || NEW.ID_venta,
        NEW.ID_venta
    FROM 
        Ventas v
    WHERE 
        v.ID_venta = NEW.ID_venta;
        
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar stock tras insertar un detalle de venta
CREATE TRIGGER trg_actualizar_stock_venta
AFTER INSERT ON Detalles_venta
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_stock_venta();

-- Función para generar alertas de stock
CREATE OR REPLACE FUNCTION fn_generar_alerta_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Stock_actual <= NEW.Stock_minimo AND 
       NOT EXISTS (SELECT 1 FROM Alertas_stock WHERE ID_producto = NEW.ID_producto AND Estado = 'Pendiente') THEN
        
        INSERT INTO Alertas_stock (
            ID_producto, 
            Estado, 
            Prioridad_alerta,
            Mensaje
        )
        VALUES (
            NEW.ID_producto, 
            'Pendiente',
            CASE
                WHEN NEW.Stock_actual = 0 THEN 'Alta'
                WHEN NEW.Stock_actual <= (NEW.Stock_minimo * 0.5) THEN 'Media'
                ELSE 'Baja'
            END,
            'Stock bajo: ' || NEW.Stock_actual || ' unidades (mínimo: ' || NEW.Stock_minimo || ')'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para generar alertas de stock cuando el stock se actualiza
CREATE TRIGGER trg_generar_alerta_stock
AFTER UPDATE OF Stock_actual ON Productos
FOR EACH ROW
EXECUTE FUNCTION fn_generar_alerta_stock();

-- Función para registrar actualizaciones de productos
CREATE OR REPLACE FUNCTION fn_registrar_actualizacion_producto()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Historial_actualizaciones (
        ID_usuario,
        ID_producto,
        Cambio_realizado,
        Valor_anterior,
        Valor_nuevo,
        Tipo_cambio
    )
    VALUES (
        COALESCE(current_setting('app.current_user_id', true)::integer, 1), -- Valor predeterminado para usuario 1 si no está establecido
        NEW.ID_producto,
        CASE 
            WHEN NEW.Nombre <> OLD.Nombre THEN 'Cambio de nombre'
            WHEN NEW.Precio <> OLD.Precio THEN 'Cambio de precio'
            WHEN NEW.Stock_actual <> OLD.Stock_actual THEN 'Cambio de stock'
            ELSE 'Otra actualización'
        END,
        CASE 
            WHEN NEW.Nombre <> OLD.Nombre THEN OLD.Nombre
            WHEN NEW.Precio <> OLD.Precio THEN OLD.Precio::text
            WHEN NEW.Stock_actual <> OLD.Stock_actual THEN OLD.Stock_actual::text
            ELSE NULL
        END,
        CASE 
            WHEN NEW.Nombre <> OLD.Nombre THEN NEW.Nombre
            WHEN NEW.Precio <> OLD.Precio THEN NEW.Precio::text
            WHEN NEW.Stock_actual <> OLD.Stock_actual THEN NEW.Stock_actual::text
            ELSE NULL
        END,
        CASE 
            WHEN NEW.Nombre <> OLD.Nombre THEN 'Nombre'
            WHEN NEW.Precio <> OLD.Precio THEN 'Precio'
            WHEN NEW.Stock_actual <> OLD.Stock_actual THEN 'Stock'
            ELSE 'Otro'
        END
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para registrar actualizaciones de productos
CREATE TRIGGER trg_registrar_actualizacion_producto
AFTER UPDATE ON Productos
FOR EACH ROW
WHEN (NEW.Nombre <> OLD.Nombre OR NEW.Precio <> OLD.Precio OR NEW.Stock_actual <> OLD.Stock_actual)
EXECUTE FUNCTION fn_registrar_actualizacion_producto();

-- Función para calcular subtotal en detalles de venta
CREATE OR REPLACE FUNCTION fn_calcular_subtotal()
RETURNS TRIGGER AS $$
BEGIN
    NEW.Subtotal := (NEW.Cantidad * NEW.Precio_unitario) - COALESCE(NEW.Descuento, 0);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para calcular subtotal
CREATE TRIGGER trg_calcular_subtotal
BEFORE INSERT OR UPDATE ON Detalles_venta
FOR EACH ROW
EXECUTE FUNCTION fn_calcular_subtotal();

-- Función para actualizar total en ventas
CREATE OR REPLACE FUNCTION fn_actualizar_total_venta()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Ventas
    SET Total_venta = (
        SELECT COALESCE(SUM(Subtotal), 0)
        FROM Detalles_venta
        WHERE ID_venta = NEW.ID_venta
    )
    WHERE ID_venta = NEW.ID_venta;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar total en ventas
CREATE TRIGGER trg_actualizar_total_venta
AFTER INSERT OR UPDATE OR DELETE ON Detalles_venta
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_total_venta();

-- Función para registrar movimientos de inventario
CREATE OR REPLACE FUNCTION fn_registrar_movimiento_inventario(
    p_tipo VARCHAR,
    p_id_producto INTEGER,
    p_cantidad INTEGER,
    p_id_usuario INTEGER,
    p_observaciones TEXT
)
RETURNS VOID AS $$
DECLARE
    v_stock_actual INTEGER;
BEGIN
    -- Obtener stock actual
    SELECT Stock_actual INTO v_stock_actual
    FROM Productos
    WHERE ID_producto = p_id_producto;
    
    -- Actualizar stock según tipo de movimiento
    IF p_tipo = 'Entrada' THEN
        UPDATE Productos
        SET Stock_actual = Stock_actual + p_cantidad
        WHERE ID_producto = p_id_producto;
    ELSIF p_tipo = 'Salida' THEN
        IF v_stock_actual >= p_cantidad THEN
            UPDATE Productos
            SET Stock_actual = Stock_actual - p_cantidad
            WHERE ID_producto = p_id_producto;
        ELSE
            RAISE EXCEPTION 'Stock insuficiente para realizar la salida';
        END IF;
    ELSIF p_tipo = 'Ajuste' THEN
        UPDATE Productos
        SET Stock_actual = p_cantidad
        WHERE ID_producto = p_id_producto;
    ELSE
        RAISE EXCEPTION 'Tipo de movimiento no válido. Use Entrada, Salida o Ajuste';
    END IF;
    
    -- Registrar movimiento
    INSERT INTO Movimientos_inventario (
        Tipo_movimiento,
        Cantidad,
        ID_usuario,
        ID_producto,
        Observaciones
    )
    VALUES (
        p_tipo,
        p_cantidad,
        p_id_usuario,
        p_id_producto,
        p_observaciones
    );
END;
$$ LANGUAGE plpgsql;

-- Función para establecer usuario actual para registro
CREATE OR REPLACE FUNCTION fn_set_current_user(p_user_id INTEGER)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_user_id', p_user_id::text, false);
END;
$$ LANGUAGE plpgsql;

-- Procedimiento para resolver alertas de stock
CREATE OR REPLACE PROCEDURE sp_resolver_alerta(p_id_alerta INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Alertas_stock
    SET Estado = 'Resuelto',
        Fecha_resolucion = CURRENT_TIMESTAMP
    WHERE ID_alerta = p_id_alerta;
END;
$$;

-- Datos de muestra para pruebas

-- Insertar categorías de muestra
INSERT INTO Categorias (Nombre_categoria, Descripción)
VALUES
('Electrónicos', 'Productos electrónicos y tecnología'),
('Hogar', 'Artículos para el hogar'),
('Oficina', 'Materiales y equipos de oficina'),
('Alimentos', 'Productos alimenticios'),
('Ropa', 'Prendas de vestir y accesorios');

-- Insertar usuarios de muestra
INSERT INTO Usuarios (Nombre_usuario, Rol, Contraseña, Correo)
VALUES
('admin', 'Admin', '$2a$10$rPiEAgSa1y1R9HVVXNXQz.X1R1sLpRzWPJcJhvQqhXeBbY1qRiJK.', 'admin@vitisstore.com'),
('empleado1', 'Empleado', '$2a$10$fV8fvZdz8n0KA9FYlwjyqe5oM6hR6eCnzPCGOkFo5K0rsYhcnIrXO', 'empleado1@vitisstore.com');

-- Insertar productos de muestra
INSERT INTO Productos (Nombre, Descripción, Precio, Precio_compra, Stock_actual, Stock_minimo, ID_categoria)
VALUES
('Audífonos inalámbricos', 'Audífonos Bluetooth con cancelación de ruido', 89.99, 45.00, 25, 10, 1),
('Camiseta manga larga', 'Camiseta de algodón talla M', 29.99, 15.00, 40, 15, 5),
('Reloj de pulsera', 'Reloj casual resistente al agua', 59.99, 30.00, 15, 5, 5),
('Drone mini', 'Drone pequeño con cámara HD', 149.99, 80.00, 12, 4, 1),
('Control de videojuegos', 'Control compatible con consolas', 49.99, 25.00, 20, 8, 1);

-- Insertar configuración de sistema
INSERT INTO Configuracion_sistema (Nombre_parametro, Valor, Descripción)
VALUES
('dias_alerta_stock', '7', 'Días para alertar antes de quedarse sin stock'),
('correo_notificaciones', 'alertas@vitisstore.com', 'Correo para recibir notificaciones'),
('porcentaje_ganancia_defecto', '50', 'Porcentaje de ganancia por defecto para nuevos productos'),
('impuestos_activados', 'true', 'Indica si se aplican impuestos a las ventas');

-- Crear un rol para la aplicación
CREATE ROLE app_user WITH LOGIN PASSWORD 'app_password';

-- Otorgar privilegios
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO app_user;