const db = require('../config/db');

const validarFincaEmpleado = (req, res, next) => {

    try {

        const idUsuario = req.usuario.id_usuario;

        db.query(
            `
            SELECT 
                id_empleado,
                cargo,
                id_finca
            FROM empleado
            WHERE id_usuario = ?
            `,
            [idUsuario],
            (err, result) => {

                if (err) {
                    return res.status(500).json({
                        error: err.message
                    });
                }

                if (result.length === 0) {
                    return res.status(404).json({
                        error: 'Empleado no encontrado'
                    });
                }

                req.empleado = result[0];

                next();
            }
        );

    } catch (error) {

        return res.status(500).json({
            error: error.message
        });

    }
};

module.exports = validarFincaEmpleado;