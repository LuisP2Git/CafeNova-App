const db = require('../config/db');

/* GET */
function obtenerInventario(req, res) {

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            SELECT i.*
            FROM inventario i
            INNER JOIN finca f
                ON i.id_finca = f.id_finca
            WHERE f.id_admin = ?
            ORDER BY i.nombre_insumo
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

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            SELECT id_finca
            FROM finca
            WHERE id_admin = ?
            LIMIT 1
            `,
            [req.usuario.id_usuario],
            (err, fincaResult) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (fincaResult.length === 0) {
                    return res.status(404).json({
                        error: 'No se encontró finca para el administrador'
                    });
                }

                const id_finca = fincaResult[0].id_finca;

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
                        id_finca
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
        );
    }

    // EMPLEADOS
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

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            UPDATE inventario i
            INNER JOIN finca f
                ON i.id_finca = f.id_finca
            SET
                i.nombre_insumo = ?,
                i.tipo = ?,
                i.cantidad = ?,
                i.unidad = ?
            WHERE i.id_insumo = ?
            AND f.id_admin = ?
            `,
            [
                nombre_insumo,
                tipo,
                cantidad,
                unidad,
                id,
                req.usuario.id_usuario
            ],
            (err, result) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({
                        error: 'Insumo no encontrado'
                    });
                }

                res.json({
                    message: 'Insumo actualizado'
                });
            }
        );
    }

    // EMPLEADOS
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
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    error: 'Insumo no encontrado'
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

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            DELETE i
            FROM inventario i
            INNER JOIN finca f
                ON i.id_finca = f.id_finca
            WHERE i.id_insumo = ?
            AND f.id_admin = ?
            `,
            [
                id,
                req.usuario.id_usuario
            ],
            (err, result) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({
                        error: 'Insumo no encontrado'
                    });
                }

                res.json({
                    message: 'Insumo eliminado'
                });
            }
        );
    }

    // EMPLEADOS
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
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    error: 'Insumo no encontrado'
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