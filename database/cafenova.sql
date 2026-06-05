-- 1. USUARIOS
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(50) UNIQUE NOT NULL,
    correo VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,

    rol ENUM('admin', 'empleado') DEFAULT 'empleado',
    estado ENUM('pendiente','activo','rechazado') DEFAULT 'pendiente',

    token VARCHAR(255),
    id_empleado INT UNIQUE,
    id_finca INT,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. FINCA
CREATE TABLE finca (
    id_finca INT AUTO_INCREMENT PRIMARY KEY,
    id_admin INT,

    nombre_finca VARCHAR(255),
    ubicacion VARCHAR(255),
    tamano_hectareas FLOAT,
    propietario VARCHAR(255),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_admin)
        REFERENCES usuarios(id_usuario)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- 3. EMPLEADO
CREATE TABLE empleado (
    id_empleado INT AUTO_INCREMENT PRIMARY KEY,

    id_finca INT,
    id_usuario INT UNIQUE,

    nombre VARCHAR(255),
    cargo VARCHAR(255),
    telefono VARCHAR(20),
    fecha_contratacion DATE,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_finca)
        REFERENCES finca(id_finca)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- RELACIONES EXTRA
ALTER TABLE usuarios
ADD FOREIGN KEY (id_empleado)
REFERENCES empleado(id_empleado)
ON DELETE SET NULL
ON UPDATE CASCADE;

ALTER TABLE usuarios
ADD FOREIGN KEY (id_finca)
REFERENCES finca(id_finca)
ON DELETE SET NULL
ON UPDATE CASCADE;

-- 4. LOTE
CREATE TABLE lote (
    id_lote INT AUTO_INCREMENT PRIMARY KEY,

    id_finca INT,

    nombre_lote VARCHAR(255),
    area FLOAT,
    tipo_suelo VARCHAR(255),

    FOREIGN KEY (id_finca)
        REFERENCES finca(id_finca)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 5. CULTIVO
CREATE TABLE cultivo (
    id_cultivo INT AUTO_INCREMENT PRIMARY KEY,

    id_lote INT,

    tipo_cultivo VARCHAR(255),
    variedad VARCHAR(255),
    fecha_siembra DATE,
    estado VARCHAR(50),

    FOREIGN KEY (id_lote)
        REFERENCES lote(id_lote)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 6. INVENTARIO (ACTUALIZADO)
CREATE TABLE inventario (
    id_insumo INT AUTO_INCREMENT PRIMARY KEY,

    id_finca INT,

    nombre_insumo VARCHAR(255),
    tipo VARCHAR(255),
    cantidad INT,
    unidad VARCHAR(50),

    FOREIGN KEY (id_finca)
        REFERENCES finca(id_finca)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 7. ACTIVIDAD
CREATE TABLE actividad (
    id_actividad INT AUTO_INCREMENT PRIMARY KEY,

    id_cultivo INT,
    id_empleado INT,

    tipo_actividad VARCHAR(255),
    fecha DATE,
    descripcion TEXT,

    FOREIGN KEY (id_cultivo)
        REFERENCES cultivo(id_cultivo)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (id_empleado)
        REFERENCES empleado(id_empleado)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- 8. COSECHA (ACTUALIZADA)
CREATE TABLE cosecha (
    id_cosecha INT AUTO_INCREMENT PRIMARY KEY,

    id_cultivo INT,
    id_finca INT,

    fecha_cosecha DATE,
    cantidad_kg FLOAT,
    calidad VARCHAR(50),

    FOREIGN KEY (id_cultivo)
        REFERENCES cultivo(id_cultivo)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (id_finca)
        REFERENCES finca(id_finca)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 9. PLAGA (CON LAS NUEVAS COLUMNAS INCORPORADAS)
CREATE TABLE plaga (
    id_plaga INT AUTO_INCREMENT PRIMARY KEY,

    id_cultivo INT,

    tipo_plaga VARCHAR(255),
    tratamiento TEXT,
    fecha_registro DATE,
    
    -- Nuevos campos agregados aquí:
    cantidad_aplicada DECIMAL(10,2),
    unidad VARCHAR(20),
    hectareas_fumigadas DECIMAL(10,2),

    FOREIGN KEY (id_cultivo)
        REFERENCES cultivo(id_cultivo)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 10. COSTO
CREATE TABLE costo (
    id_costo INT AUTO_INCREMENT PRIMARY KEY,

    id_cultivo INT,

    tipo_costo VARCHAR(255),
    monto FLOAT,
    fecha DATE,

    FOREIGN KEY (id_cultivo)
        REFERENCES cultivo(id_cultivo)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 11. USO INSUMO
CREATE TABLE uso_insumo (
    id_uso INT AUTO_INCREMENT PRIMARY KEY,

    id_actividad INT,
    id_insumo INT,

    cantidad_usada FLOAT,
    fecha DATE,

    FOREIGN KEY (id_actividad)
        REFERENCES actividad(id_actividad)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (id_insumo)
        REFERENCES inventario(id_insumo)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 12. REPORTE (ACTUALIZADO)
CREATE TABLE reporte (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,

    id_empleado INT,
    id_finca INT,

    titulo VARCHAR(255),
    descripcion TEXT,
    tipo_reporte VARCHAR(100),
    fecha DATE,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_empleado)
        REFERENCES empleado(id_empleado)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (id_finca)
        REFERENCES finca(id_finca)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 13. IA MENSAJES
CREATE TABLE ia_mensajes (
    id_mensaje INT AUTO_INCREMENT PRIMARY KEY,

    id_usuario INT,

    mensaje TEXT,
    respuesta TEXT,

    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
);

-- 14. CHAT
CREATE TABLE chat_mensajes (
    id_mensaje INT AUTO_INCREMENT PRIMARY KEY,

    id_remitente INT NOT NULL,
    id_destinatario INT NOT NULL,

    mensaje TEXT NOT NULL,
    fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    leido TINYINT(1) DEFAULT 0,

    FOREIGN KEY (id_remitente)
        REFERENCES empleado(id_empleado),

    FOREIGN KEY (id_destinatario)
        REFERENCES empleado(id_empleado)
);