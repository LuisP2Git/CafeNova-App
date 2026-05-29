module.exports = (...rolesPermitidos) => {
    return (req, res, next) => {
        // Validación de seguridad por si req.empleado no viene cargado desde el auth middleware
        if (!req.empleado || !req.empleado.cargo) {
            return res.status(401).json({ error: 'Autenticación inválida o falta el cargo' });
        }

        if (!rolesPermitidos.includes(req.empleado.cargo)) {
            return res.status(403).json({
                error: 'No autorizado para este rol'
            });
        }

        next();
    };
};
