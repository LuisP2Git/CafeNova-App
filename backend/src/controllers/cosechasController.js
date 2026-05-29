const db = require('../config/db');

/** GET /cosecha — Obtener todas las cosechas */
function obtenerCosechas(req, res) {
    db.query(
    `SELECT * FROM cosecha WHERE id_finca = ? ORDER BY fecha_cosecha DESC`,
    [req.empleado.id_finca],
        (err, results) => {
            if (err) {
                console.log('ERROR COSECHA:', err);
                return res.status(500).json({ error: err.message });
            }
            res.json(results);
        }
    );
}

/** GET /cosecha/:id — Obtener una cosecha por ID */
function obtenerCosecha(req, res) {
    const { id } = req.params;

    db.query(
     `SELECT * FROM cosecha WHERE id_cosecha = ? AND id_finca = ?`,
    [id, req.empleado.id_finca],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results[0]);
        }
    );
}

/** POST /cosecha — Crear cosecha */
function crearCosecha(req, res) {
    const { id_cultivo, fecha_cosecha, cantidad_kg, calidad } = req.body;
    const id_finca = req.empleado.id_finca;

    db.query(
        `INSERT INTO cosecha (id_cultivo, fecha_cosecha, cantidad_kg, calidad, id_finca) 
        VALUES (?, ?, ?, ?, ?)`,
        [id_cultivo, fecha_cosecha, cantidad_kg, calidad, id_finca],
        (err, result) => {
            if (err) {
                console.log('ERROR INSERT:', err);
                return res.status(500).json({ error: err.message });
            }
            res.status(201).json({ message: 'Cosecha creada', id: result.insertId });
        }
    );
}

/** PUT /cosecha/:id — Actualizar cosecha */
function actualizarCosecha(req, res) {
    const { id } = req.params;
    const { id_cultivo, fecha_cosecha, cantidad_kg, calidad } = req.body;

    db.query(
        `UPDATE cosecha
         SET id_cultivo = ?, fecha_cosecha = ?, cantidad_kg = ?, calidad = ?
         WHERE id_cosecha = ? AND id_finca = ?`,
        [id_cultivo, fecha_cosecha, cantidad_kg, calidad, id, req.empleado.id_finca],
        (err, result) => {
            if (err) {
                console.log('ERROR UPDATE:', err);
                return res.status(500).json({ error: err.message });
            }
            if (result.affectedRows === 0) {
                return res.status(404).json({ error: 'No existe la cosecha' });
            }
            res.json({ message: 'Cosecha actualizada' });
        }
    );
}

/** DELETE /cosecha/:id — Eliminar cosecha */
function eliminarCosecha(req, res) {
    const { id } = req.params;

    db.query(
        `DELETE FROM cosecha WHERE id_cosecha = ? AND id_finca = ?`,
        [id, req.empleado.id_finca],
        (err, result) => {
            if (err) {
                console.log('ERROR DELETE:', err);
                return res.status(500).json({ error: err.message });
            }
            if (result.affectedRows === 0) {
                return res.status(404).json({ error: 'No existe la cosecha' });
            }
            res.json({ message: 'Cosecha eliminada' });
        }
    );
}

module.exports = {
    obtenerCosechas,
    obtenerCosecha,
    crearCosecha,
    actualizarCosecha,
    eliminarCosecha
};
