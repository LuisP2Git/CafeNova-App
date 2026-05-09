const express = require('express');
const router  = express.Router();

const { obtenerCosechas, obtenerCosecha, crearCosecha, actualizarCosecha, eliminarCosecha } = require('../controllers/cosechasController');

router.get(   '/',    obtenerCosechas);
router.get(   '/:id', obtenerCosecha);
router.post(  '/',    crearCosecha);
router.put(   '/:id', actualizarCosecha);
router.delete('/:id', eliminarCosecha);

module.exports = router;
