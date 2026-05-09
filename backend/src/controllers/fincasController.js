const db = require('../config/db');

/** POST /fincas — Crear finca */
function crearFinca(req, res) {
    const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;

    db.query(
        'INSERT INTO finca (nombre_finca, ubicacion, tamano_hectareas, propietario, id_admin) VALUES (?, ?, ?, ?, ?)',
        [nombre_finca, ubicacion, tamano_hectareas, propietario, req.usuario.id_usuario],
        (err, result) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ id: result.insertId });
        }
    );
}

/** GET /fincas — Obtener fincas del admin autenticado */
function obtenerFincas(req, res) {
    db.query(
        'SELECT * FROM finca WHERE id_admin = ?',
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
}

/** PUT /fincas/:id — Actualizar finca */
function actualizarFinca(req, res) {
    const { id } = req.params;
    const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;

    db.query(
        `UPDATE finca 
         SET nombre_finca = ?, ubicacion = ?, tamano_hectareas = ?, propietario = ?
         WHERE id_finca = ?`,
        [nombre_finca, ubicacion, tamano_hectareas, propietario, id],
        (err) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ message: 'Finca actualizada' });
        }
    );
}

/** DELETE /fincas/:id — Eliminar finca (y sus lotes en cascada) */
function eliminarFinca(req, res) {
    const { id } = req.params;

    db.query('DELETE FROM lote WHERE id_finca = ?', [id], (err) => {
        if (err) {
            console.log('Error eliminando lotes:', err);
            return res.status(500).json({ error: err.message });
        }

        db.query('DELETE FROM finca WHERE id_finca = ?', [id], (err2) => {
            if (err2) {
                console.log('Error eliminando finca:', err2);
                return res.status(500).json({ error: err2.message });
            }
            res.json({ message: 'Finca eliminada correctamente' });
        });
    });
}

module.exports = { crearFinca, obtenerFincas, actualizarFinca, eliminarFinca };
