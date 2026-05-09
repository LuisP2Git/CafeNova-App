const axios = require('axios');
const db    = require('../config/db');

/** POST /ia — Enviar pregunta al modelo DeepSeek */
async function preguntarIA(req, res) {
    try {
        const { pregunta }  = req.body;
        const id_usuario    = req.usuario.id_usuario;

        const response = await axios.post(
            'https://api.deepseek.com/chat/completions',
            {
                model: 'deepseek-chat',
                messages: [
                    {
                        role: 'system',
                        content: 'Eres un experto caficultor colombiano.\nResponde claro y práctico.'
                    },
                    {
                        role: 'user',
                        content: pregunta
                    }
                ]
            },
            {
                headers: {
                    'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`,
                    'Content-Type':  'application/json'
                }
            }
        );

        const respuesta = response.data.choices[0].message.content;

        // Guardar conversación en BD (sin bloquear la respuesta)
        db.query(
            `INSERT INTO ia_mensajes (id_usuario, mensaje, respuesta) VALUES (?, ?, ?)`,
            [id_usuario, pregunta, respuesta]
        );

        res.json({ respuesta });

    } catch (error) {
        console.log('ERROR IA:', error.response?.data || error.message);
        res.status(500).json({ error: 'Error con IA' });
    }
}

/** GET /ia/historial — Obtener historial de mensajes IA del usuario */
function historialIA(req, res) {
    const id_usuario = req.usuario.id_usuario;

    db.query(
        `SELECT * FROM ia_mensajes 
         WHERE id_usuario = ?
         ORDER BY fecha ASC`,
        [id_usuario],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
}

module.exports = { preguntarIA, historialIA };
