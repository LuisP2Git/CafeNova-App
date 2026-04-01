const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
require('dotenv').config();
const bcrypt = require('bcrypt');
const crypto = require('crypto');

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'cafenova'
});

db.connect(err => {
    if (err) return console.error(err);
    console.log('DB conectada');
});

function verificarToken(req, res, next) {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Token requerido' });

    db.query('SELECT * FROM usuarios WHERE token = ?', [token], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        if (result.length === 0) return res.status(401).json({ error: 'Token inválido' });
        req.usuario = result[0];
        next();
    });
}

function soloAdmin(req, res, next) {
    if (req.usuario.rol !== 'admin') {
        return res.status(403).json({ error: 'Solo admin' });
    }
    next();
}

app.post('/registro', async (req, res) => {
    const { nombre_usuario, correo, password } = req.body;

    if (!nombre_usuario || !correo || !password) {
        return res.status(400).json({ error: 'Datos incompletos' });
    }

    try {
        const hash = await bcrypt.hash(password, 10);

        const sql = `
            INSERT INTO usuarios (nombre_usuario, correo, password, rol, estado)
            VALUES (?, ?, ?, 'empleado', 'pendiente')
        `;

        db.query(sql, [nombre_usuario, correo, hash], (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ mensaje: 'Registro exitoso, espera aprobación' });
        });

    } catch {
        res.status(500).json({ error: 'Error servidor' });
    }
});

app.post('/login', async (req, res) => {
    const { identificador, password } = req.body;

    if (!identificador || !password) {
        return res.status(400).json({ error: 'Datos incompletos' });
    }

    const sql = 'SELECT * FROM usuarios WHERE nombre_usuario = ? OR correo = ?';

    db.query(sql, [identificador, identificador], async (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        if (result.length === 0) return res.status(401).json({ error: 'Usuario no encontrado' });

        const user = result[0];

        const match = await bcrypt.compare(password, user.password);
        if (!match) return res.status(401).json({ error: 'Datos incorrectos' });

        if (user.estado !== 'activo') {
            return res.status(403).json({ error: 'Cuenta pendiente de aprobación' });
        }

        const token = crypto.randomBytes(32).toString('hex');

        db.query(
            'UPDATE usuarios SET token = ? WHERE id_usuario = ?',
            [token, user.id_usuario],
            () => {
                res.json({
                    mensaje: 'Login exitoso',
                    token,
                    usuario: {
                        id: user.id_usuario,
                        nombre: user.nombre_usuario,
                        correo: user.correo,
                        rol: user.rol
                    }
                });
            }
        );
    });
});

app.post('/logout', verificarToken, (req, res) => {
    db.query(
        'UPDATE usuarios SET token = NULL WHERE id_usuario = ?',
        [req.usuario.id_usuario],
        () => {
            res.json({ mensaje: 'Logout correcto' });
        }
    );
});

app.get('/usuarios/pendientes', verificarToken, soloAdmin, (req, res) => {
    db.query(`
            SELECT u.* FROM usuarios u WHERE u.estado = "pendiente"`, 
            (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(result);
        }
    );
});

app.put('/usuarios/:id/aprobar', verificarToken, soloAdmin, (req, res) => {
    const { id } = req.params;
    const { rol, id_finca, cargo, telefono, fecha_contratacion } = req.body;

    db.query('SELECT * FROM usuarios WHERE id_usuario = ?', [id], (err, result) => {
        if (result.length === 0) return res.status(404).json({ error: 'No existe' });

        const user = result[0];

        db.query(
            'UPDATE usuarios SET estado="activo", rol=? WHERE id_usuario=?',
            [rol || 'empleado', id]
        );

        db.query(
            `INSERT INTO empleado 
            (id_finca, id_usuario, nombre, cargo, telefono, fecha_contratacion) 
            VALUES (?, ?, ?, ?, ?, ?)`,
            [
                id_finca,
                user.id_usuario,
                user.nombre_usuario,
                cargo || null,
                telefono || null,
                fecha_contratacion || null
            ]
        );

        res.json({ mensaje: 'Usuario aprobado' });
    });
});

app.put('/usuarios/:id/rechazar', verificarToken, soloAdmin, (req, res) => {
    db.query(
        'UPDATE usuarios SET estado="rechazado" WHERE id_usuario=?',
        [req.params.id],
        () => res.json({ mensaje: 'Usuario rechazado' })
    );
});

app.get('/empleados', verificarToken, soloAdmin, (req, res) => {
    db.query(
        `
        SELECT e.*, f.nombre_finca
        FROM empleado e
        LEFT JOIN finca f ON e.id_finca = f.id_finca
        WHERE f.id_admin = ? OR e.id_finca IS NULL
        `,
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
});

app.put('/empleados/:id', verificarToken, soloAdmin, (req, res) => {
    const { id } = req.params;
    let { cargo, telefono, fecha_contratacion, id_finca } = req.body;
    if (!fecha_contratacion || fecha_contratacion === '') {
        fecha_contratacion = null;
    }
    db.query(
    `UPDATE empleado
            SET cargo = ?, telefono = ?, fecha_contratacion = ?, id_finca = ?
            WHERE id_empleado = ?`,
        [cargo, telefono, fecha_contratacion, id_finca, id],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ mensaje: 'Empleado actualizado' });
        }
    );
});

app.delete('/empleados/:id', verificarToken, soloAdmin, (req, res) => {
    const { id } = req.params;
    db.query(
        'UPDATE usuarios SET id_empleado = NULL WHERE id_empleado = ?',
        [id],
        (err) => {
        if (err) return res.status(500).json({ error: err.message });
        db.query(
            'DELETE FROM empleado WHERE id_empleado = ?',
            [id],
            (err, result) => {
                if (err) return res.status(500).json({ error: err.message });
                res.json({ mensaje: 'Empleado eliminado' });
                }
            );
        }
    );
});

app.post('/fincas', verificarToken, soloAdmin, (req, res) => {
    const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;

    db.query(
        'INSERT INTO finca (nombre_finca, ubicacion, tamano_hectareas, propietario, id_admin) VALUES (?, ?, ?, ?, ?)',
        [nombre_finca, ubicacion, tamano_hectareas, propietario, req.usuario.id_usuario],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );
});

app.get('/fincas', verificarToken, soloAdmin, (req, res) => {
    db.query(
        'SELECT * FROM finca WHERE id_admin = ?',
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
});

app.post('/lotes', verificarToken, soloAdmin, (req, res) => {
    const { nombre_lote, area, tipo_suelo } = req.body;

    db.query(
        'INSERT INTO lote (id_finca, nombre_lote, area, tipo_suelo) VALUES (?, ?, ?, ?)',
        [req.usuario.id_finca, nombre_lote, area, tipo_suelo],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );});

app.get('/lotes', verificarToken, (req, res) => {
    db.query(
        'SELECT * FROM lote WHERE id_finca = ?',
        [req.usuario.id_finca],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );});

app.put('/lotes/:id', verificarToken, soloAdmin, (req, res) => {
    const { id } = req.params; const { nombre_lote, area, tipo_suelo } = req.body;
    db.query(
        'UPDATE lote SET nombre_lote=?, area=?, tipo_suelo=? WHERE id_lote=?',
        [nombre_lote, area, tipo_suelo, id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ mensaje: 'Actualizado' });
        }
    );});

app.delete('/lotes/:id', verificarToken, soloAdmin, (req, res) => {
    db.query(
        'DELETE FROM lote WHERE id_lote=?',
        [req.params.id],
        () => res.json({ mensaje: 'Eliminado' })
    );});

app.post('/cultivos', verificarToken, (req, res) => {
    const { id_lote, tipo_cultivo, variedad, fecha_siembra, estado } = req.body;
    db.query(
        'INSERT INTO cultivo (id_lote, tipo_cultivo, variedad, fecha_siembra, estado) VALUES (?, ?, ?, ?, ?)',
        [id_lote, tipo_cultivo, variedad, fecha_siembra, estado],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );
});

app.get('/cultivos', verificarToken, (req, res) => {
    db.query(
        `SELECT c.* FROM cultivo c 
        JOIN lote l ON c.id_lote = l.id_lote 
        WHERE l.id_finca = ?`,
        [req.usuario.id_finca],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );});

app.post('/actividad', verificarToken, (req, res) => {
    const { id_cultivo, tipo_actividad, fecha, descripcion } = req.body;

    db.query(
        'INSERT INTO actividad (id_cultivo, id_empleado, tipo_actividad, fecha, descripcion) VALUES (?, ?, ?, ?, ?)',
        [id_cultivo, req.usuario.id_empleado, tipo_actividad, fecha, descripcion],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );});

app.post('/cosecha', verificarToken, (req, res) => {
    const { id_cultivo, fecha_cosecha, cantidad_kg, calidad } = req.body;
    db.query(
        'INSERT INTO cosecha (id_cultivo, fecha_cosecha, cantidad_kg, calidad) VALUES (?, ?, ?, ?)',
        [id_cultivo, fecha_cosecha, cantidad_kg, calidad],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );});

app.post('/plaga', verificarToken, (req, res) => {
    const { id_cultivo, tipo_plaga, tratamiento, fecha_registro } = req.body;
    db.query(
        'INSERT INTO plaga (id_cultivo, tipo_plaga, tratamiento, fecha_registro) VALUES (?, ?, ?, ?)',
        [id_cultivo, tipo_plaga, tratamiento, fecha_registro],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );
});

app.post('/costo', verificarToken, (req, res) => {
    const { id_cultivo, tipo_costo, monto, fecha } = req.body;

    db.query(
        'INSERT INTO costo (id_cultivo, tipo_costo, monto, fecha) VALUES (?, ?, ?, ?)',
        [id_cultivo, tipo_costo, monto, fecha],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );
});

app.post('/inventario', verificarToken, (req, res) => {
    const { nombre_insumo, tipo, cantidad, unidad } = req.body;

    db.query(
        'INSERT INTO inventario (nombre_insumo, tipo, cantidad, unidad) VALUES (?, ?, ?, ?)',
        [nombre_insumo, tipo, cantidad, unidad],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );});

app.post('/uso_insumo', verificarToken, (req, res) => {
    const { id_actividad, id_insumo, cantidad_usada, fecha } = req.body;

    db.query(
        'INSERT INTO uso_insumo (id_actividad, id_insumo, cantidad_usada, fecha) VALUES (?, ?, ?, ?)',
        [id_actividad, id_insumo, cantidad_usada, fecha],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );
});

app.post('/reporte', verificarToken, (req, res) => {
    const { titulo, descripcion, tipo_reporte, fecha } = req.body;

    db.query(
        'INSERT INTO reporte (id_empleado, titulo, descripcion, tipo_reporte, fecha) VALUES (?, ?, ?, ?, ?)',
        [req.usuario.id_empleado, titulo, descripcion, tipo_reporte, fecha],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: result.insertId });
        }
    );});

app.listen(3000, () => console.log('Servidor corriendo en http://localhost:3000'));