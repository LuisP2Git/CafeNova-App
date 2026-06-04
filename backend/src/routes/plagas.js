const express = require('express');

const router = express.Router();

const {
    verificarToken
} = require('../middleware/auth');

const {
    obtenerPlagas,
    crearPlaga,
    actualizarPlaga,
    eliminarPlaga
} = require('../controllers/plagasController');

router.get(
    '/',
    verificarToken,
    obtenerPlagas
);

router.post(
    '/',
    verificarToken,
    crearPlaga
);

router.put(
    '/:id', 
    verificarToken, 
    actualizarPlaga);

router.delete(
    '/:id',
    verificarToken,
    eliminarPlaga
);

module.exports = router;