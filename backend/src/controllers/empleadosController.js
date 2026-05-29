const db = require('../config/db');

/** GET /empleados — Obtener empleados del admin autenticado */
function obtenerEmpleados(req, res) {

    db.query(
        `
        SELECT 
            e.id_empleado,
            e.cargo,
            e.telefono,
            e.fecha_contratacion,
            e.id_finca,
            u.nombre_usuario AS nombre,
            u.correo,
            f.nombre_finca
        FROM empleado e
        JOIN usuarios u
            ON e.id_usuario = u.id_usuario
        LEFT JOIN finca f
            ON e.id_finca = f.id_finca
        WHERE (f.id_admin = ? OR e.id_finca IS NULL)
        AND u.estado = 'activo'
        `,
        [req.usuario.id_usuario],
        (err, results) => {

            if (err) {
                console.log(err);

                return res.status(500).json({
                    error: err.message
                });
            }

            res.json(results);
        }
    );
}

/** PUT /empleados/:id — Actualizar empleado */
function actualizarEmpleado(req, res) {

    const { id } = req.params;

    const {
        cargo,
        telefono,
        fecha_contratacion,
        id_finca
    } = req.body;

    // Verificar que la finca pertenezca al admin
    db.query(
        `
        SELECT *
        FROM finca
        WHERE id_finca = ?
        AND id_admin = ?
        `,
        [id_finca, req.usuario.id_usuario],
        (err, fincaResult) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (fincaResult.length === 0) {
                return res.status(403).json({
                    error: 'No puede asignar esa finca'
                });
            }

            db.query(
                `
                UPDATE empleado
                SET
                    cargo = ?,
                    telefono = ?,
                    fecha_contratacion = ?,
                    id_finca = ?
                WHERE id_empleado = ?
                `,
                [
                    cargo,
                    telefono,
                    fecha_contratacion,
                    id_finca,
                    id
                ],
                (err, result) => {

                    if (err) {
                        return res.status(500).json({
                            error: err.message
                        });
                    }

                    if (result.affectedRows === 0) {
                        return res.status(404).json({
                            error: 'Empleado no encontrado'
                        });
                    }

                    res.json({
                        message: 'Empleado actualizado correctamente'
                    });
                }
            );
        }
    );
}

/** DELETE /empleados/:id — Eliminar empleado */
function eliminarEmpleado(req, res) {

    const { id } = req.params;

    db.query(
        `
        DELETE FROM empleado
        WHERE id_empleado = ?
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
                    error: 'Empleado no encontrado'
                });
            }

            res.json({
                message: 'Empleado eliminado correctamente'
            });
        }
    );
}

module.exports = {
    obtenerEmpleados,
    actualizarEmpleado,
    eliminarEmpleado
};