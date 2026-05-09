const db = require('../config/db');

/** GET /usuarios/pendientes — Obtener usuarios con estado pendiente */
function obtenerPendientes(req, res) {
    db.query(
        "SELECT id_usuario, nombre_usuario, correo FROM usuarios WHERE estado = 'pendiente'",
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
}

/** PUT /usuarios/aprobar/:id — Aprobar usuario */
function aprobarUsuario(req, res) {
    const { id } = req.params;

    db.query(
        "UPDATE usuarios SET estado = 'activo' WHERE id_usuario = ?",
        [id],
        (err) => {
            if (err) {
                console.log('ERROR:', err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ message: 'Usuario aprobado correctamente' });
        }
    );
}

/** DELETE /usuarios/:id — Rechazar / eliminar usuario */
function eliminarUsuario(req, res) {
    const { id } = req.params;

    db.query(
        'DELETE FROM usuarios WHERE id_usuario = ?',
        [id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Usuario eliminado' });
        }
    );
}

module.exports = { obtenerPendientes, aprobarUsuario, eliminarUsuario };
