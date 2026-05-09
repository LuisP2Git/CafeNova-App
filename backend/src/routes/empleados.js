const express = require('express');
const router  = express.Router();

const { verificarToken } = require('../middleware/auth');
const { obtenerEmpleados, actualizarEmpleado, eliminarEmpleado } = require('../controllers/empleadosController');

router.get(   '/',    verificarToken, obtenerEmpleados);
router.put(   '/:id', verificarToken, actualizarEmpleado);
router.delete('/:id', verificarToken, eliminarEmpleado);

module.exports = router;
