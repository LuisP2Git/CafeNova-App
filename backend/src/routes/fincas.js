const express = require('express');
const router  = express.Router();

const { verificarToken, soloAdmin } = require('../middleware/auth');
const { crearFinca, obtenerFincas, actualizarFinca, eliminarFinca } = require('../controllers/fincasController');

router.post(  '/',    verificarToken, soloAdmin, crearFinca);
router.get(   '/',    verificarToken, soloAdmin, obtenerFincas);
router.put(   '/:id', verificarToken,            actualizarFinca);
router.delete('/:id', verificarToken, soloAdmin, eliminarFinca);

module.exports = router;
