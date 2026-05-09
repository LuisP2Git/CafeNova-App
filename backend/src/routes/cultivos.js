const express = require('express');
const router  = express.Router();

const { verificarToken } = require('../middleware/auth');
const { obtenerCultivos, crearCultivo, actualizarCultivo, eliminarCultivo } = require('../controllers/cultivosController');

router.get(   '/',    verificarToken, obtenerCultivos);
router.post(  '/',    verificarToken, crearCultivo);
router.put(   '/:id', verificarToken, actualizarCultivo);
router.delete('/:id', verificarToken, eliminarCultivo);

module.exports = router;
