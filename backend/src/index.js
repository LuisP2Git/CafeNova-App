const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
require('dotenv').config();
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const PDFDocument = require('pdfkit');
const dotenv = require('dotenv');
const axios = require('axios');
process.env.DEEPSEEK_API_KEY

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'cafenova'
});

db.connect(err => {
    if (err) return console.error(err);
    console.log('DB conectada');
});

// ===================== MIDDLEWARE =====================

function verificarToken(req, res, next) {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Token requerido' });

    db.query('SELECT * FROM usuarios WHERE token = ?', [token], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        if (result.length === 0) return res.status(401).json({ error: 'Token inválido' });
        req.usuario = result[0];
        next();
    });
}

function soloAdmin(req, res, next) {
    if (req.usuario.rol !== 'admin') {
        return res.status(403).json({ error: 'Solo admin' });
    }
    next();
}

// ===================== AUTH =====================

app.post('/registro', async (req, res) => {
    const { nombre_usuario, correo, password, cargo, telefono, fecha_contratacion, id_finca } = req.body;

    if (!nombre_usuario || !correo || !password) {
        return res.status(400).json({ error: 'Datos incompletos' });
    }

    try {
        const hash = await bcrypt.hash(password, 10);

        db.beginTransaction((err) => {
            if (err) return res.status(500).json({ error: err.message });

            // 1. insertar usuario
            db.query(
                `INSERT INTO usuarios (nombre_usuario, correo, password, rol, estado)
                 VALUES (?, ?, ?, 'empleado', 'pendiente')`,
                [nombre_usuario, correo, hash],
                (err, result) => {
                    if (err) {
                        return db.rollback(() =>
                            res.status(500).json({ error: err.message })
                        );
                    }

                    const id_usuario = result.insertId;

                    // 2. insertar empleado
                    db.query(
                        `INSERT INTO empleado 
                        (id_usuario, nombre, cargo, telefono, fecha_contratacion, id_finca)
                        VALUES (?, ?, ?, ?, ?, ?)`,
                        [
                            id_usuario,
                            nombre_usuario,
                            cargo || 'Sin asignar',
                            telefono || null,
                            fecha_contratacion || null,
                            id_finca || null
                        ],
                        (err2) => {
                            if (err2) {
                                return db.rollback(() =>
                                    res.status(500).json({ error: err2.message })
                                );
                            }

        db.commit((err3) => {
            if (err3) {
                return db.rollback(() =>
                    res.status(500).json({ error: err3.message })
                );
            }

            res.json({ mensaje: 'Registro exitoso' });
        });
    }
);
                }
            );
        });

    } catch {
        res.status(500).json({ error: 'Error servidor' });
    }
});

app.post('/login', async (req, res) => {
    const { identificador, password } = req.body;

    db.query(
        'SELECT * FROM usuarios WHERE nombre_usuario = ? OR correo = ?',
        [identificador, identificador],
        async (err, result) => {
            if (result.length === 0) return res.status(401).json({ error: 'No existe' });

            const user = result[0];
            const match = await bcrypt.compare(password, user.password);
            if (!match) return res.status(401).json({ error: 'Incorrecto' });

            if (user.estado !== 'activo') {
                return res.status(403).json({ error: 'Pendiente' });
            }

            const token = crypto.randomBytes(32).toString('hex');

            db.query(
                'UPDATE usuarios SET token=? WHERE id_usuario=?',
                [token, user.id_usuario],
                () => {
                    res.json({ token, usuario: user });
                }
            );
        }
    );
});

// ===================== FINCAS =====================

app.post('/fincas', verificarToken, soloAdmin, (req, res) => {
    const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;

    db.query(
        'INSERT INTO finca (nombre_finca, ubicacion, tamano_hectareas, propietario, id_admin) VALUES (?, ?, ?, ?, ?)',
        [nombre_finca, ubicacion, tamano_hectareas, propietario, req.usuario.id_usuario],
        (err, result) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ id: result.insertId });
        }
    );
});

app.get('/fincas', verificarToken, soloAdmin, (req, res) => {
    db.query(
        'SELECT * FROM finca WHERE id_admin = ?',
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
});

app.put('/fincas/:id', verificarToken, (req, res) => {
  const { id } = req.params;
  const { nombre_finca, ubicacion, tamano_hectareas, propietario } = req.body;

  db.query(
    `UPDATE finca 
     SET nombre_finca = ?, ubicacion = ?, tamano_hectareas = ?, propietario = ?
     WHERE id_finca = ?`,
    [nombre_finca, ubicacion, tamano_hectareas, propietario, id],
    (err) => {
      if (err) {
        console.log(err);
        return res.status(500).json({ error: err.message });
      }

      res.json({ message: 'Finca actualizada' });
    }
  );
});

app.delete('/fincas/:id', verificarToken, soloAdmin, (req, res) => {
  const { id } = req.params;

  // 🔥 eliminar lotes primero
  db.query('DELETE FROM lote WHERE id_finca = ?', [id], (err) => {
    if (err) {
      console.log("Error eliminando lotes:", err);
      return res.status(500).json({ error: err.message });
    }

    // 🔥 luego eliminar finca
    db.query('DELETE FROM finca WHERE id_finca = ?', [id], (err) => {
      if (err) {
        console.log("Error eliminando finca:", err);
        return res.status(500).json({ error: err.message });
      }

      res.json({ message: 'Finca eliminada correctamente' });
    });
  });
});

// ===================== LOTES =====================


// CREAR LOTE
app.post('/lotes', verificarToken, soloAdmin, (req, res) => {
    const { id_finca, nombre_lote, area, tipo_suelo } = req.body;

    db.query(
        'INSERT INTO lote (id_finca, nombre_lote, area, tipo_suelo) VALUES (?, ?, ?, ?)',
        [id_finca, nombre_lote, area, tipo_suelo],
        (err, result) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ id: result.insertId });
        }
    );
});

// 🔥 OBTENER LOTES (FIX NULL)
app.get('/lotes', verificarToken, (req, res) => {
    db.query(
        `SELECT 
            l.*, 
            f.nombre_finca 
         FROM lote l
         JOIN finca f ON l.id_finca = f.id_finca
         WHERE f.id_admin = ?`,
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
});

// 🔥 EDITAR LOTE
app.put('/lotes/:id', verificarToken, soloAdmin, (req, res) => {
    const { id } = req.params;
    const { id_finca, nombre_lote, area, tipo_suelo } = req.body;

    db.query(
        `UPDATE lote 
         SET id_finca = ?, nombre_lote = ?, area = ?, tipo_suelo = ?
         WHERE id_lote = ?`,
        [id_finca, nombre_lote, area, tipo_suelo, id],
        (err) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ error: err.message });
            }
            res.json({ message: 'Lote actualizado' });
        }
    );
});

// 🔥 ELIMINAR LOTE
app.delete('/lotes/:id', verificarToken, soloAdmin, (req, res) => {
    const { id } = req.params;

    db.query('DELETE FROM lote WHERE id_lote = ?', [id], (err) => {
        if (err) {
            console.log("ERROR DELETE:", err);
            return res.status(500).json({ error: err.message });
        }

        res.json({ message: 'Lote eliminado' });
    });
});
// ===================== CULTIVOS (MEJORADO) =====================

// ===================== CULTIVO CRUD =====================

// 🔹 GET CULTIVOS (para dropdown Flutter)
app.get('/cultivo', verificarToken, (req, res) => {
    db.query(
        `SELECT 
            c.*,
            l.nombre_lote,
            f.nombre_finca
         FROM cultivo c
         JOIN lote l ON c.id_lote = l.id_lote
         JOIN finca f ON l.id_finca = f.id_finca`,
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
});

// 🔹 CREAR CULTIVO
app.post('/cultivo', verificarToken, (req, res) => {
    const { id_lote, tipo_cultivo, variedad, fecha_siembra, estado } = req.body;

    db.query(
        `INSERT INTO cultivo (id_lote, tipo_cultivo, variedad, fecha_siembra, estado)
         VALUES (?, ?, ?, ?, ?)`,
        [id_lote, tipo_cultivo, variedad, fecha_siembra, estado],
        (err, result) => {
            if (err) {
                console.log("ERROR INSERT CULTIVO:", err);
                return res.status(500).json({ error: err.message });
            }

            res.status(201).json({
                message: 'Cultivo creado',
                id: result.insertId
            });
        }
    );
});

// 🔹 EDITAR CULTIVO
app.put('/cultivo/:id', verificarToken, (req, res) => {
    const { id } = req.params;
    const { id_lote, tipo_cultivo, variedad, fecha_siembra, estado } = req.body;

    db.query(
        `UPDATE cultivo
         SET id_lote = ?, tipo_cultivo = ?, variedad = ?, fecha_siembra = ?, estado = ?
         WHERE id_cultivo = ?`,
        [id_lote, tipo_cultivo, variedad, fecha_siembra, estado, id],
        (err, result) => {
            if (err) {
                console.log("ERROR UPDATE CULTIVO:", err);
                return res.status(500).json({ error: err.message });
            }

            res.json({ message: 'Cultivo actualizado' });
        }
    );
});

// 🔹 ELIMINAR CULTIVO (con cascada manual)
app.delete('/cultivo/:id', verificarToken, (req, res) => {
    const { id } = req.params;

    // 🔥 primero eliminar cosechas relacionadas
    db.query('DELETE FROM cosecha WHERE id_cultivo = ?', [id], (err) => {
        if (err) {
            console.log("ERROR DELETE COSECHAS:", err);
            return res.status(500).json({ error: err.message });
        }

        // 🔥 luego eliminar cultivo
        db.query('DELETE FROM cultivo WHERE id_cultivo = ?', [id], (err2) => {
            if (err2) {
                console.log("ERROR DELETE CULTIVO:", err2);
                return res.status(500).json({ error: err2.message });
            }

            res.json({ message: 'Cultivo eliminado' });
        });
    });
});

// ================= COSECHAS =================

// 🔹 OBTENER TODAS
app.get('/cosecha', (req, res) => {
  db.query(
    `SELECT * FROM cosecha ORDER BY fecha_cosecha DESC`,
    (err, results) => {
      if (err) {
        console.log("ERROR COSECHA:", err);
        return res.status(500).json({ error: err.message });
      }
      res.json(results);
    }
  );
});

// 🔹 OBTENER UNA
app.get('/cosecha/:id', (req, res) => {
  const { id } = req.params;

  db.query(
    'SELECT * FROM cosecha WHERE id_cosecha = ?',
    [id],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(results[0]);
    }
  );
});

// 🔹 CREAR
app.post('/cosecha', (req, res) => {
  const { id_cultivo, fecha_cosecha, cantidad_kg, calidad } = req.body;

  db.query(
    `INSERT INTO cosecha (id_cultivo, fecha_cosecha, cantidad_kg, calidad)
     VALUES (?, ?, ?, ?)`,
    [id_cultivo, fecha_cosecha, cantidad_kg, calidad],
    (err, result) => {
      if (err) {
        console.log("ERROR INSERT:", err);
        return res.status(500).json({ error: err.message });
      }

      res.status(201).json({
        message: 'Cosecha creada',
        id: result.insertId
      });
    }
  );
});

// 🔹 EDITAR
app.put('/cosecha/:id', (req, res) => {
  const { id } = req.params;
  const { id_cultivo, fecha_cosecha, cantidad_kg, calidad } = req.body;

  db.query(
    `UPDATE cosecha
     SET id_cultivo = ?, fecha_cosecha = ?, cantidad_kg = ?, calidad = ?
     WHERE id_cosecha = ?`,
    [id_cultivo, fecha_cosecha, cantidad_kg, calidad, id],
    (err, result) => {
      if (err) {
        console.log("ERROR UPDATE:", err);
        return res.status(500).json({ error: err.message });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({ error: 'No existe la cosecha' });
      }

      res.json({ message: 'Cosecha actualizada' });
    }
  );
});

// 🔹 ELIMINAR
app.delete('/cosecha/:id', (req, res) => {
  const { id } = req.params;

  db.query(
    'DELETE FROM cosecha WHERE id_cosecha = ?',
    [id],
    (err, result) => {
      if (err) {
        console.log("ERROR DELETE:", err);
        return res.status(500).json({ error: err.message });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({ error: 'No existe la cosecha' });
      }

      res.json({ message: 'Cosecha eliminada' });
    }
  );
});

// ===================== REPORTES =====================
// 🔐 ROLES: ADMIN Y EMPLEADO PUEDEN VER
function adminOEmpleado(req, res, next) {
    if (req.usuario.rol !== 'admin' && req.usuario.rol !== 'empleado') {
        return res.status(403).json({ error: 'Acceso denegado' });
    }
    next();
}

// ================= TOTAL COSECHA =================
app.get('/reportes/total-cosecha', verificarToken, adminOEmpleado, (req, res) => {
    db.query(`
        SELECT SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
        JOIN lote l ON cu.id_lote = l.id_lote
        JOIN finca f ON l.id_finca = f.id_finca
        WHERE f.id_admin = ?
    `, [req.usuario.id_usuario], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(result[0] || { total_kg: 0 });
    });
});

// ================= COSECHA MENSUAL =================
app.get('/reportes/cosecha-mensual', verificarToken, adminOEmpleado, (req, res) => {
    db.query(`
        SELECT DATE_FORMAT(c.fecha_cosecha, '%Y-%m') AS mes,
               SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
        JOIN lote l ON cu.id_lote = l.id_lote
        JOIN finca f ON l.id_finca = f.id_finca
        WHERE f.id_admin = ?
        GROUP BY mes
        ORDER BY mes
    `, [req.usuario.id_usuario], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(result);
    });
});

// ================= POR CALIDAD =================
app.get('/reportes/por-calidad', verificarToken, adminOEmpleado, (req, res) => {
    db.query(`
        SELECT c.calidad, SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
        JOIN lote l ON cu.id_lote = l.id_lote
        JOIN finca f ON l.id_finca = f.id_finca
        WHERE f.id_admin = ?
        GROUP BY c.calidad
    `, [req.usuario.id_usuario], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(result);
    });
});

// ================= MEJOR CULTIVO =================
app.get('/reportes/mejor-cultivo', verificarToken, adminOEmpleado, (req, res) => {
    db.query(`
        SELECT cu.tipo_cultivo, cu.variedad, SUM(c.cantidad_kg) AS total
        FROM cosecha c
        JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
        JOIN lote l ON cu.id_lote = l.id_lote
        JOIN finca f ON l.id_finca = f.id_finca
        WHERE f.id_admin = ?
        GROUP BY cu.id_cultivo
        ORDER BY total DESC
        LIMIT 1
    `, [req.usuario.id_usuario], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(result[0] || {});
    });
});

// ================= REPORTE POR FECHA =================
app.get('/reportes/por-fecha', verificarToken, adminOEmpleado, (req, res) => {
    const { desde, hasta } = req.query;

    if (!desde || !hasta) {
        return res.status(400).json({ error: 'Fechas requeridas' });
    }

    db.query(`
        SELECT DATE(c.fecha_cosecha) AS fecha,
               SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
        JOIN lote l ON cu.id_lote = l.id_lote
        JOIN finca f ON l.id_finca = f.id_finca
        WHERE f.id_admin = ?
        AND c.fecha_cosecha BETWEEN ? AND ?
        GROUP BY fecha
        ORDER BY fecha
    `, [req.usuario.id_usuario, desde, hasta], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(result);
    });
});

// ================= PDF (ADMIN Y EMPLEADO) =================
app.get('/reportes/pdf', verificarToken, adminOEmpleado, (req, res) => {

    const doc = new PDFDocument({ margin: 40 });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=reporte_cafenova.pdf');

    doc.pipe(res);

    // ================= HEADER =================
    doc
        .rect(0, 0, doc.page.width, 80)
        .fill('#6B7F66');

    doc
        .fillColor('white')
        .fontSize(20)
        .text('☕ Cafe Nova', 40, 25);

    doc
        .fontSize(10)
        .text(`Fecha: ${new Date().toLocaleDateString()}`, 400, 30);

    doc.moveDown(3);

    // ================= CONSULTAS =================
    db.query(`
        SELECT DATE(c.fecha_cosecha) AS fecha,
               SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
        JOIN lote l ON cu.id_lote = l.id_lote
        JOIN finca f ON l.id_finca = f.id_finca
        WHERE f.id_admin = ?
        GROUP BY fecha
        ORDER BY fecha
    `, [req.usuario.id_usuario], (err, results) => {

        if (err) {
            doc.text('Error generando reporte');
            doc.end();
            return;
        }

        let total = 0;

        results.forEach(r => total += r.total_kg);

        // ================= TARJETAS =================
        const cardY = 120;

        // CARD 1
        doc
            .roundedRect(40, cardY, 240, 70, 10)
            .fill('#F5F1ED');

        doc
            .fillColor('#333')
            .fontSize(12)
            .text('Producción Total', 60, cardY + 15);

        doc
            .fontSize(18)
            .fillColor('#6B7F66')
            .text(`${total} kg`, 60, cardY + 35);

        // ================= TABLA =================
        let y = 230;

        doc
            .fillColor('black')
            .fontSize(14)
            .text('Producción por Fecha', 40, y);

        y += 25;

        // encabezado
        doc
            .rect(40, y, 500, 25)
            .fill('#6B7F66');

        doc
            .fillColor('white')
            .fontSize(10)
            .text('Fecha', 60, y + 7)
            .text('Producción (kg)', 300, y + 7);

        y += 25;

        // filas
        results.forEach((r, i) => {
            const bg = i % 2 === 0 ? '#FFFFFF' : '#F5F1ED';

            doc
                .rect(40, y, 500, 25)
                .fill(bg);

            doc
                .fillColor('#333')
                .fontSize(10)
                .text(r.fecha.toISOString().split('T')[0], 60, y + 7)
                .text(`${r.total_kg} kg`, 300, y + 7);

            y += 25;
        });

        // ================= FOOTER =================
        doc.moveDown();

        doc
            .fontSize(10)
            .fillColor('gray')
            .text('Generado por Cafe Nova', 40, doc.page.height - 50, {
                align: 'center'
            });

        doc.end();
    });
});

// ===================== EMPLEADOS =====================

// 🔹 OBTENER EMPLEADOS
app.get('/empleados', verificarToken, (req, res) => {
    db.query(`
    SELECT 
        e.id_empleado,
        e.cargo,
        e.telefono,
        e.fecha_contratacion,
        e.id_finca,
        u.nombre_usuario AS nombre,
        u.correo,
        f.nombre_finca
    FROM empleado e
    JOIN usuarios u ON e.id_usuario = u.id_usuario
    LEFT JOIN finca f ON e.id_finca = f.id_finca
    WHERE (f.id_admin = ? OR e.id_finca IS NULL)
    AND u.estado = 'activo'
`, [req.usuario.id_usuario], (err, results) => {
        if (err) {
            console.log(err);
            return res.status(500).json({ error: err.message });
        }

        res.json(results);
    });
});

// 🔹 EDITAR EMPLEADO
app.put('/empleados/:id', verificarToken, (req, res) => {
    const { id } = req.params;
    const { cargo, telefono, fecha_contratacion, id_finca } = req.body;

    db.query(
        `UPDATE empleado 
         SET cargo = ?, telefono = ?, fecha_contratacion = ?, id_finca = ?
         WHERE id_empleado = ?`,
        [cargo, telefono, fecha_contratacion, id_finca, id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Empleado actualizado' });
        }
    );
});

// 🔹 ELIMINAR EMPLEADO
app.delete('/empleados/:id', verificarToken, (req, res) => {
    const { id } = req.params;

    db.query(
        'DELETE FROM empleado WHERE id_empleado = ?',
        [id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Empleado eliminado' });
        }
    );
});

// ===================== USUARIOS PENDIENTES =====================

// 🔹 OBTENER PENDIENTES
app.get('/usuarios/pendientes', verificarToken, soloAdmin, (req, res) => {
    db.query(
        "SELECT id_usuario, nombre_usuario, correo FROM usuarios WHERE estado = 'pendiente'",
        (err, results) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(results);
        }
    );
});

// 🔹 APROBAR USUARIO
app.put('/usuarios/aprobar/:id', verificarToken, soloAdmin, (req, res) => {
    const { id } = req.params;

    db.query(
        "UPDATE usuarios SET estado = 'activo' WHERE id_usuario = ?",
        [id],
        (err) => {
            if (err) {
                console.log("ERROR:", err);
                return res.status(500).json({ error: err.message });
            }

            res.json({ message: 'Usuario aprobado correctamente' });
        }
    );
});

// 🔹 RECHAZAR / ELIMINAR
app.delete('/usuarios/:id', verificarToken, soloAdmin, (req, res) => {
    const { id } = req.params;

    db.query(
        "DELETE FROM usuarios WHERE id_usuario = ?",
        [id],
        (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Usuario eliminado' });
        }
    );
});
// ===================== IA =====================
app.post('/ia', verificarToken, async (req, res) => {
    try {
        const { pregunta } = req.body;
        const id_usuario = req.usuario.id_usuario;

        const response = await axios.post(
            'https://api.deepseek.com/chat/completions',
            {
                model: "deepseek-chat",
                messages: [
                    {
                        role: "system",
                        content: `
Eres un experto caficultor colombiano.
Responde claro y práctico.
`
                    },
                    {
                        role: "user",
                        content: pregunta
                    }
                ]
            },
            {
                headers: {
                    'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        const respuesta = response.data.choices[0].message.content;

        // GUARDAR EN DB
        db.query(
            `INSERT INTO ia_mensajes (id_usuario, mensaje, respuesta)
             VALUES (?, ?, ?)`,
            [id_usuario, pregunta, respuesta]
        );

        res.json({ respuesta });

    } catch (error) {
        console.log("ERROR IA:", error.response?.data || error.message);
        res.status(500).json({ error: 'Error con IA' });
    }
});
app.get('/ia/historial', verificarToken, (req, res) => {
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
});

// ===================== SERVER =====================
console.log(process.env.DEEPSEEK_API_KEY);


app.listen(3000, () => console.log('Servidor corriendo en http://localhost:3000'));