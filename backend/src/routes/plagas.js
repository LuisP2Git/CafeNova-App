const express = require('express');

const router = express.Router();

const {
    verificarToken
} = require('../middleware/auth');

const {
    obtenerPlagas,
    crearPlaga,
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

router.delete(
    '/:id',
    verificarToken,
    eliminarPlaga
);

module.exports = router;