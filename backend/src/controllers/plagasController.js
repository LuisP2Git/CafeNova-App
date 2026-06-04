const db = require('../config/db');

// GET
function obtenerPlagas(req, res) {

    if (req.usuario.rol === 'admin') {

        return db.query(`
            SELECT
                p.*,
                c.tipo_cultivo,
                c.variedad
            FROM plaga p
            LEFT JOIN cultivo c
                ON p.id_cultivo = c.id_cultivo
            ORDER BY p.fecha_registro DESC
        `,
        (err, results) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            res.json(results);
        });
    }

    db.query(`
        SELECT
            p.*,
            c.tipo_cultivo,
            c.variedad
        FROM plaga p
        INNER JOIN cultivo c
            ON p.id_cultivo = c.id_cultivo
        INNER JOIN lote l
            ON c.id_lote = l.id_lote
        WHERE l.id_finca = ?
        ORDER BY p.fecha_registro DESC
    `,
    [req.empleado.id_finca],
    (err, results) => {

        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.json(results);
    });
}

// POST
function crearPlaga(req, res) {

    const {
        id_cultivo,
        tipo_plaga,
        tratamiento,
        cantidad_aplicada,
        unidad,
        hectareas_fumigadas
    } = req.body;

    db.query(`
        INSERT INTO plaga (
            id_cultivo,
            tipo_plaga,
            tratamiento,
            cantidad_aplicada,
            unidad,
            hectareas_fumigadas,
            fecha_registro
        )
        VALUES (?, ?, ?, ?, ?, ?, CURDATE())
    `,
    [
        id_cultivo,
        tipo_plaga,
        tratamiento,
        cantidad_aplicada,
        unidad,
        hectareas_fumigadas
    ],
    (err, result) => {

        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.status(201).json({
            mensaje: 'Registro creado',
            id: result.insertId
        });
    });
}

// PUT
function actualizarPlaga(req, res) {

    const {
        id_cultivo,
        tipo_plaga,
        tratamiento,
        cantidad_aplicada,
        unidad,
        hectareas_fumigadas
    } = req.body;

    db.query(
        `
        UPDATE plaga
        SET
            id_cultivo = ?,
            tipo_plaga = ?,
            tratamiento = ?,
            cantidad_aplicada = ?,
            unidad = ?,
            hectareas_fumigadas = ?
        WHERE id_plaga = ?
        `,
        [
            id_cultivo,
            tipo_plaga,
            tratamiento,
            cantidad_aplicada,
            unidad,
            hectareas_fumigadas,
            req.params.id
        ],
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    error: 'Registro no encontrado'
                });
            }

            return res.json({
                message: 'Registro actualizado'
            });
        }
    );
}

// DELETE
function eliminarPlaga(req, res) {

    db.query(`
        DELETE FROM plaga
        WHERE id_plaga = ?
    `,
    [req.params.id],
    err => {

        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.json({
            mensaje: 'Eliminado'
        });
    });
}

module.exports = {
    obtenerPlagas,
    crearPlaga,
    actualizarPlaga,
    eliminarPlaga
};