const express = require('express');
const cors    = require('cors');

// Importar rutas
const authRoutes     = require('./routes/auth');
const fincasRoutes   = require('./routes/fincas');
const lotesRoutes    = require('./routes/lotes');
const cultivosRoutes = require('./routes/cultivos');
const cosechasRoutes = require('./routes/cosechas');
const reportesRoutes = require('./routes/reportes');
const empleadosRoutes= require('./routes/empleados');
const usuariosRoutes = require('./routes/usuarios');
const iaRoutes       = require('./routes/ia');
const inventarioRoutes = require('./routes/inventario');
const plagasRoutes = require('./routes/plagas');
const chatRoutes = require('./routes/chat');

const app = express();

// ─── Middlewares globales ────────────────────────────────────────────────────
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({
  limit: '50mb'
}));

app.use(express.urlencoded({
  extended: true,
  limit: '50mb'
}));
app.use((req, res, next) => {
    console.log(req.method, req.originalUrl);
    next();
});
// ─── Rutas ──────────────────────────────────────────────────────────────────
app.use('/',          authRoutes);
app.use('/fincas',    fincasRoutes);
app.use('/lotes',     lotesRoutes);
app.use('/cultivo',   cultivosRoutes);
app.use('/cosecha',   cosechasRoutes);
app.use('/cosechas', cosechasRoutes);
app.use('/reportes',  reportesRoutes);
app.use('/empleados', empleadosRoutes);
app.use('/usuarios',  usuariosRoutes);
app.use('/inventario', inventarioRoutes);
app.use('/plagas', plagasRoutes);
app.use('/chat',     chatRoutes);
app.use('/',          iaRoutes);       // /ia y /ia/historial

module.exports = app;
