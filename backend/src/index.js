const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
require('dotenv').config();
const bcrypt = require('bcrypt');

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
    if (err) {
        console.error('Error conectando a la DB:', err);
        return;
    }
    console.log('Conectado a la base de datos MySQL');
});

app.get('/empleados', (req, res) => {
    db.query('SELECT * FROM empleado', (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

app.post('/registro', async (req, res) => {
    const { nombre_usuario, correo, password, rol, id_empleado } = req.body;

    if (!nombre_usuario || !correo || !password) {
        return res.status(400).json({ error: 'Datos incompletos' });
    }

    try {
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        const sql = 'INSERT INTO usuarios (nombre_usuario, correo, password, rol, id_empleado) VALUES (?, ?, ?, ?, ?)';

        db.query(sql, [nombre_usuario, correo, passwordHash, rol, id_empleado], (err, result) => {
            if (err) {
                return res.status(500).json({ error: 'Error al registrar usuario: ' + err.message });
            }
            res.status(201).json({ mensaje: '¡Usuario registrado con éxito!', id: result.insertId });
        });

    } catch (error) {
        res.status(500).json({ error: 'Error en el servidor' });
    }
});

app.post('/login', async (req, res) => {
    const { nombre_usuario, password } = req.body;

    if (!nombre_usuario || !password) {
        return res.status(400).json({ error: 'Datos incompletos' });
    }

    try {
        const sql = 'SELECT * FROM usuarios WHERE nombre_usuario = ? OR correo = ?';
        db.query(sql, [nombre_usuario, nombre_usuario], async (err, result) => {
            if (err) return res.status(500).json({ error: err.message });

            if (result.length === 0) {
                return res.status(401).json({ error: 'Usuario no encontrado' });
            }

            const user = result[0];
            const coinciden = await bcrypt.compare(password, user.password);

            if (!coinciden) {
                return res.status(401).json({ error: 'Datos incorrectos' });
            }

            if (user.token) {
                return res.status(403).json({ error: 'Sesión ya activa en otro dispositivo' });
            }

            const token = Math.random().toString(36).substring(2);
            db.query(
                'UPDATE usuarios SET token = ? WHERE id_usuario = ?',
                [token, user.id_usuario],
                (err) => {
                    if (err) return res.status(500).json({ error: err.message });
                    res.json({
                        mensaje: 'Login exitoso',
                        token: token,
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
    } catch (error) {
        res.status(500).json({ error: 'Error en el servidor' });
    }
});

app.post('/logout', (req, res) => {
    const { token } = req.body;

    if (!token) {
        return res.status(400).json({ error: 'Token requerido' });
    }

    db.query(
        'UPDATE usuarios SET token = NULL WHERE token = ?',
        [token],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });

            if (result.affectedRows === 0) {
                return res.status(404).json({ error: 'Token no válido' });
            }

            res.json({ mensaje: 'Sesión cerrada correctamente' });
        }
    );
});

app.post('/fincas', (req, res) => {
    const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;

    db.query(
        'INSERT INTO finca (nombre_finca, ubicacion, tamano_hectareas, propietario) VALUES (?, ?, ?, ?)',
        [nombre_finca, ubicacion, tamano_hectareas, propietario],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.status(201).json({ mensaje: 'Finca creada con éxito', id: result.insertId });
        }
    );
});

app.get('/fincas', (req, res) => {
    db.query('SELECT * FROM finca', (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

app.put('/fincas/:id', (req, res) => {
    const { id } = req.params;
    const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;

    db.query(
        'UPDATE finca SET nombre_finca = ?, ubicacion = ?, tamano_hectareas = ?, propietario = ? WHERE id_finca = ?',
        [nombre_finca, ubicacion, tamano_hectareas, propietario, id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ mensaje: 'Finca actualizada correctamente' });
        }
    );
});

app.delete('/fincas/:id', (req, res) => {
    const { id } = req.params;

    db.query('DELETE FROM finca WHERE id_finca = ?', [id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ mensaje: 'Finca eliminada' });
    });
});

app.post('/lotes', (req, res) => {
    const { id_finca, nombre_lote, area, tipo_suelo } = req.body;

    db.query(
        'INSERT INTO lote (id_finca, nombre_lote, area, tipo_suelo) VALUES (?, ?, ?, ?)',
        [id_finca, nombre_lote, area, tipo_suelo],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.status(201).json({ mensaje: 'Lote creado con éxito', id: result.insertId });
        }
    );
});

app.get('/lotes', (req, res) => {
    const sql = `
        SELECT l.*, f.nombre_finca 
        FROM lote l 
        JOIN finca f ON l.id_finca = f.id_finca
    `;

    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

app.put('/lotes/:id', (req, res) => {
    const { id } = req.params;
    const { nombre_lote, area, tipo_suelo } = req.body;

    db.query(
        'UPDATE lote SET nombre_lote = ?, area = ?, tipo_suelo = ? WHERE id_lote = ?',
        [nombre_lote, area, tipo_suelo, id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ mensaje: 'Lote actualizado correctamente' });
        }
    );
});

app.delete('/lotes/:id', (req, res) => {
    const { id } = req.params;

    db.query('DELETE FROM lote WHERE id_lote = ?', [id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ mensaje: 'Lote eliminado' });
    });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});