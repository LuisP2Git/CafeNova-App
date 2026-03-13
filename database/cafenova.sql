USE cafenova;

CREATE TABLE finca (
    id_finca INT AUTO_INCREMENT PRIMARY KEY,
    nombre_finca VARCHAR(255),
    ubicacion VARCHAR(255),
    tamano_hectareas FLOAT,
    propietario VARCHAR(255),
    created_at DATETIME
);

CREATE TABLE empleado (
    id_empleado INT AUTO_INCREMENT PRIMARY KEY,
    id_finca INT,
    nombre VARCHAR(255),
    cargo VARCHAR(255),
    telefono VARCHAR(20),
    fecha_contratacion DATE,
    created_at DATETIME,
    FOREIGN KEY (id_finca) REFERENCES finca(id_finca)
);

CREATE TABLE lote (
    id_lote INT AUTO_INCREMENT PRIMARY KEY,
    id_finca INT,
    nombre_lote VARCHAR(255),
    area FLOAT,
    tipo_suelo VARCHAR(255),
    created_at DATETIME,
    FOREIGN KEY (id_finca) REFERENCES finca(id_finca)
);

CREATE TABLE cultivo (
    id_cultivo INT AUTO_INCREMENT PRIMARY KEY,
    id_lote INT,
    tipo_cultivo VARCHAR(255),
    variedad VARCHAR(255),
    fecha_siembra DATE,
    estado VARCHAR(50),
    created_at DATETIME,
    FOREIGN KEY (id_lote) REFERENCES lote(id_lote)
);

CREATE TABLE inventario (
    id_insumo INT AUTO_INCREMENT PRIMARY KEY,
    nombre_insumo VARCHAR(255),
    tipo VARCHAR(255),
    cantidad INT,
    unidad VARCHAR(50),
    created_at DATETIME
);

CREATE TABLE actividad (
    id_actividad INT AUTO_INCREMENT PRIMARY KEY,
    id_cultivo INT,
    id_empleado INT,
    tipo_actividad VARCHAR(255),
    fecha DATE,
    descripcion TEXT,
    created_at DATETIME,
    FOREIGN KEY (id_cultivo) REFERENCES cultivo(id_cultivo),
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);

CREATE TABLE uso_insumo (
    id_uso INT AUTO_INCREMENT PRIMARY KEY,
    id_actividad INT,
    id_insumo INT,
    cantidad_usada FLOAT,
    fecha DATE,
    FOREIGN KEY (id_actividad) REFERENCES actividad(id_actividad),
    FOREIGN KEY (id_insumo) REFERENCES inventario(id_insumo)
);

CREATE TABLE cosecha (
    id_cosecha INT AUTO_INCREMENT PRIMARY KEY,
    id_cultivo INT,
    fecha_cosecha DATE,
    cantidad_kg FLOAT,
    calidad VARCHAR(50),
    created_at DATETIME,
    FOREIGN KEY (id_cultivo) REFERENCES cultivo(id_cultivo)
);

CREATE TABLE plaga (
    id_plaga INT AUTO_INCREMENT PRIMARY KEY,
    id_cultivo INT,
    tipo_plaga VARCHAR(255),
    tratamiento TEXT,
    fecha_registro DATE,
    created_at DATETIME,
    FOREIGN KEY (id_cultivo) REFERENCES cultivo(id_cultivo)
);

CREATE TABLE costo (
    id_costo INT AUTO_INCREMENT PRIMARY KEY,
    id_cultivo INT,
    tipo_costo VARCHAR(255),
    monto FLOAT,
    fecha DATE,
    created_at DATETIME,
    FOREIGN KEY (id_cultivo) REFERENCES cultivo(id_cultivo)
);