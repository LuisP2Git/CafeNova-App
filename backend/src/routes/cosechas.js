const express = require('express');
const router  = express.Router();
const auth = require('../middleware/auth');
const validarFincaEmpleado = require('../middleware/fincaMiddleware');
const allowRoles = require('../middleware/roleMiddleware');

const { obtenerCosechas, obtenerCosecha, crearCosecha, actualizarCosecha, eliminarCosecha } = require('../controllers/cosechasController');

router.get(
    '/',
    auth,
    validarFincaEmpleado,
    obtenerCosechas
);

router.get(
    '/:id',
    auth,
    validarFincaEmpleado,
    obtenerCosecha
);

router.post(
    '/',
    auth,
    validarFincaEmpleado,
    allowRoles('Recolector'),
    crearCosecha
);

router.put(
    '/:id',
    auth,
    validarFincaEmpleado,
    allowRoles('Recolector'),
    actualizarCosecha
);

router.delete(
    '/:id',
    auth,
    validarFincaEmpleado,
    allowRoles('Administrador'),
    eliminarCosecha
);

module.exports = router;
