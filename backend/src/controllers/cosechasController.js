const db = require('../config/db');

/** GET /cosecha — Obtener todas las cosechas */
function obtenerCosechas(req, res) {

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            SELECT
                c.*
            FROM cosecha c
            INNER JOIN cultivo cu
                ON c.id_cultivo = cu.id_cultivo
            INNER JOIN lote l
                ON cu.id_lote = l.id_lote
            INNER JOIN finca f
                ON l.id_finca = f.id_finca
            WHERE f.id_admin = ?
            ORDER BY c.fecha_cosecha DESC
            `,
            [req.usuario.id_usuario],
            (err, results) => {

                if (err) {
                    console.log('ERROR COSECHA:', err);
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
        FROM cosecha
        WHERE id_finca = ?
        ORDER BY fecha_cosecha DESC
        `,
        [req.empleado.id_finca],
        (err, results) => {

            if (err) {
                console.log('ERROR COSECHA:', err);
                return res.status(500).json({
                    error: err.message
                });
            }

            res.json(results);
        }
    );
}

/** GET /cosecha/:id — Obtener una cosecha por ID */
function obtenerCosecha(req, res) {

    const { id } = req.params;

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            SELECT c.*
            FROM cosecha c
            INNER JOIN cultivo cu
                ON c.id_cultivo = cu.id_cultivo
            INNER JOIN lote l
                ON cu.id_lote = l.id_lote
            INNER JOIN finca f
                ON l.id_finca = f.id_finca
            WHERE c.id_cosecha = ?
            AND f.id_admin = ?
            `,
            [id, req.usuario.id_usuario],
            (err, results) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                res.json(results[0]);
            }
        );
    }

    // EMPLEADOS
    db.query(
        `
        SELECT *
        FROM cosecha
        WHERE id_cosecha = ?
        AND id_finca = ?
        `,
        [id, req.empleado.id_finca],
        (err, results) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            res.json(results[0]);
        }
    );
}

/** POST /cosecha — Crear cosecha */
function crearCosecha(req, res) {

    const {
        id_cultivo,
        fecha_cosecha,
        cantidad_kg,
        calidad
    } = req.body;

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            SELECT l.id_finca
            FROM cultivo cu
            INNER JOIN lote l
                ON cu.id_lote = l.id_lote
            INNER JOIN finca f
                ON l.id_finca = f.id_finca
            WHERE cu.id_cultivo = ?
            AND f.id_admin = ?
            `,
            [id_cultivo, req.usuario.id_usuario],
            (err, cultivoResult) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (cultivoResult.length === 0) {
                    return res.status(403).json({
                        error: 'Cultivo no autorizado'
                    });
                }

                const id_finca = cultivoResult[0].id_finca;

                db.query(
                    `
                    INSERT INTO cosecha (
                        id_cultivo,
                        fecha_cosecha,
                        cantidad_kg,
                        calidad,
                        id_finca
                    )
                    VALUES (?, ?, ?, ?, ?)
                    `,
                    [
                        id_cultivo,
                        fecha_cosecha,
                        cantidad_kg,
                        calidad,
                        id_finca
                    ],
                    (err, result) => {

                        if (err) {
                            console.log('ERROR INSERT:', err);

                            return res.status(500).json({
                                error: err.message
                            });
                        }

                        res.status(201).json({
                            message: 'Cosecha creada',
                            id: result.insertId
                        });
                    }
                );
            }
        );
    }

    // EMPLEADOS
    const id_finca = req.empleado.id_finca;

    db.query(
        `
        INSERT INTO cosecha (
            id_cultivo,
            fecha_cosecha,
            cantidad_kg,
            calidad,
            id_finca
        )
        VALUES (?, ?, ?, ?, ?)
        `,
        [
            id_cultivo,
            fecha_cosecha,
            cantidad_kg,
            calidad,
            id_finca
        ],
        (err, result) => {

            if (err) {
                console.log('ERROR INSERT:', err);

                return res.status(500).json({
                    error: err.message
                });
            }

            res.status(201).json({
                message: 'Cosecha creada',
                id: result.insertId
            });
        }
    );
}

/** PUT /cosecha/:id — Actualizar cosecha */
function actualizarCosecha(req, res) {

    const { id } = req.params;
    const {
        id_cultivo,
        fecha_cosecha,
        cantidad_kg,
        calidad
    } = req.body;

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            UPDATE cosecha
            SET
                id_cultivo = ?,
                fecha_cosecha = ?,
                cantidad_kg = ?,
                calidad = ?
            WHERE id_cosecha = ?
            `,
            [
                id_cultivo,
                fecha_cosecha,
                cantidad_kg,
                calidad,
                id
            ],
            (err, result) => {

                if (err) {
                    console.log('ERROR UPDATE:', err);

                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({
                        error: 'No existe la cosecha'
                    });
                }

                res.json({
                    message: 'Cosecha actualizada'
                });
            }
        );
    }

    // EMPLEADOS
    db.query(
        `
        UPDATE cosecha
        SET
            id_cultivo = ?,
            fecha_cosecha = ?,
            cantidad_kg = ?,
            calidad = ?
        WHERE id_cosecha = ?
        AND id_finca = ?
        `,
        [
            id_cultivo,
            fecha_cosecha,
            cantidad_kg,
            calidad,
            id,
            req.empleado.id_finca
        ],
        (err, result) => {

            if (err) {
                console.log('ERROR UPDATE:', err);

                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    error: 'No existe la cosecha'
                });
            }

            res.json({
                message: 'Cosecha actualizada'
            });
        }
    );
}

/** DELETE /cosecha/:id — Eliminar cosecha */
function eliminarCosecha(req, res) {

    const { id } = req.params;

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            DELETE FROM cosecha
            WHERE id_cosecha = ?
            `,
            [id],
            (err, result) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({
                        error: 'No existe la cosecha'
                    });
                }

                res.json({
                    message: 'Cosecha eliminada'
                });
            }
        );
    }

    // EMPLEADOS
    db.query(
        `
        DELETE FROM cosecha
        WHERE id_cosecha = ?
        AND id_finca = ?
        `,
        [id, req.empleado.id_finca],
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    error: 'No existe la cosecha'
                });
            }

            res.json({
                message: 'Cosecha eliminada'
            });
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