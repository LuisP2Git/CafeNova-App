const db = require('../config/db');

/* GET */
function obtenerInventario(req, res) {

    db.query(
        `
        SELECT *
        FROM inventario
        WHERE id_finca = ?
        ORDER BY nombre_insumo
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

/* POST */
function crearInsumo(req, res) {

    const {
        nombre_insumo,
        tipo,
        cantidad,
        unidad
    } = req.body;

    db.query(
        `
        INSERT INTO inventario
        (
            nombre_insumo,
            tipo,
            cantidad,
            unidad,
            id_finca
        )
        VALUES (?, ?, ?, ?, ?)
        `,
        [
            nombre_insumo,
            tipo,
            cantidad,
            unidad,
            req.empleado.id_finca
        ],
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            res.status(201).json({
                id: result.insertId
            });
        }
    );
}

/* PUT */
function actualizarInsumo(req, res) {

    const { id } = req.params;

    const {
        nombre_insumo,
        tipo,
        cantidad,
        unidad
    } = req.body;

    db.query(
        `
        UPDATE inventario
        SET
            nombre_insumo = ?,
            tipo = ?,
            cantidad = ?,
            unidad = ?
        WHERE id_insumo = ?
        AND id_finca = ?
        `,
        [
            nombre_insumo,
            tipo,
            cantidad,
            unidad,
            id,
            req.empleado.id_finca
        ],
        (err) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            res.json({
                message: 'Insumo actualizado'
            });
        }
    );
}

/* DELETE */
function eliminarInsumo(req, res) {

    const { id } = req.params;

    db.query(
        `
        DELETE FROM inventario
        WHERE id_insumo = ?
        AND id_finca = ?
        `,
        [
            id,
            req.empleado.id_finca
        ],
        (err) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            res.json({
                message: 'Insumo eliminado'
            });
        }
    );
}

module.exports = {
    obtenerInventario,
    crearInsumo,
    actualizarInsumo,
    eliminarInsumo
};