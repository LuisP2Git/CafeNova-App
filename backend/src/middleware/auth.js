const db = require('../config/db');

/**
 * Verifica que el request traiga un token válido.
 * Carga información de usuario y empleado.
 */
function verificarToken(req, res, next) {

    const token = req.headers['authorization']?.split(' ')[1];

    if (!token) {
        return res.status(401).json({
            error: 'Token requerido'
        });
    }

    db.query(
        `
        SELECT
            u.*,
            e.id_empleado,
            e.id_finca,
            e.cargo
        FROM usuarios u
        LEFT JOIN empleado e
            ON u.id_usuario = e.id_usuario
        WHERE u.token = ?
        `,
        [token],
        (err, result) => {

            if (err) {
                return res.status(500).json({
                    error: err.message
                });
            }

            if (result.length === 0) {
                return res.status(401).json({
                    error: 'Token inválido'
                });
            }

            const usuario = result[0];

            req.usuario = usuario;

            req.empleado = {
                id_empleado: usuario.id_empleado,
                id_finca: usuario.id_finca,
                cargo: usuario.cargo
            };

            next();
        }
    );
}

/**
 * Solo administradores.
 */
function soloAdmin(req, res, next) {

    if (req.usuario.rol !== 'admin') {
        return res.status(403).json({
            error: 'Solo administradores'
        });
    }

    next();
}

/**
 * Administradores o empleados.
 */
function adminOEmpleado(req, res, next) {

    if (
        req.usuario.rol !== 'admin' &&
        req.usuario.rol !== 'empleado'
    ) {
        return res.status(403).json({
            error: 'Acceso denegado'
        });
    }

    next();
}

/**
 * Verifica que exista empleado asociado.
 */
function requiereEmpleado(req, res, next) {

    if (!req.empleado || !req.empleado.id_empleado) {
        return res.status(403).json({
            error: 'Usuario sin empleado asociado'
        });
    }

    next();
}

/**
 * Verifica que exista finca asociada.
 */
function requiereFinca(req, res, next) {

    if (!req.empleado || !req.empleado.id_finca) {
        return res.status(403).json({
            error: 'Empleado sin finca asignada'
        });
    }

    next();
}

module.exports = {
    verificarToken,
    soloAdmin,
    adminOEmpleado,
    requiereEmpleado,
    requiereFinca
};