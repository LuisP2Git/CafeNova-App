const db = require('../config/db');

/** POST /lotes — Crear lote */
function crearLote(req, res) {

    const {
        id_finca,
        nombre_lote,
        area,
        tipo_suelo
    } = req.body;

    db.query(
        'INSERT INTO lote (id_finca, nombre_lote, area, tipo_suelo) VALUES (?, ?, ?, ?)',
        [id_finca, nombre_lote, area, tipo_suelo],
        (err, result) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }

            res.json({
                id: result.insertId
            });
        }
    );
}

/** GET /lotes — Obtener lotes del usuario autenticado */
function obtenerLotes(req, res) {

    // ADMINISTRADOR
    if (req.empleado.cargo === 'Administrador') {

        return db.query(
            `
            SELECT
                l.*,
                f.nombre_finca
            FROM lote l
            INNER JOIN finca f
                ON l.id_finca = f.id_finca
            WHERE f.id_admin = ?
            `,
            [req.usuario.id_usuario],
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

    // EMPLEADOS
    db.query(
        `
        SELECT
            l.*,
            f.nombre_finca
        FROM lote l
        INNER JOIN finca f
            ON l.id_finca = f.id_finca
        WHERE l.id_finca = ?
        `,
        [req.empleado.id_finca],
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

/** PUT /lotes/:id — Actualizar lote */
function actualizarLote(req, res) {
    const { id } = req.params;
    const { nombre_lote, area, tipo_suelo } = req.body;
    const id_finca = req.empleado.id_finca;

    db.query(
        `UPDATE lote 
         SET nombre_lote = ?, area = ?, tipo_suelo = ?
         WHERE id_lote = ?
         AND id_finca = ?`,
        [nombre_lote, area, tipo_suelo, id, req.empleado.id_finca],
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

    db.query(
        'DELETE FROM lote WHERE id_lote = ?',
        [id],
        (err) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }

            res.json({ message: 'Lote eliminado' });
        }
    );
}

module.exports = { crearLote, obtenerLotes, actualizarLote, eliminarLote };
