const express = require('express');
const router  = express.Router();

const { verificarToken, soloAdmin } = require('../middleware/auth');
const { obtenerPendientes, aprobarUsuario, eliminarUsuario } = require('../controllers/usuariosController');

router.get(   '/pendientes',      verificarToken, soloAdmin, obtenerPendientes);
router.put(   '/aprobar/:id',     verificarToken, soloAdmin, aprobarUsuario);
router.delete('/:id',             verificarToken, soloAdmin, eliminarUsuario);

module.exports = router;
