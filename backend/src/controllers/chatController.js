const db = require('../config/db');

/**
 * Enviar mensaje
 */
function enviarMensaje(req, res) {

    const { id_destinatario, mensaje } = req.body;

    db.query(
        `
        SELECT cargo
        FROM empleado
        WHERE id_empleado = ?
        `,
        [id_destinatario],
        (err, results) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (results.length === 0) {
                return res.status(404).json({
                    error: 'Empleado no encontrado'
                });
            }

            const rolRemitente = req.usuario.rol;
            const cargoRemitente = req.empleado.cargo;

            const cargoDestinatario =
                results[0].cargo;

            const esAdmin =
                rolRemitente === 'admin';

            const esAuxiliar =
                cargoRemitente ===
                'Auxiliar Administrativo';

            // Si NO es admin ni auxiliar
            if (!esAdmin && !esAuxiliar) {

                const puedeEscribir =
                    cargoDestinatario === 'Administrador' ||
                    cargoDestinatario === 'Auxiliar Administrativo';

                if (!puedeEscribir) {

                    return res.status(403).json({
                        error:
                            'No tienes permiso para comunicarte con este empleado'
                    });
                }
            }

            db.query(
                `
                INSERT INTO chat_mensajes
                (
                    id_remitente,
                    id_destinatario,
                    mensaje
                )
                VALUES (?, ?, ?)
                `,
                [
                    req.empleado.id_empleado,
                    id_destinatario,
                    mensaje
                ],
                (err) => {

                    if (err) {
                        return res.status(500).json({
                            error: err.message
                        });
                    }

                    res.json({
                        message: 'Mensaje enviado'
                    });
                }
            );
        }
    );
}

/**
 * Obtener conversación
 */
function obtenerConversacion(req, res) {

    const { id } = req.params;

    db.query(
        `
        SELECT cargo
        FROM empleado
        WHERE id_empleado = ?
        `,
        [id],
        (err, empleadoResult) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (empleadoResult.length === 0) {
                return res.status(404).json({
                    error: 'Empleado no encontrado'
                });
            }

            const rolActual =
                req.usuario.rol;

            const cargoActual =
                req.empleado.cargo;

            const cargoDestino =
                empleadoResult[0].cargo;

            const esAdmin =
                rolActual === 'admin';

            const esAuxiliar =
                cargoActual ===
                'Auxiliar Administrativo';

            // Si NO es admin ni auxiliar
            if (!esAdmin && !esAuxiliar) {

                const permitido =
                    cargoDestino === 'Administrador' ||
                    cargoDestino === 'Auxiliar Administrativo';

                if (!permitido) {

                    return res.status(403).json({
                        error:
                            'No tienes permiso para ver esta conversación'
                    });
                }
            }

            // MARCAR COMO LEÍDOS
            db.query(
                `
                UPDATE chat_mensajes
                SET leido = 1
                WHERE
                    id_remitente = ?
                    AND id_destinatario = ?
                    AND leido = 0
                `,
                [
                    id,
                    req.empleado.id_empleado
                ]
            );

            db.query(
                `
                SELECT *
                FROM chat_mensajes
                WHERE
                (
                    id_remitente = ?
                    AND id_destinatario = ?
                )
                OR
                (
                    id_remitente = ?
                    AND id_destinatario = ?
                )
                ORDER BY fecha_envio ASC
                `,
                [
                    req.empleado.id_empleado,
                    id,

                    id,
                    req.empleado.id_empleado
                ],
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
    );
}

/**
 * Obtener contactos
 */
function obtenerContactos(req, res) {

    const cargo = req.empleado.cargo;

    // Administrador y auxiliar ven todos

    if (
        cargo === 'Administrador' ||
        cargo === 'Auxiliar Administrativo'
    ) {

        return db.query(
            `
            SELECT
                e.id_empleado,
                u.nombre_usuario,
                e.cargo
            FROM empleado e
            INNER JOIN usuarios u
                ON u.id_usuario = e.id_usuario
            WHERE e.id_empleado <> ?
            `,
            [req.empleado.id_empleado],
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

    // Los demás empleados solo ven admin y auxiliar

    db.query(
        `
        SELECT
            e.id_empleado,
            u.nombre_usuario,
            e.cargo
        FROM empleado e
        INNER JOIN usuarios u
            ON u.id_usuario = e.id_usuario
        WHERE e.cargo IN
        (
            'Administrador',
            'Auxiliar Administrativo'
        )
        AND e.id_empleado <> ?
        `,
        [req.empleado.id_empleado],
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

function obtenerNoLeidos(req, res) {

    db.query(
        `
        SELECT COUNT(*) AS total
        FROM chat_mensajes
        WHERE
            id_destinatario = ?
            AND leido = 0
        `,
        [req.empleado.id_empleado],
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            res.json({
                total: result[0].total
            });
        }
    );
}

module.exports = {
    enviarMensaje,
    obtenerConversacion,
    obtenerContactos,
    obtenerNoLeidos
};