require('dotenv').config();

console.log("GEMINI:", process.env.GEMINI_API_KEY);

// Conexión a la base de datos (se establece al importar)
require('./src/config/db');

const app  = require('./src/app');
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});
