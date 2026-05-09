const db = require('../config/db');

/**
 * Verifica que el request traiga un token válido en el header Authorization.
 * Inyecta req.usuario con los datos del usuario autenticado.
 */
function verificarToken(req, res, next) {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Token requerido' });

    db.query('SELECT * FROM usuarios WHERE token = ?', [token], (err, result) => {
        if (err)               return res.status(500).json({ error: err.message });
        if (result.length === 0) return res.status(401).json({ error: 'Token inválido' });

        req.usuario = result[0];
        next();
    });
}

/**
 * Solo permite el paso a usuarios con rol 'admin'.
 * Debe usarse después de verificarToken.
 */
function soloAdmin(req, res, next) {
    if (req.usuario.rol !== 'admin') {
        return res.status(403).json({ error: 'Solo admin' });
    }
    next();
}

/**
 * Permite el paso a usuarios con rol 'admin' o 'empleado'.
 * Debe usarse después de verificarToken.
 */
function adminOEmpleado(req, res, next) {
    if (req.usuario.rol !== 'admin' && req.usuario.rol !== 'empleado') {
        return res.status(403).json({ error: 'Acceso denegado' });
    }
    next();
}

module.exports = { verificarToken, soloAdmin, adminOEmpleado };
