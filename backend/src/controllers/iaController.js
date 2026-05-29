const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const db = require('../config/db');

const genAI = new GoogleGenerativeAI(
    process.env.GEMINI_API_KEY
);

// Modelo Gemini recomendado
const MODEL_NAME = 'gemini-2.5-flash';

/**
 * =========================================================
 * CHAT IA
 * =========================================================
 */
async function preguntarIA(req, res) {

    try {

        const { pregunta } = req.body;

        const id_usuario = req.usuario?.id_usuario;

        if (!pregunta) {
            return res.status(400).json({
                success: false,
                error: 'La pregunta es obligatoria'
            });
        }

        const model = genAI.getGenerativeModel({
            model: MODEL_NAME,
            generationConfig: {
                temperature: 0.4,
                maxOutputTokens: 2048
            }
        });

        const promptSistema = `
Eres un experto caficultor colombiano.

Especialidades:
- Cultivo de café
- Suelos
- Fertilizantes
- Plagas
- Enfermedades
- Producción agrícola
- Administración de fincas cafeteras
- Cosechas

Debes responder:
- Claro
- Profesional
- Práctico
- En español
`;

        const result = await model.generateContent([
            promptSistema,
            pregunta
        ]);

        const response = await result.response;

        const respuesta = response.text();

        // Guardar historial si existe usuario
        if (id_usuario) {

            db.query(
                `
                INSERT INTO ia_mensajes
                (id_usuario, mensaje, respuesta)
                VALUES (?, ?, ?)
                `,
                [id_usuario, pregunta, respuesta],
                (err) => {
                    if (err) {
                        console.log(
                            'ERROR GUARDANDO HISTORIAL:',
                            err.message
                        );
                    }
                }
            );
        }

        return res.json({
            success: true,
            respuesta,
            usageMetadata:
                response.usageMetadata || null
        });

    } catch (error) {

        console.log(
            'ERROR IA:',
            error.response?.data || error.message
        );

        // Rate limit
        if (error.status === 429) {
            return res.status(429).json({
                success: false,
                error: 'Límite de peticiones alcanzado'
            });
        }

        // API inválida
        if (error.status === 401) {
            return res.status(401).json({
                success: false,
                error: 'API KEY inválida'
            });
        }

        // Error de red
        if (
            error.code === 'ECONNABORTED' ||
            error.code === 'ENOTFOUND'
        ) {
            return res.status(500).json({
                success: false,
                error: 'Error de conexión'
            });
        }

        return res.status(500).json({
            success: false,
            error:
                error.message ||
                'Error interno con IA'
        });
    }
}

/**
 * =========================================================
 * HISTORIAL IA
 * =========================================================
 */
function historialIA(req, res) {

    try {

        const id_usuario = req.usuario?.id_usuario;

        if (!id_usuario) {
            return res.status(401).json({
                success: false,
                error: 'Usuario no autenticado'
            });
        }

        db.query(
            `
            SELECT *
            FROM ia_mensajes
            WHERE id_usuario = ?
            ORDER BY fecha ASC
            `,
            [id_usuario],
            (err, results) => {

                if (err) {
                    return res.status(500).json({
                        success: false,
                        error: err.message
                    });
                }

                return res.json({
                    success: true,
                    historial: results
                });
            }
        );

    } catch (error) {

        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
}

/**
 * =========================================================
 * ANALIZAR IMAGEN CON GEMINI VISION
 * =========================================================
 */
async function analizarImagenIA(req, res) {

    try {

        const {
            imagen_base64,
            mime_type,
            prompt,
            temperature,
            maxTokens
        } = req.body;

        if (!imagen_base64) {
            return res.status(400).json({
                success: false,
                error: 'No se recibió ninguna imagen'
            });
        }

        const model = genAI.getGenerativeModel({
            model: MODEL_NAME,
            generationConfig: {
                temperature: temperature || 0.3,
                maxOutputTokens: maxTokens || 4096
            }
        });

        const imagePart = {
            inlineData: {
                data: imagen_base64,
                mimeType:
                    mime_type || 'image/jpeg'
            }
        };

        const promptFinal = prompt || `
Eres un ingeniero agrónomo experto en café.

Analiza la imagen detalladamente.

Debes:
- Detectar enfermedades
- Detectar plagas
- Analizar hojas
- Analizar suelo
- Analizar frutos
- Detectar problemas visibles
- Recomendar soluciones
- Explicar el análisis claramente

Responde en español.
`;

        const result = await model.generateContent([
            promptFinal,
            imagePart
        ]);

        const response = await result.response;

        const texto = response.text();

        return res.json({
            success: true,
            respuesta: texto,
            usageMetadata:
                response.usageMetadata || null
        });

    } catch (error) {

        console.log(
            'ERROR GEMINI:',
            error.response?.data || error.message
        );

        // Rate limit
        if (error.status === 429) {
            return res.status(429).json({
                success: false,
                error: 'Rate limit excedido'
            });
        }

        // API inválida
        if (error.status === 401) {
            return res.status(401).json({
                success: false,
                error: 'API KEY inválida'
            });
        }

        // Imagen inválida
        if (error.message?.includes('mime')) {
            return res.status(400).json({
                success: false,
                error: 'Formato de imagen inválido'
            });
        }

        return res.status(500).json({
            success: false,
            error:
                error.message ||
                'Error analizando imagen'
        });
    }
}

module.exports = {
    preguntarIA,
    historialIA,
    analizarImagenIA
};