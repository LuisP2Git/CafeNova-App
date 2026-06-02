const express = require('express');
const router  = express.Router();

const { verificarToken } = require('../middleware/auth');
const { obtenerCultivos, crearCultivo, actualizarCultivo, eliminarCultivo } = require('../controllers/cultivosController');

router.get('/', verificarToken, (req, res) => {
    console.log('GET CULTIVOS');
    return obtenerCultivos(req, res);
});

router.post('/', verificarToken, (req, res) => {
    console.log('POST CULTIVOS');
    return crearCultivo(req, res);
});

router.put('/:id', verificarToken, (req, res) => {
    console.log('PUT CULTIVOS');
    return actualizarCultivo(req, res);
});

router.delete('/:id', verificarToken, (req, res) => {
    console.log('DELETE CULTIVOS');
    return eliminarCultivo(req, res);
});
module.exports = router;
