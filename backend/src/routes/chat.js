const express = require('express');

const router = express.Router();

const {
    verificarToken
} = require('../middleware/auth');

const {
    enviarMensaje,
    obtenerConversacion,
    obtenerContactos,
    obtenerNoLeidos
} = require('../controllers/chatController');

router.get(
    '/contactos',
    verificarToken,
    obtenerContactos
);

router.get(
    '/no-leidos',
    verificarToken,
    obtenerNoLeidos
);

router.get(
    '/:id',
    verificarToken,
    obtenerConversacion
);

router.post(
    '/',
    verificarToken,
    enviarMensaje
);

module.exports = router;