const db = require('../config/db');

/** GET /cultivo — Obtener cultivos de la finca del empleado */
function obtenerCultivos(req, res) {

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            SELECT
                c.*,
                l.nombre_lote,
                f.nombre_finca
            FROM cultivo c
            JOIN lote l
                ON c.id_lote = l.id_lote
            JOIN finca f
                ON l.id_finca = f.id_finca
            `,
            (err, results) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                return res.json(results);
            }
        );
    }

    // EMPLEADOS
    db.query(
        `
        SELECT
            c.*,
            l.nombre_lote,
            f.nombre_finca
        FROM cultivo c
        JOIN lote l
            ON c.id_lote = l.id_lote
        JOIN finca f
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

            return res.json(results);
        }
    );
}

/** POST /cultivo — Crear cultivo */
function crearCultivo(req, res) {

    console.log('ROL:', req.usuario.rol);

    const {
        id_lote,
        tipo_cultivo,
        variedad,
        fecha_siembra,
        estado
    } = req.body;

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            INSERT INTO cultivo (
                id_lote,
                tipo_cultivo,
                variedad,
                fecha_siembra,
                estado
            )
            VALUES (?, ?, ?, ?, ?)
            `,
            [
                id_lote,
                tipo_cultivo,
                variedad,
                fecha_siembra,
                estado
            ],
            (err, result) => {

                if (err) {
                    console.log('ERROR INSERT CULTIVO ADMIN:', err);

                    return res.status(500).json({
                        error: err.message
                    });
                }

                return res.status(201).json({
                    message: 'Cultivo creado',
                    id: result.insertId
                });
            }
        );
    }

    // EMPLEADOS
    db.query(
        `
        SELECT *
        FROM lote
        WHERE id_lote = ?
        AND id_finca = ?
        `,
        [id_lote, req.empleado.id_finca],
        (err, loteResult) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (loteResult.length === 0) {
                return res.status(403).json({
                    error: 'El lote no pertenece a su finca'
                });
            }

            db.query(
                `
                INSERT INTO cultivo (
                    id_lote,
                    tipo_cultivo,
                    variedad,
                    fecha_siembra,
                    estado
                )
                VALUES (?, ?, ?, ?, ?)
                `,
                [
                    id_lote,
                    tipo_cultivo,
                    variedad,
                    fecha_siembra,
                    estado
                ],
                (err, result) => {

                    if (err) {
                        console.log('ERROR INSERT CULTIVO:', err);

                        return res.status(500).json({
                            error: err.message
                        });
                    }

                    return res.status(201).json({
                        message: 'Cultivo creado',
                        id: result.insertId
                    });
                }
            );
        }
    );
}

/** PUT /cultivo/:id — Actualizar cultivo */
function actualizarCultivo(req, res) {

    const { id } = req.params;

    const {
        id_lote,
        tipo_cultivo,
        variedad,
        fecha_siembra,
        estado
    } = req.body;

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            UPDATE cultivo
            SET
                id_lote = ?,
                tipo_cultivo = ?,
                variedad = ?,
                fecha_siembra = ?,
                estado = ?
            WHERE id_cultivo = ?
            `,
            [
                id_lote,
                tipo_cultivo,
                variedad,
                fecha_siembra,
                estado,
                id
            ],
            (err, result) => {

                if (err) {
                    console.log('ERROR UPDATE CULTIVO:', err);

                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({
                        error: 'Cultivo no encontrado'
                    });
                }
                console.log('ANTES DEL JSON FINAL');
console.log('headersSent:', res.headersSent);

                return res.json({
                    message: 'Cultivo actualizado'
                });
            }
        );
    }

    // EMPLEADOS
    db.query(
        `
        UPDATE cultivo
        SET
            id_lote = ?,
            tipo_cultivo = ?,
            variedad = ?,
            fecha_siembra = ?,
            estado = ?
        WHERE id_cultivo = ?
        AND id_lote IN (
            SELECT id_lote
            FROM lote
            WHERE id_finca = ?
        )
        `,
        [
            id_lote,
            tipo_cultivo,
            variedad,
            fecha_siembra,
            estado,
            id,
            req.empleado.id_finca
        ],
        (err, result) => {

            if (err) {
                console.log('ERROR UPDATE CULTIVO:', err);

                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    error: 'Cultivo no encontrado o no autorizado'
                });
            }

            return res.json({
                message: 'Cultivo actualizado'
            });
        }
    );
}
/** DELETE /cultivo/:id — Eliminar cultivo */
function eliminarCultivo(req, res) {

    const { id } = req.params;

    // ADMINISTRADOR
    if (req.usuario.rol === 'admin') {

        return db.query(
            `
            DELETE FROM cultivo
            WHERE id_cultivo = ?
            `,
            [id],
            (err, result) => {

                if (err) {
                    console.log('ERROR DELETE CULTIVO:', err);

                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({
                        error: 'Cultivo no encontrado'
                    });
                }

                return res.json({
                    message: 'Cultivo eliminado'
                });
            }
        );
    }

    // EMPLEADOS
    db.query(
        `
        DELETE FROM cultivo
        WHERE id_cultivo = ?
        AND id_lote IN (
            SELECT id_lote
            FROM lote
            WHERE id_finca = ?
        )
        `,
        [id, req.empleado.id_finca],
        (err, result) => {

            if (err) {
                console.log('ERROR DELETE CULTIVO:', err);

                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.affectedRows === 0) {
                return res.status(404).json({
                    error: 'Cultivo no encontrado o no autorizado'
                });
            }

            return res.json({
                message: 'Cultivo eliminado'
            });
        }
    );
}

module.exports = {
    obtenerCultivos,
    crearCultivo,
    actualizarCultivo,
    eliminarCultivo
};