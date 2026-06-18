const PDFDocument = require('pdfkit');
const db = require('../config/db');

function esAdmin(req) {
    return req.usuario.rol === 'admin';
}

function obtenerFiltroReportes(req) {

    if (req.usuario.rol === 'admin') {

        return {
            admin: true
        };
    }

    return {
        admin: false,
        finca: req.empleado.id_finca
    };
}

/** GET /reportes/total-cosecha */
function totalCosecha(req, res) {

    let query;
    let params;

    if (req.usuario.rol === 'admin') {

        query = `
            SELECT
                SUM(c.cantidad_kg) AS total_kg
            FROM cosecha c
            JOIN cultivo cu
                ON c.id_cultivo = cu.id_cultivo
            JOIN lote l
                ON cu.id_lote = l.id_lote
            JOIN finca f
                ON l.id_finca = f.id_finca
            WHERE f.id_admin = ?
        `;

        params = [req.usuario.id_usuario];

    } else {

        query = `
            SELECT
                SUM(c.cantidad_kg) AS total_kg
            FROM cosecha c
            JOIN cultivo cu
                ON c.id_cultivo = cu.id_cultivo
            JOIN lote l
                ON cu.id_lote = l.id_lote
            WHERE l.id_finca = ?
        `;

        params = [req.empleado.id_finca];
    }

    db.query(query, params, (err, result) => {

        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.json(result[0] || {
            total_kg: 0
        });
    });
}

/** GET /reportes/cosecha-mensual */
function cosechaMensual(req, res) {

    const filtro = obtenerFiltroReportes(req);

    let query;
    let params;

    if (filtro.admin) {

    query = `
    SELECT
        c.calidad,
        SUM(c.cantidad_kg) AS total_kg
    FROM cosecha c
    JOIN cultivo cu
        ON c.id_cultivo = cu.id_cultivo
    JOIN lote l
        ON cu.id_lote = l.id_lote
    JOIN finca f
        ON l.id_finca = f.id_finca
    WHERE f.id_admin = ?
    GROUP BY c.calidad
    `;

    params = [req.usuario.id_usuario];
} 
    else {
        query = `
        SELECT
            cu.tipo_cultivo,
            cu.variedad,
            SUM(c.cantidad_kg) AS total
        FROM cosecha c
        JOIN cultivo cu
            ON c.id_cultivo = cu.id_cultivo
        JOIN lote l
            ON cu.id_lote = l.id_lote
        GROUP BY cu.id_cultivo
        ORDER BY total DESC
        LIMIT 1
        `;

params = [filtro.finca];
    }

    db.query(query, params, (err, result) => {

        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.json(result);
    });
}

/** GET /reportes/por-calidad */
function porCalidad(req, res) {

    const filtro = obtenerFiltroReportes(req);

    let query;
    let params;

    if (filtro.admin) {

        query = `
        SELECT
            c.calidad,
            SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu
            ON c.id_cultivo = cu.id_cultivo
        JOIN lote l
            ON cu.id_lote = l.id_lote
        GROUP BY c.calidad
        `;

        params = [
  req.usuario.id_usuario
];

    } else {

        query = `
        SELECT
            c.calidad,
            SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu
            ON c.id_cultivo = cu.id_cultivo
        JOIN lote l
            ON cu.id_lote = l.id_lote
        WHERE l.id_finca = ?
        GROUP BY c.calidad
        `;

        params = [filtro.finca];
    }

    db.query(query, params, (err, result) => {

        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.json(result);
    });
}

/** GET /reportes/mejor-cultivo */
function mejorCultivo(req, res) {

    const filtro = obtenerFiltroReportes(req);

    let query;
    let params;

    if (filtro.admin) {

        query = `
        SELECT
            cu.tipo_cultivo,
            cu.variedad,
            SUM(c.cantidad_kg) AS total
        FROM cosecha c
        JOIN cultivo cu
            ON c.id_cultivo = cu.id_cultivo
        JOIN lote l
            ON cu.id_lote = l.id_lote
        JOIN finca f
            ON l.id_finca = f.id_finca
        WHERE f.id_admin = ?
        GROUP BY cu.id_cultivo
        ORDER BY total DESC
        LIMIT 1
        `;

        params = [];

    } else {

        query = `
        SELECT
            cu.tipo_cultivo,
            cu.variedad,
            SUM(c.cantidad_kg) AS total
        FROM cosecha c
        JOIN cultivo cu
            ON c.id_cultivo = cu.id_cultivo
        JOIN lote l
            ON cu.id_lote = l.id_lote
        WHERE l.id_finca = ?
        GROUP BY cu.id_cultivo
        ORDER BY total DESC
        LIMIT 1
        `;

        params = [filtro.finca];
    }

    db.query(query, params, (err, result) => {

        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.json(result[0] || {});
    });
}

/** GET /reportes/por-fecha */
function porFecha(req, res) {

    const { desde, hasta } = req.query;

    if (!desde || !hasta) {
        return res.status(400).json({
            error: 'Fechas requeridas'
        });
    }

    const filtro = obtenerFiltroReportes(req);

    let query;
    let params;

    if (filtro.admin) {

        query = `
        SELECT
            DATE(c.fecha_cosecha) AS fecha,
            SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu
            ON c.id_cultivo = cu.id_cultivo
        JOIN lote l
            ON cu.id_lote = l.id_lote
        WHERE c.fecha_cosecha BETWEEN ? AND ?
        GROUP BY fecha
        ORDER BY fecha
        `;
        params = [
            desde,
            hasta
        ];

    } else {

        query = `
        SELECT
            DATE(c.fecha_cosecha) AS fecha,
            SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu
            ON c.id_cultivo = cu.id_cultivo
        JOIN lote l
            ON cu.id_lote = l.id_lote
        WHERE l.id_finca = ?
        AND c.fecha_cosecha BETWEEN ? AND ?
        GROUP BY fecha
        ORDER BY fecha
        `;

        params = [
            filtro.finca,
            desde,
            hasta
        ];
    }

    db.query(query, params, (err, result) => {

        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.json(result);
    });
}

/** GET /reportes/resumen-lotes */
function resumenPorLotes(req, res) {

    const { id_lote } = req.query;

    let query;
    let params;

    if (req.usuario.rol === 'admin') {

        query = `
            SELECT
                l.id_lote,
                l.nombre_lote,
                SUM(c.cantidad_kg) AS total_kg
            FROM cosecha c
            JOIN cultivo cu
                ON c.id_cultivo = cu.id_cultivo
            JOIN lote l
                ON cu.id_lote = l.id_lote
            JOIN finca f
                ON l.id_finca = f.id_finca
            WHERE f.id_admin = ?
        `;

        params = [req.usuario.id_usuario];

    } else {

        query = `
            SELECT
                l.id_lote,
                l.nombre_lote,
                SUM(c.cantidad_kg) AS total_kg
            FROM cosecha c
            JOIN cultivo cu
                ON c.id_cultivo = cu.id_cultivo
            JOIN lote l
                ON cu.id_lote = l.id_lote
            WHERE l.id_finca = ?
        `;

        params = [req.empleado.id_finca];
    }

    if (id_lote) {
        query += ' AND l.id_lote = ?';
        params.push(id_lote);
    }

    query += `
        GROUP BY l.id_lote
        ORDER BY total_kg DESC
    `;

    db.query(query, params, (err, results) => {
        if (err) {
            return res.status(500).json({
                error: err.message
            });
        }

        res.json(results);
    });
}

/** GET /reportes/reporte-finca */
function reportePorFinca(req, res) {

    db.query(
        `
        SELECT
            l.id_finca,
            COUNT(c.id_cosecha) AS total_cosechas,
            SUM(c.cantidad_kg) AS total_kg
        FROM lote l
        LEFT JOIN cultivo cu
            ON cu.id_lote = l.id_lote
        LEFT JOIN cosecha c
            ON c.id_cultivo = cu.id_cultivo
        WHERE l.id_finca = ?
        GROUP BY l.id_finca
        `,
        [req.empleado.id_finca],
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

/** GET /reportes/pdf */
function generarPDF(req, res) {

    const doc = new PDFDocument({
        size: 'A4',
        margin: 40
    });

    res.setHeader(
        'Content-Type',
        'application/pdf'
    );

    res.setHeader(
        'Content-Disposition',
        'attachment; filename=CafeNova_Reporte.pdf'
    );

    doc.pipe(res);

    db.query(
        `
        SELECT
            DATE(c.fecha_cosecha) AS fecha,
            SUM(c.cantidad_kg) AS total_kg
        FROM cosecha c
        JOIN cultivo cu
            ON c.id_cultivo = cu.id_cultivo
        JOIN lote l
            ON cu.id_lote = l.id_lote
        WHERE l.id_finca = ?
        GROUP BY fecha
        ORDER BY fecha
        `,
        [req.empleado.id_finca],
        (err, results) => {

            if (err) {

                doc.fontSize(16)
                   .text('Error generando reporte');

                doc.end();

                return;
            }

            let totalKg = 0;

            results.forEach(r => {
                totalKg += Number(r.total_kg || 0);
            });

            // =========================
            // HEADER
            // =========================

            doc.rect(
                0,
                0,
                doc.page.width,
                110
            )
            .fill('#2E7D32');

            doc.fillColor('white')
                .fontSize(28)
                .font('Helvetica-Bold')
                .text(
                    'CafeNova',
                    40,
                    25
                );

            doc.fontSize(12)
                .font('Helvetica')
                .text(
                    'Sistema Inteligente de Gestión Cafetera',
                    40,
                    60
                );

            doc.text(
                `Fecha: ${new Date().toLocaleDateString()}`,
                400,
                35
            );

            // =========================
            // TITULO
            // =========================

            let y = 150;

doc.fillColor('#222')
   .fontSize(22)
   .font('Helvetica-Bold')
   .text(
      'Reporte General de Producción',
      40,
      y,
      {
         align: 'center'
      }
   );

y += 70;

            // =========================
            // RESUMEN EJECUTIVO
            // =========================

            doc.roundedRect(
    40,
    y,
    515,
    100,
    10
)
.fill('#F5F8F5');

            doc.fillColor('#2E7D32')
                .fontSize(14)
                .font('Helvetica-Bold')
                .text(
                    'Resumen Ejecutivo',
                    55,
                    y + 15
                );

            doc.fillColor('#333')
                .fontSize(11)
                .font('Helvetica')
                .text(
                    `La finca registró una producción acumulada de ${totalKg.toFixed(2)} kg de café durante el período evaluado.`,
                    55,
                    y + 40,
                    {
                        width: 450
                    }
                );

            y += 130;

            // =========================
            // KPI PRODUCCION
            // =========================

            doc.roundedRect(
                40,
                y,
                240,
                90,
                12
            )
            .fill('#E8F5E9');

            doc.fillColor('#2E7D32')
                .fontSize(13)
                .font('Helvetica-Bold')
                .text(
                    'Producción Total',
                    60,
                    y + 18
                );

            doc.fillColor('#1B5E20')
                .fontSize(24)
                .font('Helvetica-Bold')
                .text(
                    `${totalKg.toFixed(2)} kg`,
                    60,
                    y + 42
                );

            doc.roundedRect(
                315,
                y,
                240,
                90,
                12
            )
            .fill('#FFF8E1');

            doc.fillColor('#EF6C00')
                .fontSize(13)
                .font('Helvetica-Bold')
                .text(
                    'Registros Analizados',
                    335,
                    y + 18
                );

            doc.fillColor('#E65100')
                .fontSize(24)
                .font('Helvetica-Bold')
                .text(
                    `${results.length}`,
                    335,
                    y + 42
                );

            y += 125;

            // =========================
            // TABLA
            // =========================

            doc.fillColor('#222')
                .fontSize(16)
                .font('Helvetica-Bold')
                .text(
                    'Producción por Fecha',
                    40,
                    y
                );

            y += 30;

            doc.rect(
                40,
                y,
                515,
                30
            )
            .fill('#2E7D32');

            doc.fillColor('white')
                .fontSize(11)
                .font('Helvetica-Bold')
                .text(
                    'Fecha',
                    60,
                    y + 9
                );

            doc.text(
                'Producción (kg)',
                320,
                y + 9
            );

            y += 30;

            results.forEach((item, index) => {

                const color =
                    index % 2 === 0
                        ? '#FFFFFF'
                        : '#F5F8F5';

                doc.rect(
                    40,
                    y,
                    515,
                    28
                )
                .fill(color);

                doc.fillColor('#333')
                    .fontSize(10)
                    .font('Helvetica')
                    .text(
                        item.fecha
                            .toISOString()
                            .split('T')[0],
                        60,
                        y + 8
                    );

                doc.text(
    `${item.total_kg} kg`,
    320,
    y + 8
);

y += 28;

if (y > 700) {

    doc.addPage();

    y = 60;

    doc.rect(
        40,
        y,
        515,
        30
    )
    .fill('#2E7D32');

    doc.fillColor('white')
        .fontSize(11)
        .font('Helvetica-Bold')
        .text('Fecha', 60, y + 9);

    doc.text(
        'Producción (kg)',
        320,
        y + 9
    );

    y += 40;
}
            });

            // =========================
            // RESUMEN FINAL
            // =========================

if (y + 90 > 700) {
    doc.addPage();
    y = 60;
}

            y += 20;

            doc.roundedRect(
    40,
    y,
    515,
    100,
    10
)
            .fill('#E8F5E9');

            doc.fillColor('#1B5E20')
                .fontSize(15)
                .font('Helvetica-Bold')
                .text(
                    `Producción acumulada: ${totalKg.toFixed(2)} kg`,
                    60,
                    y + 25
                );

            // =========================
            // FOOTER
            // =========================

            doc.fillColor('#888')
                .fontSize(9)
                .font('Helvetica')
                .text(
                    'Reporte generado automáticamente por CafeNova',
                    0,
                    doc.page.height - 45,
                    {
                        align: 'center'
                    }
                );

            doc.text(
                'Sistema Inteligente de Gestión Cafetera',
                0,
                doc.page.height - 30,
                {
                    align: 'center'
                }
            );

            doc.end();
        }
    );
}

module.exports = {
    totalCosecha,
    cosechaMensual,
    porCalidad,
    mejorCultivo,
    porFecha,
    resumenPorLotes,
    reportePorFinca,
    generarPDF
};
