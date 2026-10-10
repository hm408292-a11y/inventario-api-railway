const express = require("express");
const mysql = require("mysql2");
const bodyParser = require("body-parser");
const cors = require("cors");
const QRCode = require("qrcode");
const fs = require("fs");
const path = require("path");
const PDFDocument = require("pdfkit");
const ExcelJS = require("exceljs");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const multer = require("multer");

const app = express();
app.use(bodyParser.json());
app.use(cors());

const SECRET = "clave_secreta_inventario";

// 🔥 CONEXIÓN USANDO POOL (Soluciona el error de "Connection is closed")
const conexion = mysql.createPool({
  host: process.env.MYSQLHOST,
  user: process.env.MYSQLUSER,
  password: process.env.MYSQLPASSWORD,
  database: process.env.MYSQLDATABASE,
  port: process.env.MYSQLPORT,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
});

// Probar conexión
conexion.getConnection((err, conn) => {
  if (err) {
    console.error("❌ Error al conectar a la base de datos:", err);
    return;
  }
  console.log("✅ Conectado a MySQL/MariaDB (Railway)");
  conn.release();
  generarTodosLosQR();
});

const CARPETA_QR = path.join(__dirname, "qr");
const CARPETA_UPLOADS = path.join(__dirname, "uploads");

if (!fs.existsSync(CARPETA_QR)) fs.mkdirSync(CARPETA_QR, { recursive: true });
if (!fs.existsSync(CARPETA_UPLOADS)) fs.mkdirSync(CARPETA_UPLOADS, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, CARPETA_UPLOADS),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `material_${Date.now()}${ext}`);
  },
});
const upload = multer({ storage });

function generarQR(materialId, nombre) {
  const ruta = path.join(CARPETA_QR, `${materialId}.png`);
  QRCode.toFile(ruta, materialId.toString(),
    { color: { dark: "#000000", light: "#FFFFFF" }, margin: 2, width: 300 },
    (err) => { if (err) console.error(`❌ Error QR ${materialId}:`, err); }
  );
}

function generarTodosLosQR() {
  conexion.query("SELECT id, nombre FROM materiales", (err, mats) => {
    if (err || mats.length === 0) return;
    mats.forEach((m) => generarQR(m.id, m.nombre));
  });
}

function formatFecha(f) {
  if (!f) return null;
  const d = new Date(f);
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,"0")}-${String(d.getDate()).padStart(2,"0")}`;
}

function buildFiltroQuery(query) {
  const { maestro, fecha_inicio, fecha_fin } = query;
  let sql = `SELECT p.id, m.nombre AS material, u.nombre AS docente,
                    p.fecha_prestamo, p.fecha_devolucion
             FROM prestamos p
             INNER JOIN materiales m ON p.material_id = m.id
             INNER JOIN usuarios u ON p.docente_id = u.id
             WHERE 1=1`;
  const params = [];
  if (maestro && maestro.trim() !== "") { sql += " AND u.nombre LIKE ?"; params.push(`%${maestro.trim()}%`); }
  if (fecha_inicio && fecha_inicio.trim() !== "") { sql += " AND DATE(p.fecha_prestamo) >= ?"; params.push(fecha_inicio); }
  if (fecha_fin && fecha_fin.trim() !== "") { sql += " AND DATE(p.fecha_prestamo) <= ?"; params.push(fecha_fin); }
  sql += " ORDER BY p.id DESC";
  return { sql, params };
}

function buildHistorialQuery(query) {
  const { maestro, material, fecha_inicio, fecha_fin } = query;
  let sql = `SELECT p.id, m.nombre AS material, u.nombre AS docente,
                    p.fecha_prestamo, p.fecha_devolucion
             FROM prestamos p
             INNER JOIN materiales m ON p.material_id = m.id
             INNER JOIN usuarios u ON p.docente_id = u.id
             WHERE 1=1`;
  const params = [];
  if (maestro && maestro.trim() !== "") {
    sql += " AND u.nombre LIKE ?";
    params.push(`%${maestro.trim()}%`);
  }
  if (material && material.trim() !== "") {
    sql += " AND m.nombre LIKE ?";
    params.push(`%${material.trim()}%`);
  }
  if (fecha_inicio && fecha_inicio.trim() !== "") {
    sql += " AND DATE(p.fecha_prestamo) >= ?";
    params.push(fecha_inicio);
  }
  if (fecha_fin && fecha_fin.trim() !== "") {
    sql += " AND DATE(p.fecha_prestamo) <= ?";
    params.push(fecha_fin);
  }
  sql += " ORDER BY p.id DESC";
  return { sql, params };
}

function verificarToken(req, res, next) {
  let token = req.headers["authorization"];
  if (!token) return res.status(401).json({ status: "error", mensaje: "Token requerido" });
  if (token.startsWith("Bearer ")) token = token.slice(7);
  jwt.verify(token, SECRET, (err, decoded) => {
    if (err) return res.status(401).json({ status: "error", mensaje: "Token inválido" });
    req.usuario = decoded;
    next();
  });
}

function soloAdmin(req, res, next) {
  if (req.usuario.rol !== "admin")
    return res.status(403).json({ status: "error", mensaje: "Acceso denegado" });
  next();
}

app.get("/", (req, res) => res.send("Bienvenido a Inventario API"));

app.post("/registro", (req, res) => {
  const { nombre, correo, password, rol } = req.body;
  if (!nombre || !correo || !password) return res.json({ status: "error", mensaje: "Faltan datos" });
  const hashed = bcrypt.hashSync(password, 8);
  conexion.query("INSERT INTO usuarios (nombre, correo, password, rol, activo) VALUES (?, ?, ?, ?, 1)",
    [nombre, correo, hashed, rol || "maestro"], (err) => {
      if (err) return res.json({ status: "error", mensaje: err.message });
      res.json({ status: "ok", mensaje: "Usuario registrado" });
    });
});

app.post("/login", (req, res) => {
  const { correo, password } = req.body;
  conexion.query("SELECT * FROM usuarios WHERE correo = ?", [correo], (err, result) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    if (result.length === 0) return res.json({ status: "error", mensaje: "Usuario no encontrado" });
    const u = result[0];
    if (!bcrypt.compareSync(password, u.password)) return res.json({ status: "error", mensaje: "Contraseña incorrecta" });
    if (u.rol !== "admin" && !u.activo) return res.json({ status: "error", mensaje: "Usuario desactivado" });
    const token = jwt.sign({ id: u.id, rol: u.rol, nombre: u.nombre }, SECRET, { expiresIn: "8h" });
    res.json({ status: "ok", token, id: u.id, rol: u.rol, usuario: u.nombre });
  });
});

app.get("/crear-admin", (req, res) => {
  const hashed = bcrypt.hashSync("admin123", 8);
  conexion.query("DELETE FROM usuarios WHERE correo = 'admin@test.com'", () => {
    conexion.query("INSERT INTO usuarios (nombre, correo, password, rol, activo) VALUES ('Admin', 'admin@test.com', ?, 'admin', 1)",
      [hashed], (e) => {
        if (e) return res.json({ status: "error", mensaje: e.message });
        res.json({ status: "ok", mensaje: "Admin creado: admin@test.com / admin123" });
      });
  });
});

app.get("/crear-maestro", (req, res) => {
  const { nombre, correo, pass } = req.query;
  if (!nombre || !correo || !pass) return res.json({ status: "error", mensaje: "Faltan datos" });
  const hashed = bcrypt.hashSync(pass, 8);
  conexion.query("DELETE FROM usuarios WHERE correo = ?", [correo], () => {
    conexion.query("INSERT INTO usuarios (nombre, correo, password, rol, activo) VALUES (?, ?, ?, 'maestro', 1)",
      [nombre, correo, hashed], (e) => {
        if (e) return res.json({ status: "error", mensaje: e.message });
        res.json({ status: "ok", mensaje: `¡${nombre} creado!` });
      });
  });
});

app.get("/dashboard", verificarToken, (req, res) => {
  const sql = `
    SELECT 
      (SELECT COUNT(*) FROM materiales) AS total_materiales,
      (SELECT COUNT(*) FROM prestamos WHERE fecha_devolucion IS NULL) AS prestados,
      (SELECT COUNT(*) FROM prestamos WHERE fecha_devolucion IS NOT NULL) AS devueltos,
      (SELECT COUNT(*) FROM materiales WHERE estado = 'dañado') AS danados
  `;
  conexion.query(sql, (err, r) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(r[0]);
  });
});

app.get("/materiales", verificarToken, (req, res) => {
  const sql = "SELECT id, nombre, cantidad, estado, categoria, foto FROM materiales ORDER BY nombre";
  conexion.query(sql, (err, result) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(result);
  });
});

app.post("/materiales", verificarToken, upload.single("foto"), (req, res) => {
  const { nombre, cantidad, estado, categoria } = req.body;
  if (!nombre) return res.json({ status: "error", mensaje: "El nombre es obligatorio" });
  const foto = req.file ? `uploads/${req.file.filename}` : null;
  const sql = "INSERT INTO materiales (nombre, cantidad, estado, categoria, foto) VALUES (?, ?, ?, ?, ?)";
  conexion.query(sql, [nombre, cantidad || 1, estado || "bueno", categoria || "General", foto],
    (err, result) => {
      if (err) return res.json({ status: "error", mensaje: err.message });
      generarQR(result.insertId, nombre);
      res.json({ status: "ok", mensaje: "Material registrado con foto y categoría", id: result.insertId });
    });
});

app.put("/materiales/:id", verificarToken, upload.single("foto"), (req, res) => {
  const { nombre, cantidad, estado, categoria } = req.body;
  let sql = "UPDATE materiales SET nombre = ?, cantidad = ?, estado = ?, categoria = ?";
  const params = [nombre, cantidad, estado, categoria];
  if (req.file) {
    sql += ", foto = ?";
    params.push(`uploads/${req.file.filename}`);
  }
  sql += " WHERE id = ?";
  params.push(req.params.id);

  conexion.query(sql, params, (err) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json({ status: "ok", mensaje: "Material actualizado correctamente" });
  });
});

app.delete("/materiales/:id", verificarToken, soloAdmin, (req, res) => {
  const id = req.params.id;
  conexion.query("SELECT foto FROM materiales WHERE id = ?", [id], (err, rows) => {
    if (!err && rows.length > 0 && rows[0].foto) {
      const rutaFoto = path.join(__dirname, rows[0].foto);
      fs.unlink(rutaFoto, () => {});
    }
    conexion.query("DELETE FROM materiales WHERE id = ?", [id], (err2) => {
      if (err2) return res.json({ status: "error", mensaje: err2.message });
      res.json({ status: "ok", mensaje: "Material eliminado correctamente" });
    });
  });
});

app.get("/usuarios", verificarToken, (req, res) => {
  const { rol } = req.query;
  let sql = "SELECT id, nombre, correo, rol, activo FROM usuarios";
  const params = [];
  if (rol) { sql += " WHERE rol = ?"; params.push(rol); }
  sql += " ORDER BY nombre";
  conexion.query(sql, params, (err, r) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(r);
  });
});

app.put("/usuarios/:id/activo", verificarToken, soloAdmin, (req, res) => {
  conexion.query("UPDATE usuarios SET activo = ? WHERE id = ?",
    [req.body.activo, req.params.id], (err) => {
      if (err) return res.json({ status: "error", mensaje: err.message });
      res.json({ status: "ok", mensaje: "Estado actualizado" });
    });
});

app.post("/prestamos", verificarToken, (req, res) => {
  const { material_id, docente_id, fecha_prestamo } = req.body;
  conexion.query("SELECT * FROM permisos WHERE docente_id = ? AND material_id = ? AND puede_prestar = TRUE",
    [docente_id, material_id], (err, perm) => {
      if (err) return res.json({ status: "error", mensaje: err.message });
      if (perm.length === 0)
        return res.json({ status: "fail", mensaje: "Sin permiso para prestar este material." });

      conexion.query("INSERT INTO prestamos (material_id, docente_id, fecha_prestamo) VALUES (?, ?, ?)",
        [material_id, docente_id, fecha_prestamo], (err2) => {
          if (err2) return res.json({ status: "error", mensaje: err2.message });
          res.json({ status: "ok", mensaje: "Préstamo registrado" });
        });
    });
});

app.get("/prestamos", verificarToken, (req, res) => {
  const sql = `SELECT p.id, m.nombre AS material, u.nombre AS docente,
               p.fecha_prestamo, p.fecha_devolucion
               FROM prestamos p
               INNER JOIN materiales m ON p.material_id = m.id
               INNER JOIN usuarios u ON p.docente_id = u.id
               ORDER BY p.id DESC`;
  conexion.query(sql, (err, r) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(r);
  });
});

app.put("/prestamos/devolver/:id", verificarToken, (req, res) => {
  conexion.query("UPDATE prestamos SET fecha_devolucion = NOW() WHERE id = ?",
    [req.params.id], (err) => {
      if (err) return res.json({ status: "error", mensaje: err.message });
      res.json({ status: "ok", mensaje: "Material devuelto" });
    });
});

app.put("/prestamos/devolver/mat/:material_id", verificarToken, (req, res) => {
  conexion.query("UPDATE prestamos SET fecha_devolucion = NOW() WHERE material_id = ? AND fecha_devolucion IS NULL",
    [req.params.material_id], (err, result) => {
      if (err) return res.json({ status: "error", mensaje: err.message });
      if (result.affectedRows === 0)
        return res.json({ status: "fail", mensaje: "No hay préstamos pendientes" });
      res.json({ status: "ok", mensaje: "Entrega registrada" });
    });
});

app.put("/prestamos/:id", verificarToken, (req, res) => {
  conexion.query("UPDATE prestamos SET fecha_devolucion = ? WHERE id = ?",
    [req.body.fecha_devolucion, req.params.id], (err) => {
      if (err) return res.json({ status: "error", mensaje: err.message });
      res.json({ status: "ok", mensaje: "Préstamo actualizado" });
    });
});

app.get("/reportes/total", verificarToken, (req, res) => {
  conexion.query("SELECT COUNT(*) AS total FROM prestamos", (err, r) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(r[0]);
  });
});

app.get("/reportes/pendientes", verificarToken, (req, res) => {
  conexion.query("SELECT COUNT(*) AS pendientes FROM prestamos WHERE fecha_devolucion IS NULL", (err, r) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(r[0]);
  });
});

app.get("/reportes/devueltos", verificarToken, (req, res) => {
  conexion.query("SELECT COUNT(*) AS devueltos FROM prestamos WHERE fecha_devolucion IS NOT NULL", (err, r) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(r[0]);
  });
});

app.get("/reportes/filtrados", verificarToken, (req, res) => {
  const { sql, params } = buildFiltroQuery(req.query);
  conexion.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ status: "error", mensaje: err.message });
    res.json(rows);
  });
});

app.get("/reportes/pdf", verificarToken, (req, res) => {
  const { sql, params } = buildFiltroQuery(req.query);
  conexion.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ status: "error", mensaje: err.message });

    const doc = new PDFDocument({ margin: 40, size: "A4" });
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", "attachment; filename=reporte.pdf");
    doc.pipe(res);

    doc.fontSize(20).fillColor("#1A237E").text("INFRAMEN - Reporte de Préstamos", { align: "center" });
    doc.moveDown(0.4);
    doc.fontSize(10).fillColor("#555").text(`Generado: ${new Date().toLocaleString()}`, { align: "center" });
    doc.moveDown(0.8);
    doc.fontSize(11).fillColor("#000");
    if (req.query.maestro) doc.text(`Docente: ${req.query.maestro}`);
    if (req.query.fecha_inicio) doc.text(`Desde: ${req.query.fecha_inicio}`);
    if (req.query.fecha_fin) doc.text(`Hasta: ${req.query.fecha_fin}`);
    doc.moveDown(0.6);

    let y = doc.y;
    doc.fontSize(11).fillColor("#1A237E");
    doc.text("ID", 40, y, { width: 35, lineBreak: false });
    doc.text("Material", 80, y, { width: 135, lineBreak: false });
    doc.text("Docente", 220, y, { width: 115, lineBreak: false });
    doc.text("Préstamo", 340, y, { width: 95, lineBreak: false });
    doc.text("Devolución", 440, y, { width: 115, lineBreak: false });
    y += 18;
    doc.moveTo(40, y - 4).lineTo(555, y - 4).strokeColor("#1A237E").stroke();
    y += 6;

    doc.fillColor("#000").fontSize(10);
    if (rows.length === 0) {
      doc.text("No hay préstamos con estos filtros.", 40, y);
    } else {
      rows.forEach((r) => {
        if (y > 760) { doc.addPage(); y = 60; }
        doc.text(String(r.id), 40, y, { width: 35, lineBreak: false });
        doc.text(r.material || "-", 80, y, { width: 135, lineBreak: false });
        doc.text(r.docente || "-", 220, y, { width: 115, lineBreak: false });
        doc.text(formatFecha(r.fecha_prestamo) || "-", 340, y, { width: 95, lineBreak: false });
        doc.text(formatFecha(r.fecha_devolucion) || "Pendiente", 440, y, { width: 115, lineBreak: false });
        y += 18;
      });
    }

    doc.moveDown(2);
    doc.fontSize(11).fillColor("#1A237E").text(`Total: ${rows.length}`, { align: "right" });
    doc.end();
  });
});

app.get("/reportes/excel", verificarToken, async (req, res) => {
  const { sql, params } = buildFiltroQuery(req.query);
  conexion.query(sql, params, async (err, rows) => {
    if (err) return res.status(500).json({ status: "error", mensaje: err.message });

    try {
      const workbook = new ExcelJS.Workbook();
      const sheet = workbook.addWorksheet("Préstamos");
      sheet.columns = [
        { header: "ID", key: "id", width: 8 },
        { header: "Material", key: "material", width: 28 },
        { header: "Docente", key: "docente", width: 22 },
        { header: "Fecha Préstamo", key: "fecha_prestamo", width: 16 },
        { header: "Fecha Devolución", key: "fecha_devolucion", width: 18 },
      ];
      const header = sheet.getRow(1);
      header.font = { bold: true, color: { argb: "FFFFFFFF" } };
      header.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF1A237E" } };

      if (rows.length === 0) {
        sheet.addRow({ id: "-", material: "Sin registros", docente: "-", fecha_prestamo: "-", fecha_devolucion: "-" });
      } else {
        rows.forEach((r) => {
          sheet.addRow({
            id: r.id, material: r.material || "-", docente: r.docente || "-",
            fecha_prestamo: formatFecha(r.fecha_prestamo) || "-",
            fecha_devolucion: formatFecha(r.fecha_devolucion) || "Pendiente",
          });
        });
      }

      res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
      res.setHeader("Content-Disposition", "attachment; filename=reporte.xlsx");
      await workbook.xlsx.write(res);
      res.end();
    } catch (e) {
      res.status(500).json({ status: "error", mensaje: e.message });
    }
  });
});

app.get("/historial", verificarToken, (req, res) => {
  const { sql, params } = buildHistorialQuery(req.query);
  conexion.query(sql, params, (err, result) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(result);
  });
});

app.get("/historial/pdf", verificarToken, (req, res) => {
  const { sql, params } = buildHistorialQuery(req.query);
  conexion.query(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ status: "error", mensaje: err.message });

    if (rows.length === 0) {
      return res.status(400).json({ status: "error", mensaje: "No hay préstamos con estos filtros." });
    }

    const doc = new PDFDocument({ margin: 40, size: "A4" });
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", "attachment; filename=historial.pdf");
    doc.pipe(res);

    doc.fontSize(20).fillColor("#1A237E").text("INFRAMEN - Historial de Préstamos", { align: "center" });
    doc.moveDown(0.4);
    doc.fontSize(10).fillColor("#555").text(`Generado: ${new Date().toLocaleString()}`, { align: "center" });
    doc.moveDown(0.8);

    doc.fontSize(11).fillColor("#000");
    if (req.query.maestro) doc.text(`Docente: ${req.query.maestro}`);
    if (req.query.material) doc.text(`Material: ${req.query.material}`);
    if (req.query.fecha_inicio) doc.text(`Desde: ${req.query.fecha_inicio}`);
    if (req.query.fecha_fin) doc.text(`Hasta: ${req.query.fecha_fin}`);
    doc.moveDown(0.6);

    let y = doc.y;
    doc.fontSize(11).fillColor("#1A237E");
    doc.text("ID", 40, y, { width: 35, lineBreak: false });
    doc.text("Material", 80, y, { width: 135, lineBreak: false });
    doc.text("Docente", 220, y, { width: 115, lineBreak: false });
    doc.text("Préstamo", 340, y, { width: 95, lineBreak: false });
    doc.text("Devolución", 440, y, { width: 115, lineBreak: false });
    y += 18;
    doc.moveTo(40, y - 4).lineTo(555, y - 4).strokeColor("#1A237E").stroke();
    y += 6;

    doc.fillColor("#000").fontSize(10);
    rows.forEach((r) => {
      if (y > 760) {
        doc.addPage();
        y = 60;
      }
      doc.text(String(r.id), 40, y, { width: 35, lineBreak: false });
      doc.text(r.material || "-", 80, y, { width: 135, lineBreak: false });
      doc.text(r.docente || "-", 220, y, { width: 115, lineBreak: false });
      doc.text(formatFecha(r.fecha_prestamo) || "-", 340, y, { width: 95, lineBreak: false });
      doc.text(formatFecha(r.fecha_devolucion) || "Pendiente", 440, y, { width: 115, lineBreak: false });
      y += 18;
    });

    doc.moveDown(2);
    doc.fontSize(11).fillColor("#1A237E").text(`Total de registros: ${rows.length}`, { align: "right" });

    doc.end();
  });
});

app.get("/historial/excel", verificarToken, async (req, res) => {
  const { sql, params } = buildHistorialQuery(req.query);
  conexion.query(sql, params, async (err, rows) => {
    if (err) return res.status(500).json({ status: "error", mensaje: err.message });

    if (rows.length === 0) {
      return res.status(400).json({ status: "error", mensaje: "No hay préstamos con estos filtros." });
    }

    try {
      const workbook = new ExcelJS.Workbook();
      workbook.creator = "INFRAMEN";
      workbook.created = new Date();

      const sheet = workbook.addWorksheet("Historial");
      sheet.columns = [
        { header: "ID", key: "id", width: 8 },
        { header: "Material", key: "material", width: 28 },
        { header: "Docente", key: "docente", width: 22 },
        { header: "Fecha Préstamo", key: "fecha_prestamo", width: 16 },
        { header: "Fecha Devolución", key: "fecha_devolucion", width: 18 },
      ];

      const header = sheet.getRow(1);
      header.font = { bold: true, color: { argb: "FFFFFFFF" } };
      header.alignment = { vertical: "middle", horizontal: "center" };
      header.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF1A237E" } };

      rows.forEach((r) => {
        sheet.addRow({
          id: r.id,
          material: r.material || "-",
          docente: r.docente || "-",
          fecha_prestamo: formatFecha(r.fecha_prestamo) || "-",
          fecha_devolucion: formatFecha(r.fecha_devolucion) || "Pendiente",
        });
      });

      res.setHeader(
        "Content-Type",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      );
      res.setHeader("Content-Disposition", "attachment; filename=historial.xlsx");
      await workbook.xlsx.write(res);
      res.end();
    } catch (e) {
      console.error(e);
      res.status(500).json({ status: "error", mensaje: e.message });
    }
  });
});

app.get("/notificaciones/:docente_id", verificarToken, (req, res) => {
  const sql = `SELECT p.id, m.nombre AS material, p.fecha_prestamo
               FROM prestamos p
               INNER JOIN materiales m ON p.material_id = m.id
               WHERE p.docente_id = ? AND p.fecha_devolucion IS NULL`;
  conexion.query(sql, [req.params.docente_id], (err, r) => {
    if (err) return res.json({ status: "error", mensaje: err.message });
    res.json(r);
  });
});

app.post("/permisos", verificarToken, soloAdmin, (req, res) => {
  const { docente_id, material_id, puede_ver, puede_prestar, puede_devolver } = req.body;
  conexion.query(
    "INSERT INTO permisos (docente_id, material_id, puede_ver, puede_prestar, puede_devolver) VALUES (?, ?, ?, ?, ?)",
    [docente_id, material_id, puede_ver, puede_prestar, puede_devolver],
    (err) => {
      if (err) return res.json({ status: "error", mensaje: err.message });
      res.json({ status: "ok", mensaje: "Permiso asignado" });
    });
});

app.use("/qr", express.static(CARPETA_QR));
app.use("/uploads", express.static(CARPETA_UPLOADS));

app.get("/generar-qr", (req, res) => { generarTodosLosQR(); res.json({ status: "ok" }); });

// 🔥 Puerto dinámico para Railway
const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Servidor corriendo en el puerto ${PORT}`);
});