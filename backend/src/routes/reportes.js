const express = require('express');
const router  = express.Router();

const { verificarToken, adminOEmpleado } = require('../middleware/auth');
const { totalCosecha, cosechaMensual, porCalidad, mejorCultivo, porFecha, generarPDF } = require('../controllers/reportesController');

router.get('/total-cosecha',  verificarToken, adminOEmpleado, totalCosecha);
router.get('/cosecha-mensual',verificarToken, adminOEmpleado, cosechaMensual);
router.get('/por-calidad',    verificarToken, adminOEmpleado, porCalidad);
router.get('/mejor-cultivo',  verificarToken, adminOEmpleado, mejorCultivo);
router.get('/por-fecha',      verificarToken, adminOEmpleado, porFecha);
router.get('/pdf',            verificarToken, adminOEmpleado, generarPDF);

module.exports = router;
