const PDFDocument = require('pdfkit');
const db          = require('../config/db');

/** GET /reportes/total-cosecha */
function totalCosecha(req, res) {
    db.query(
        `SELECT SUM(c.cantidad_kg) AS total_kg
         FROM cosecha c
         JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
         JOIN lote l     ON cu.id_lote   = l.id_lote
         JOIN finca f    ON l.id_finca   = f.id_finca
         WHERE f.id_admin = ?`,
        [req.usuario.id_usuario],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(result[0] || { total_kg: 0 });
        }
    );
}

/** GET /reportes/cosecha-mensual */
function cosechaMensual(req, res) {
    db.query(
        `SELECT DATE_FORMAT(c.fecha_cosecha, '%Y-%m') AS mes,
                SUM(c.cantidad_kg) AS total_kg
         FROM cosecha c
         JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
         JOIN lote l     ON cu.id_lote   = l.id_lote
         JOIN finca f    ON l.id_finca   = f.id_finca
         WHERE f.id_admin = ?
         GROUP BY mes
         ORDER BY mes`,
        [req.usuario.id_usuario],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(result);
        }
    );
}

/** GET /reportes/por-calidad */
function porCalidad(req, res) {
    db.query(
        `SELECT c.calidad, SUM(c.cantidad_kg) AS total_kg
         FROM cosecha c
         JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
         JOIN lote l     ON cu.id_lote   = l.id_lote
         JOIN finca f    ON l.id_finca   = f.id_finca
         WHERE f.id_admin = ?
         GROUP BY c.calidad`,
        [req.usuario.id_usuario],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(result);
        }
    );
}

/** GET /reportes/mejor-cultivo */
function mejorCultivo(req, res) {
    db.query(
        `SELECT cu.tipo_cultivo, cu.variedad, SUM(c.cantidad_kg) AS total
         FROM cosecha c
         JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
         JOIN lote l     ON cu.id_lote   = l.id_lote
         JOIN finca f    ON l.id_finca   = f.id_finca
         WHERE f.id_admin = ?
         GROUP BY cu.id_cultivo
         ORDER BY total DESC
         LIMIT 1`,
        [req.usuario.id_usuario],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(result[0] || {});
        }
    );
}

/** GET /reportes/por-fecha?desde=YYYY-MM-DD&hasta=YYYY-MM-DD */
function porFecha(req, res) {
    const { desde, hasta } = req.query;

    if (!desde || !hasta) {
        return res.status(400).json({ error: 'Fechas requeridas' });
    }

    db.query(
        `SELECT DATE(c.fecha_cosecha) AS fecha,
                SUM(c.cantidad_kg) AS total_kg
         FROM cosecha c
         JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
         JOIN lote l     ON cu.id_lote   = l.id_lote
         JOIN finca f    ON l.id_finca   = f.id_finca
         WHERE f.id_admin = ?
           AND c.fecha_cosecha BETWEEN ? AND ?
         GROUP BY fecha
         ORDER BY fecha`,
        [req.usuario.id_usuario, desde, hasta],
        (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(result);
        }
    );
}

/** GET /reportes/pdf — Generar PDF con reporte de cosechas */
function generarPDF(req, res) {
    const doc = new PDFDocument({ margin: 40 });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=reporte_cafenova.pdf');
    doc.pipe(res);

    // Header
    doc.rect(0, 0, doc.page.width, 80).fill('#6B7F66');
    doc.fillColor('white').fontSize(20).text('☕ Cafe Nova', 40, 25);
    doc.fontSize(10).text(`Fecha: ${new Date().toLocaleDateString()}`, 400, 30);
    doc.moveDown(3);

    db.query(
        `SELECT DATE(c.fecha_cosecha) AS fecha,
                SUM(c.cantidad_kg) AS total_kg
         FROM cosecha c
         JOIN cultivo cu ON c.id_cultivo = cu.id_cultivo
         JOIN lote l     ON cu.id_lote   = l.id_lote
         JOIN finca f    ON l.id_finca   = f.id_finca
         WHERE f.id_admin = ?
         GROUP BY fecha
         ORDER BY fecha`,
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) {
                doc.text('Error generando reporte');
                doc.end();
                return;
            }

            let total = 0;
            results.forEach(r => { total += r.total_kg; });

            // Tarjeta de producción total
            const cardY = 120;
            doc.roundedRect(40, cardY, 240, 70, 10).fill('#F5F1ED');
            doc.fillColor('#333').fontSize(12).text('Producción Total', 60, cardY + 15);
            doc.fontSize(18).fillColor('#6B7F66').text(`${total} kg`, 60, cardY + 35);

            // Tabla
            let y = 230;
            doc.fillColor('black').fontSize(14).text('Producción por Fecha', 40, y);
            y += 25;

            doc.rect(40, y, 500, 25).fill('#6B7F66');
            doc.fillColor('white').fontSize(10)
                .text('Fecha', 60, y + 7)
                .text('Producción (kg)', 300, y + 7);
            y += 25;

            results.forEach((r, i) => {
                const bg = i % 2 === 0 ? '#FFFFFF' : '#F5F1ED';
                doc.rect(40, y, 500, 25).fill(bg);
                doc.fillColor('#333').fontSize(10)
                    .text(r.fecha.toISOString().split('T')[0], 60, y + 7)
                    .text(`${r.total_kg} kg`, 300, y + 7);
                y += 25;
            });

            // Footer
            doc.moveDown();
            doc.fontSize(10).fillColor('gray')
                .text('Generado por Cafe Nova', 40, doc.page.height - 50, { align: 'center' });

            doc.end();
        }
    );
}

function reportePorFinca(req, res) {
    db.query(
        `
        SELECT
            f.id_finca,
            f.nombre_finca,
            COUNT(c.id_cosecha) AS total_cosechas,
            SUM(c.cantidad_kg) AS total_kg
        FROM finca f
        LEFT JOIN lote l
            ON l.id_finca = f.id_finca
        LEFT JOIN cultivo cu
            ON cu.id_lote = l.id_lote
        LEFT JOIN cosecha c
            ON c.id_cultivo = cu.id_cultivo
        WHERE f.id_admin = ?
        GROUP BY f.id_finca
        ORDER BY total_kg DESC
        `,
        [req.usuario.id_usuario],
        (err, results) => {
            if (err) {
                console.log(err);
                return res.status(500).json({
                    error: err.message
                });
            }

            res.json(results);
        }
    );
}

module.exports = {totalCosecha, cosechaMensual, porCalidad, mejorCultivo, porFecha, generarPDF, reportePorFinca};