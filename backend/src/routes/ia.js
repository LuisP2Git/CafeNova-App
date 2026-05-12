const express = require('express');
const router = express.Router();

const { verificarToken } = require('../middleware/auth');

const { 
    preguntarIA,
    historialIA,
    analizarImagenIA
} = require('../controllers/iaController');

router.post('/ia', verificarToken, preguntarIA);

router.get('/ia/historial', verificarToken, historialIA);

router.post(
    '/ia/imagen',
    verificarToken,
    analizarImagenIA
);

module.exports = router;