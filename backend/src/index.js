const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
require('dotenv').config();

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
    const sql = 'SELECT * FROM empleado';
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

const bcrypt = require('bcrypt'); 

app.post('/registro', async (req, res) => {
    const { nombre_usuario, password, rol, id_empleado } = req.body;

    try {
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        const sql = 'INSERT INTO usuarios (nombre_usuario, password, rol, id_empleado) VALUES (?, ?, ?, ?)';

        db.query(sql, [nombre_usuario, passwordHash, rol, id_empleado], (err, result) => {
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

    try {
        const sql = 'SELECT * FROM usuarios WHERE nombre_usuario = ?';
        db.query(sql, [nombre_usuario], async (err, result) => {
            if (err) return res.status(500).json({ error: err.message });

            if (result.length === 0) {
                return res.status(401).json({ error: 'Usuario no encontrado' });
            }

            const usuario = result[0];

            const coinciden = await bcrypt.compare(password, usuario.password);

            if (!coinciden) {
                return res.status(401).json({ error: 'Contraseña incorrecta' });
            }

            res.json({
                mensaje: '¡Login exitoso!',
                usuario: {
                    id: usuario.id_usuario,
                    nombre: usuario.nombre_usuario,
                    rol: usuario.rol
                }
            });
        });
    } catch (error) {
        res.status(500).json({ error: 'Error en el servidor' });
    }
});

app.post('/fincas', (req, res) => {
    const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;
    const sql = 'INSERT INTO finca (nombre_finca, ubicacion, tamano_hectareas, propietario) VALUES (?, ?, ?, ?)';
    
    db.query(sql, [nombre_finca, ubicacion, tamano_hectareas, propietario], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ mensaje: 'Finca creada con éxito', id: result.insertId });
    });
});

app.get('/fincas', (req, res) => {
    const sql = 'SELECT * FROM finca';
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

app.put('/fincas/:id', (req, res) => {
    const { id } = req.params;
    const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;
    const sql = 'UPDATE finca SET nombre_finca = ?, ubicacion = ?, tamano_hectareas = ?, propietario = ? WHERE id_finca = ?';
    
    db.query(sql, [nombre_finca, ubicacion, tamano_hectareas, propietario, id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ mensaje: 'Finca actualizada correctamente' });
    });
});

app.delete('/fincas/:id', (req, res) => {
    const { id } = req.params;
    const sql = 'DELETE FROM finca WHERE id_finca = ?';
    
    db.query(sql, [id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ mensaje: 'Finca eliminada' });
    });
});

app.post('/lotes', (req, res) => {
    const { id_finca, nombre_lote, area, tipo_suelo } = req.body;
    const sql = 'INSERT INTO lote (id_finca, nombre_lote, area, tipo_suelo) VALUES (?, ?, ?, ?)';
    
    db.query(sql, [id_finca, nombre_lote, area, tipo_suelo], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ mensaje: 'Lote creado con éxito', id: result.insertId });
    });
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
    const sql = 'UPDATE lote SET nombre_lote = ?, area = ?, tipo_suelo = ? WHERE id_lote = ?';
    
    db.query(sql, [nombre_lote, area, tipo_suelo, id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ mensaje: 'Lote actualizado correctamente' });
    });
});

app.delete('/lotes/:id', (req, res) => {
    const { id } = req.params;
    const sql = 'DELETE FROM lote WHERE id_lote = ?';
    
    db.query(sql, [id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ mensaje: 'Lote eliminado' });
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});