const express = require('express');
const router = express.Router();

const { verificarToken, soloAdmin } = require('../middleware/auth');

const {
  obtenerPendientes,
  aprobarUsuario,
  eliminarUsuario,
  obtenerPerfil,
  actualizarPerfil,
  cambiarPassword,
} = require('../controllers/usuariosController');

router.get(
  '/perfil',
  verificarToken,
  obtenerPerfil
);

router.put(
  '/perfil',
  verificarToken,
  actualizarPerfil
);

router.put(
  '/password',
  verificarToken,
  cambiarPassword
);

router.get(
  '/pendientes',
  verificarToken,
  soloAdmin,
  obtenerPendientes
);

router.put(
  '/aprobar/:id',
  verificarToken,
  soloAdmin,
  aprobarUsuario
);

router.delete(
  '/:id',
  verificarToken,
  soloAdmin,
  eliminarUsuario
);

module.exports = router;