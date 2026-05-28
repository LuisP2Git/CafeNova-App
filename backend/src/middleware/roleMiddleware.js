const allowRoles = (...rolesPermitidos) => {

    return (req, res, next) => {

        if (!rolesPermitidos.includes(req.empleado.cargo)) {

            return res.status(403).json({
                error: 'No autorizado'
            });

        }

        next();
    };
};

module.exports = allowRoles;