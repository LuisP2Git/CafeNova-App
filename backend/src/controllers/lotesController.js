const db = require('../config/db');

/** POST /lotes — Crear lote */
function crearLote(req, res) {
    const { id_finca, nombre_lote, area, tipo_suelo } = req.body;

    db.query(
        'INSERT INTO lote (id_finca, nombre_lote, area, tipo_suelo) VALUES (?, ?, ?, ?)',
        [id_finca, nombre_lote, area, tipo_suelo],
        (err, result) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ id: result.insertId });
        }
    );
}

/** GET /lotes — Obtener lotes del usuario autenticado */
function obtenerLotes(req, res) {
    db.query(
        `SELECT 
            l.*, 
            f.nombre_finca 
         FROM lote l
         JOIN finca f ON l.id_finca = f.id_finca
         WHERE f.id_admin = ?`,
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
}

/** PUT /lotes/:id — Actualizar lote */
function actualizarLote(req, res) {
    const { id } = req.params;
    const { id_finca, nombre_lote, area, tipo_suelo } = req.body;

    db.query(
        `UPDATE lote 
         SET id_finca = ?, nombre_lote = ?, area = ?, tipo_suelo = ?
         WHERE id_lote = ?`,
        [id_finca, nombre_lote, area, tipo_suelo, id],
        (err) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ message: 'Lote actualizado' });
        }
    );
}

/** DELETE /lotes/:id — Eliminar lote */
function eliminarLote(req, res) {
    const { id } = req.params;

    db.query('DELETE FROM lote WHERE id_lote = ?', [id], (err) => {
        if (err) {
            console.log('ERROR DELETE:', err);
            return res.status(500).json({ error: err.message });
        }
        res.json({ message: 'Lote eliminado' });
    });
}

module.exports = { crearLote, obtenerLotes, actualizarLote, eliminarLote };
