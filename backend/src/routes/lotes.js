const express = require('express');
const router  = express.Router();

const { verificarToken, soloAdmin } = require('../middleware/auth');
const { crearLote, obtenerLotes, actualizarLote, eliminarLote } = require('../controllers/lotesController');

router.post(  '/',    verificarToken, soloAdmin, crearLote);
router.get(   '/',    verificarToken,            obtenerLotes);
router.put(   '/:id', verificarToken, soloAdmin, actualizarLote);
router.delete('/:id', verificarToken, soloAdmin, eliminarLote);

module.exports = router;
