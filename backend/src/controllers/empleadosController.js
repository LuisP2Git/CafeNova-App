const db = require('../config/db');

/** GET /empleados — Obtener empleados del admin autenticado */
function obtenerEmpleados(req, res) {
    db.query(
        `SELECT 
            e.id_empleado,
            e.cargo,
            e.telefono,
            e.fecha_contratacion,
            e.id_finca,
            u.nombre_usuario AS nombre,
            u.correo,
            f.nombre_finca
         FROM empleado e
         JOIN usuarios u ON e.id_usuario = u.id_usuario
         LEFT JOIN finca f ON e.id_finca = f.id_finca
         WHERE (f.id_admin = ? OR e.id_finca IS NULL)
           AND u.estado = 'activo'`,
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }
            res.json(results);
        }
    );
}

/** PUT /empleados/:id — Actualizar empleado */
function actualizarEmpleado(req, res) {
    const { id } = req.params;
    const { cargo, telefono, fecha_contratacion, id_finca } = req.body;

    db.query(
        `UPDATE empleado 
         SET cargo = ?, telefono = ?, fecha_contratacion = ?, id_finca = ?
         WHERE id_empleado = ?`,
        [cargo, telefono, fecha_contratacion, id_finca, id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Empleado actualizado' });
        }
    );
}

/** DELETE /empleados/:id — Eliminar empleado */
function eliminarEmpleado(req, res) {
    const { id } = req.params;

    db.query(
        'DELETE FROM empleado WHERE id_empleado = ?',
        [id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Empleado eliminado' });
        }
    );
}

module.exports = { obtenerEmpleados, actualizarEmpleado, eliminarEmpleado };
