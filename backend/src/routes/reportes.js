const express = require('express');
const router = express.Router();

const db = require('../config/db');
const { verificarToken } = require('../middleware/auth');

const PDFDocument = require('pdfkit');
const { ChartJSNodeCanvas } = require('chartjs-node-canvas');

// ============================================================
// HELPER MYSQL
// ============================================================

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, results) => {
      if (err) {
        reject(err);
      } else {
        resolve(results);
      }
    });
  });
}

// ============================================================
// PRODUCCIÓN MENSUAL
// ============================================================

router.get('/cosecha-mensual', verificarToken, async (req, res) => {

  try {

    const idUsuario = req.usuario.id_usuario;

    const rows = await run(`
      SELECT

        MONTH(co.fecha_cosecha) AS numero_mes,

        CASE MONTH(co.fecha_cosecha)

          WHEN 1 THEN 'Ene'
          WHEN 2 THEN 'Feb'
          WHEN 3 THEN 'Mar'
          WHEN 4 THEN 'Abr'
          WHEN 5 THEN 'May'
          WHEN 6 THEN 'Jun'
          WHEN 7 THEN 'Jul'
          WHEN 8 THEN 'Ago'
          WHEN 9 THEN 'Sep'
          WHEN 10 THEN 'Oct'
          WHEN 11 THEN 'Nov'
          WHEN 12 THEN 'Dic'

        END AS mes,

        COALESCE(SUM(co.cantidad_kg),0) AS total_kg

      FROM cosecha co

      INNER JOIN cultivo cu
        ON cu.id_cultivo = co.id_cultivo

      INNER JOIN lote l
        ON l.id_lote = cu.id_lote

      INNER JOIN finca f
        ON f.id_finca = l.id_finca

      WHERE f.id_admin = ?

      GROUP BY MONTH(co.fecha_cosecha)

      ORDER BY numero_mes ASC

    `, [idUsuario]);

    res.json(rows);

  } catch (e) {

    console.error(e);

    res.status(500).json([]);
  }
});

// ============================================================
// POR CALIDAD
// ============================================================

router.get('/por-calidad', verificarToken, async (req, res) => {

  try {

    const idUsuario = req.usuario.id_usuario;

    const rows = await run(`
      SELECT

        COALESCE(co.calidad,'Sin calidad')
          AS calidad,

        COALESCE(
          SUM(co.cantidad_kg),
          0
        ) AS total_kg

      FROM cosecha co

      INNER JOIN cultivo cu
        ON cu.id_cultivo = co.id_cultivo

      INNER JOIN lote l
        ON l.id_lote = cu.id_lote

      INNER JOIN finca f
        ON f.id_finca = l.id_finca

      WHERE f.id_admin = ?

      GROUP BY co.calidad

      ORDER BY total_kg DESC

    `, [idUsuario]);

    res.json(rows);

  } catch (e) {

    console.error(e);

    res.status(500).json([]);
  }
});

// ============================================================
// TOTAL COSECHA
// ============================================================

router.get('/total-cosecha', verificarToken, async (req, res) => {

  try {

    const idUsuario = req.usuario.id_usuario;

    const rows = await run(`
      SELECT
        COALESCE(SUM(co.cantidad_kg), 0) AS total_kg
      FROM cosecha co
      INNER JOIN cultivo cu
        ON cu.id_cultivo = co.id_cultivo
      INNER JOIN lote l
        ON l.id_lote = cu.id_lote
      INNER JOIN finca f
        ON f.id_finca = l.id_finca
      WHERE f.id_admin = ?
    `, [idUsuario]);

    res.json({
      total_kg: parseFloat(rows[0]?.total_kg || 0),
    });

  } catch (e) {

    console.error(e);

    res.status(500).json({
      total_kg: 0,
    });
  }
});

// ============================================================
// MEJOR CULTIVO
// ============================================================

router.get('/mejor-cultivo', verificarToken, async (req, res) => {

  try {

    const idUsuario = req.usuario.id_usuario;

    const rows = await run(`
      SELECT
        cu.tipo_cultivo,
        cu.variedad,
        COALESCE(SUM(co.cantidad_kg),0) AS total_kg
      FROM cosecha co
      INNER JOIN cultivo cu
        ON cu.id_cultivo = co.id_cultivo
      INNER JOIN lote l
        ON l.id_lote = cu.id_lote
      INNER JOIN finca f
        ON f.id_finca = l.id_finca
      WHERE f.id_admin = ?
      GROUP BY cu.tipo_cultivo, cu.variedad
      ORDER BY total_kg DESC
      LIMIT 1
    `, [idUsuario]);

    if (!rows.length) {

      return res.json({
        nombre: 'N/A',
        total_kg: 0,
      });
    }

    res.json({

      nombre:
          '${rows[0].tipo_cultivo} — ${rows[0].variedad}',

      total_kg:
          parseFloat(rows[0].total_kg || 0),

    });

  } catch (e) {

    console.error(e);

    res.status(500).json({
      nombre: 'N/A',
      total_kg: 0,
    });
  }
});

// ============================================================
// POR FINCA
// ============================================================

router.get('/por-finca', verificarToken, async (req, res) => {
  try {
    const idUsuario = req.usuario.id_usuario;

    const fincas = await run(
      `
      SELECT
        id_finca,
        nombre_finca,
        ubicacion,
        tamano_hectareas,
        propietario
      FROM finca
      WHERE id_admin = ?
      ORDER BY nombre_finca ASC
    `,
      [idUsuario]
    );

    const resultado = [];

    for (const finca of fincas) {
      const lotes = await run(
        `
        SELECT
          id_lote,
          nombre_lote,
          area,
          tipo_suelo
        FROM lote
        WHERE id_finca = ?
      `,
        [finca.id_finca]
      );

      const lotesConDatos = [];

      for (const lote of lotes) {
        const cultivos = await run(
          `
          SELECT
            cu.id_cultivo,
            cu.tipo_cultivo,
            cu.variedad,
            cu.fecha_siembra,
            cu.estado
          FROM cultivo cu
          WHERE cu.id_lote = ?
        `,
          [lote.id_lote]
        );

        const cultivosConCosechas = [];

        for (const cultivo of cultivos) {
          const cosechas = await run(
            `
            SELECT
              id_cosecha,
              fecha_cosecha,
              cantidad_kg,
              calidad
            FROM cosecha
            WHERE id_cultivo = ?
            ORDER BY fecha_cosecha DESC
          `,
            [cultivo.id_cultivo]
          );

          cultivosConCosechas.push({
            ...cultivo,
            cosechas,
          });
        }

        lotesConDatos.push({
          ...lote,
          cultivos: cultivosConCosechas,
        });
      }

      resultado.push({
        ...finca,
        lotes: lotesConDatos,
      });
    }

    res.json(resultado);
  } catch (error) {
    console.error('GET /por-finca', error);

    res.status(500).json({
      error: 'Error por finca',
    });
  }
});

// ============================================================
// TENDENCIAS
// ============================================================

router.get('/por-fecha', verificarToken, async (req, res) => {

  try {

    const idUsuario = req.usuario.id_usuario;

    const { desde, hasta } = req.query;

    const rows = await run(`
      SELECT

        co.fecha_cosecha AS fecha,

        COALESCE(
          co.cantidad_kg,
          0
        ) AS total_kg,

        COALESCE(
          co.calidad,
          ''
        ) AS calidad,

        COALESCE(
          cu.tipo_cultivo,
          ''
        ) AS tipo_cultivo,

        COALESCE(
          cu.variedad,
          ''
        ) AS variedad,

        COALESCE(
          l.nombre_lote,
          ''
        ) AS nombre_lote,

        COALESCE(
          f.nombre_finca,
          ''
        ) AS nombre_finca

      FROM cosecha co

      INNER JOIN cultivo cu
        ON cu.id_cultivo = co.id_cultivo

      INNER JOIN lote l
        ON l.id_lote = cu.id_lote

      INNER JOIN finca f
        ON f.id_finca = l.id_finca

      WHERE f.id_admin = ?

      AND DATE(co.fecha_cosecha)
      BETWEEN ? AND ?

      ORDER BY co.fecha_cosecha ASC

    `, [idUsuario, desde, hasta]);

    res.json(rows);

  } catch (e) {

    console.error(e);

    res.status(500).json([]);
  }
});

// ============================================================
// GUARDAR REPORTE
// ============================================================

router.post('/', verificarToken, async (req, res) => {
  try {
    const idUsuario = req.usuario.id_usuario;

    const empleado = await run(
      `
      SELECT id_empleado
      FROM empleado
      WHERE id_usuario = ?
      LIMIT 1
    `,
      [idUsuario]
    );

    if (!empleado.length) {
      return res.status(400).json({
        error: 'Empleado no encontrado',
      });
    }

    const { titulo, descripcion, tipo_reporte } = req.body;

    const result = await run(
      `
      INSERT INTO reporte (
        id_empleado,
        titulo,
        descripcion,
        tipo_reporte,
        fecha,
        created_at
      )
      VALUES (?, ?, ?, ?, CURDATE(), NOW())
    `,
      [
        empleado[0].id_empleado,
        titulo || 'Reporte',
        descripcion || '',
        tipo_reporte || 'general',
      ]
    );

    res.status(201).json({
      id_reporte: result.insertId,
    });
  } catch (error) {
    console.error('POST /reportes', error);

    res.status(500).json({
      error: 'Error guardando reporte',
    });
  }
});

// ============================================================
// PDF
// ============================================================

router.get('/pdf', verificarToken, async (req, res) => {
  try {
    const idUsuario = req.usuario.id_usuario;

    const mensual = await run(
      `
      SELECT
        DATE_FORMAT(co.fecha_cosecha, '%Y-%m') AS mes,
        SUM(co.cantidad_kg) AS total_kg
      FROM cosecha co
      INNER JOIN cultivo cu
        ON cu.id_cultivo = co.id_cultivo
      INNER JOIN lote l
        ON l.id_lote = cu.id_lote
      INNER JOIN finca f
        ON f.id_finca = l.id_finca
      WHERE f.id_admin = ?
      GROUP BY mes
      ORDER BY mes ASC
    `,
      [idUsuario]
    );

    const chartCanvas = new ChartJSNodeCanvas({
      width: 700,
      height: 350,
    });

    const image = await chartCanvas.renderToBuffer({
      type: 'bar',
      data: {
        labels: mensual.map((m) => m.mes),
        datasets: [
          {
            label: 'Producción KG',
            data: mensual.map((m) =>
              parseFloat(m.total_kg || 0)
            ),
            backgroundColor: '#6B7F66',
          },
        ],
      },
    });

    const doc = new PDFDocument({
      margin: 40,
    });

    res.setHeader(
      'Content-Type',
      'application/pdf'
    );

    res.setHeader(
      'Content-Disposition',
      'attachment; filename=reporte_cafenova.pdf'
    );

    doc.pipe(res);

    doc
      .fontSize(22)
      .text('CafeNova', {
        align: 'center',
      });

    doc.moveDown();

    doc.fontSize(16).text('Reporte General');

    doc.moveDown();

    doc.image(image, {
      fit: [500, 250],
      align: 'center',
    });

    doc.moveDown(2);

    mensual.forEach((m) => {
      doc.text(
        `${m.mes}: ${parseFloat(
          m.total_kg || 0
        ).toFixed(1)} KG`
      );
    });

    doc.end();
  } catch (error) {
    console.error('GET /pdf', error);

    if (!res.headersSent) {
      res.status(500).json({
        error: 'Error PDF',
      });
    }
  }
});

module.exports = router;
