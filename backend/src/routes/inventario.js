const express = require('express');
const router = express.Router();

const auth = require('../middleware/auth');

const {
  obtenerInventario,
  crearInsumo,
  actualizarInsumo,
  eliminarInsumo
} = require('../controllers/inventarioController');

router.get(
  '/',
  auth.verificarToken,
  obtenerInventario
);

router.post(
  '/',
  auth.verificarToken,
  crearInsumo
);

router.put(
  '/:id',
  auth.verificarToken,
  actualizarInsumo
);

router.delete(
  '/:id',
  auth.verificarToken,
  eliminarInsumo
);

module.exports = router;