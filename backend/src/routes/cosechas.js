const express = require('express');
const router  = express.Router();

const { verificarToken } = require('../middleware/auth');
const validarFincaEmpleado = require('../middleware/fincaMiddleware');
const allowRoles = require('../middleware/roleMiddleware');

const { obtenerCosechas, obtenerCosecha, crearCosecha, actualizarCosecha, eliminarCosecha } = require('../controllers/cosechasController');


router.get(
    '/',
    verificarToken, 
    validarFincaEmpleado,
    obtenerCosechas
);

router.get(
    '/:id',
    verificarToken, 
    validarFincaEmpleado,
    obtenerCosecha
);

router.post(
    '/',
    verificarToken, 
    validarFincaEmpleado,
    allowRoles('Recolector', 'Administrador'),
    crearCosecha
);

router.put(
    '/:id',
    verificarToken, 
    validarFincaEmpleado,
    allowRoles('Recolector', 'Administrador'),
    actualizarCosecha
);

router.delete(
    '/:id',
    verificarToken, 
    validarFincaEmpleado,
    allowRoles('Administrador'),
    eliminarCosecha
);

module.exports = router;