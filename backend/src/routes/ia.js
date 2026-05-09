const express = require('express');
const router  = express.Router();

const { verificarToken } = require('../middleware/auth');
const { preguntarIA, historialIA } = require('../controllers/iaController');

router.post('/ia',          verificarToken, preguntarIA);
router.get( '/ia/historial',verificarToken, historialIA);

module.exports = router;
