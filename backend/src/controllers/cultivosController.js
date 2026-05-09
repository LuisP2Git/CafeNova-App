const db = require('../config/db');

/** GET /cultivo — Obtener todos los cultivos */
function obtenerCultivos(req, res) {
    db.query(
        `SELECT 
            c.*,
            l.nombre_lote,
            f.nombre_finca
         FROM cultivo c
         JOIN lote l ON c.id_lote = l.id_lote
         JOIN finca f ON l.id_finca = f.id_finca`,
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
}

/** POST /cultivo — Crear cultivo */
function crearCultivo(req, res) {
    const { id_lote, tipo_cultivo, variedad, fecha_siembra, estado } = req.body;

    db.query(
        `INSERT INTO cultivo (id_lote, tipo_cultivo, variedad, fecha_siembra, estado)
         VALUES (?, ?, ?, ?, ?)`,
        [id_lote, tipo_cultivo, variedad, fecha_siembra, estado],
        (err, result) => {
            if (err) {
                console.log('ERROR INSERT CULTIVO:', err);
                return res.status(500).json({ error: err.message });
            }
            res.status(201).json({ message: 'Cultivo creado', id: result.insertId });
        }
    );
}

/** PUT /cultivo/:id — Actualizar cultivo */
function actualizarCultivo(req, res) {
    const { id } = req.params;
    const { id_lote, tipo_cultivo, variedad, fecha_siembra, estado } = req.body;

    db.query(
        `UPDATE cultivo
         SET id_lote = ?, tipo_cultivo = ?, variedad = ?, fecha_siembra = ?, estado = ?
         WHERE id_cultivo = ?`,
        [id_lote, tipo_cultivo, variedad, fecha_siembra, estado, id],
        (err) => {
            if (err) {
                console.log('ERROR UPDATE CULTIVO:', err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ message: 'Cultivo actualizado' });
        }
    );
}

/** DELETE /cultivo/:id — Eliminar cultivo (y cosechas en cascada) */
function eliminarCultivo(req, res) {
    const { id } = req.params;

    db.query('DELETE FROM cosecha WHERE id_cultivo = ?', [id], (err) => {
        if (err) {
            console.log('ERROR DELETE COSECHAS:', err);
            return res.status(500).json({ error: err.message });
        }

        db.query('DELETE FROM cultivo WHERE id_cultivo = ?', [id], (err2) => {
            if (err2) {
                console.log('ERROR DELETE CULTIVO:', err2);
                return res.status(500).json({ error: err2.message });
            }
            res.json({ message: 'Cultivo eliminado' });
        });
    });
}

module.exports = { obtenerCultivos, crearCultivo, actualizarCultivo, eliminarCultivo };
