const bcrypt = require('bcrypt');
const crypto = require('crypto');
const db = require('../config/db');
const ROLES = require('../constants/roles');

/**
 * POST /registro
 * Registra un nuevo usuario y crea el empleado asociado.
 */
async function registro(req, res) {

    const {
        nombre_usuario,
        correo,
        password,
        cargo,
        telefono,
        fecha_contratacion,
        id_finca
    } = req.body;

    let fincaAsignada = id_finca;

if (cargo === 'Administrador') {
    fincaAsignada = null;
}

    const rolesPermitidos = Object.values(ROLES);

    if (cargo && !rolesPermitidos.includes(cargo)) {
        return res.status(400).json({
            error: 'Cargo inválido'
        });
    }

    if (!nombre_usuario || !correo || !password) {
        return res.status(400).json({
            error: 'Datos incompletos'
        });
    }

    try {

        const hash = await bcrypt.hash(password, 10);

        db.beginTransaction((err) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            // Crear usuario
            db.query(
                `
                INSERT INTO usuarios (
                    nombre_usuario,
                    correo,
                    password,
                    rol,
                    estado
                )
                VALUES (
                    ?, ?, ?, 'empleado', 'pendiente'
                )
                `,
                [
                    nombre_usuario,
                    correo,
                    hash
                ],
                (err, resultUsuario) => {

                    if (err) {
                        return db.rollback(() =>
                            res.status(500).json({
                                error: err.message
                            })
                        );
                    }

                    const id_usuario = resultUsuario.insertId;

                    // Crear empleado
                    db.query(
                        `
                        INSERT INTO empleado (
                            id_usuario,
                            nombre,
                            cargo,
                            telefono,
                            fecha_contratacion,
                            id_finca
                        )
                        VALUES (?, ?, ?, ?, ?, ?)
                        `,
                        [
                            [
                            id_usuario,
                            nombre_usuario,
                            cargo || 'Sin asignar',
                            telefono || null,
                            fecha_contratacion || null,
                            fincaAsignada
]
                        ],
                        (err2, resultEmpleado) => {

                            if (err2) {
                                return db.rollback(() =>
                                    res.status(500).json({
                                        error: err2.message
                                    })
                                );
                            }

                            const id_empleado = resultEmpleado.insertId;

                            // Relacionar usuario con empleado
                            db.query(
                                `
                                UPDATE usuarios
                                SET id_empleado = ?
                                WHERE id_usuario = ?
                                `,
                                [
                                    id_empleado,
                                    id_usuario
                                ],
                                (err3) => {

                                    if (err3) {
                                        return db.rollback(() =>
                                            res.status(500).json({
                                                error: err3.message
                                            })
                                        );
                                    }

                                    db.commit((err4) => {

                                        if (err4) {
                                            return db.rollback(() =>
                                                res.status(500).json({
                                                    error: err4.message
                                                })
                                            );
                                        }

                                        res.json({
                                            mensaje: 'Registro exitoso'
                                        });
                                    });
                                }
                            );
                        }
                    );
                }
            );
        });

    } catch (error) {

        console.log(error);

        res.status(500).json({
            error: 'Error servidor'
        });
    }
}

/**
 * POST /login
 * Autentica usuario y devuelve token.
 */
async function login(req, res) {

    const {
        identificador,
        password
    } = req.body;

    db.query(
        `
        SELECT
            u.*,
            e.cargo,
            e.id_finca,
            e.id_empleado
        FROM usuarios u
        LEFT JOIN empleado e
            ON u.id_usuario = e.id_usuario
        WHERE u.nombre_usuario = ?
        OR u.correo = ?
        `,
        [
            identificador,
            identificador
        ],
        async (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.length === 0) {
                return res.status(401).json({
                    error: 'Usuario no existe'
                });
            }

            const user = result[0];

            const match = await bcrypt.compare(
                password,
                user.password
            );

            if (!match) {
                return res.status(401).json({
                    error: 'Contraseña incorrecta'
                });
            }

            if (user.estado !== 'activo') {
                return res.status(403).json({
                    error: 'Usuario pendiente de aprobación'
                });
            }

            const token = crypto
                .randomBytes(32)
                .toString('hex');

            db.query(
                `
                UPDATE usuarios
                SET token = ?
                WHERE id_usuario = ?
                `,
                [
                    token,
                    user.id_usuario
                ],
                (err2) => {

                    if (err2) {
                        return res.status(500).json({
                            error: err2.message
                        });
                    }

                    res.json({
                        token,
                        usuario: {
                            id_usuario: user.id_usuario,
                            nombre_usuario: user.nombre_usuario,
                            correo: user.correo,
                            rol: user.rol,
                            estado: user.estado,
                            cargo: user.cargo,
                            id_finca: user.id_finca,
                            id_empleado: user.id_empleado
                        }
                    });
                }
            );
        }
    );
}

module.exports = {
    registro,
    login
};