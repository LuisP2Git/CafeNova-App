const db = require('../config/db');

/** GET /usuarios/pendientes */
function obtenerPendientes(req, res) {

    db.query(
        `
        SELECT
            id_usuario,
            nombre_usuario,
            correo
        FROM usuarios
        WHERE estado = 'pendiente'
        `,
        (err, results) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            res.json(results);
        }
    );
}

/** PUT /usuarios/aprobar/:id */
function aprobarUsuario(req, res) {

    const { id } = req.params;

    const {
        rol,
        cargo,
        id_finca
    } = req.body;

    if (!cargo || !id_finca) {
        return res.status(400).json({
            error: 'Debe asignar cargo y finca'
        });
    }

    db.query(
        `
        SELECT *
        FROM empleado
        WHERE id_usuario = ?
        `,
        [id],
        (err, empleadoResult) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (empleadoResult.length === 0) {
                return res.status(404).json({
                    error: 'Empleado no encontrado'
                });
            }

            db.beginTransaction((err) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                db.query(
                    `
                    UPDATE usuarios
                    SET
                        estado = 'activo',
                        rol = ?
                    WHERE id_usuario = ?
                    `,
                    [
                        rol || 'empleado',
                        id
                    ],
                    (err2) => {

                        if (err2) {
                            return db.rollback(() =>
                                res.status(500).json({
                                    error: err2.message
                                })
                            );
                        }

                        db.query(
                            `
                            UPDATE empleado
                            SET
                                cargo = ?,
                                id_finca = ?
                            WHERE id_usuario = ?
                            `,
                            [
                                cargo,
                                id_finca,
                                id
                            ],
                            (err3) => {

                                if (err3) {
                                    return db.rollback(() =>
                                        res.status(500).json({
                                            error: err3.message
                                        })
                                    );
                                }

                                db.query(
                                    `
                                    UPDATE usuarios
                                    SET id_finca = ?
                                    WHERE id_usuario = ?
                                    `,
                                    [
                                        id_finca,
                                        id
                                    ],
                                    (err4) => {

                                        if (err4) {
                                            return db.rollback(() =>
                                                res.status(500).json({
                                                    error: err4.message
                                                })
                                            );
                                        }

                                        db.commit((err5) => {

                                            if (err5) {
                                                return db.rollback(() =>
                                                    res.status(500).json({
                                                        error: err5.message
                                                    })
                                                );
                                            }

                                            res.json({
                                                message:
                                                    'Usuario aprobado correctamente'
                                            });
                                        });
                                    }
                                );
                            }
                        );
                    }
                );
            });
        }
    );
}

/** DELETE /usuarios/:id */
function eliminarUsuario(req, res) {

    const { id } = req.params;

    db.query(
        `
        DELETE FROM usuarios
        WHERE id_usuario = ?
        `,
        [id],
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    error: 'Usuario no encontrado'
                });
            }

            res.json({
                message: 'Usuario eliminado'
            });
        }
    );
}

module.exports = {
    obtenerPendientes,
    aprobarUsuario,
    eliminarUsuario
};