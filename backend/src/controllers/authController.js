const bcrypt = require('bcrypt');
const crypto = require('crypto');
const db     = require('../config/db');

/**
 * POST /registro
 * Registra un nuevo usuario y crea el empleado asociado.
 */
async function registro(req, res) {
    const { nombre_usuario, correo, password, cargo, telefono, fecha_contratacion, id_finca } = req.body;

    if (!nombre_usuario || !correo || !password) {
        return res.status(400).json({ error: 'Datos incompletos' });
    }

    try {
        const hash = await bcrypt.hash(password, 10);

        db.beginTransaction((err) => {
            if (err) return res.status(500).json({ error: err.message });

            // 1. Insertar usuario
            db.query(
                `INSERT INTO usuarios (nombre_usuario, correo, password, rol, estado)
                 VALUES (?, ?, ?, 'empleado', 'pendiente')`,
                [nombre_usuario, correo, hash],
                (err, result) => {
                    if (err) {
                        return db.rollback(() =>
                            res.status(500).json({ error: err.message })
                        );
                    }

                    const id_usuario = result.insertId;

                    // 2. Insertar empleado
                    db.query(
                        `INSERT INTO empleado 
                         (id_usuario, nombre, cargo, telefono, fecha_contratacion, id_finca)
                         VALUES (?, ?, ?, ?, ?, ?)`,
                        [
                            id_usuario,
                            nombre_usuario,
                            cargo              || 'Sin asignar',
                            telefono           || null,
                            fecha_contratacion || null,
                            id_finca           || null
                        ],
                        (err2) => {
                            if (err2) {
                                return db.rollback(() =>
                                    res.status(500).json({ error: err2.message })
                                );
                            }

                            db.commit((err3) => {
                                if (err3) {
                                    return db.rollback(() =>
                                        res.status(500).json({ error: err3.message })
                                    );
                                }
                                res.json({ mensaje: 'Registro exitoso' });
                            });
                        }
                    );
                }
            );
        });

    } catch {
        res.status(500).json({ error: 'Error servidor' });
    }
}

/**
 * POST /login
 * Autentica un usuario y devuelve un token.
 */
async function login(req, res) {
    const { identificador, password } = req.body;

    db.query(
        'SELECT * FROM usuarios WHERE nombre_usuario = ? OR correo = ?',
        [identificador, identificador],
        async (err, result) => {
            if (err)               return res.status(500).json({ error: err.message });
            if (result.length === 0) return res.status(401).json({ error: 'No existe' });

            const user  = result[0];
            const match = await bcrypt.compare(password, user.password);

            if (!match)              return res.status(401).json({ error: 'Incorrecto' });
            if (user.estado !== 'activo') return res.status(403).json({ error: 'Pendiente' });

            const token = crypto.randomBytes(32).toString('hex');

            db.query(
                'UPDATE usuarios SET token=? WHERE id_usuario=?',
                [token, user.id_usuario],
                () => {
                    res.json({ token, usuario: user });
                }
            );
        }
    );
}

module.exports = { registro, login };
