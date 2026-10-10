const bcrypt = require("bcryptjs");
const mysql = require("mysql2");

const conexion = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "2007",
  database: "inventario_db",
});

conexion.connect((err) => {
  if (err) {
    console.error("❌ Error:", err);
    return;
  }
  console.log("✅ Conectado a MariaDB");

  // Borrar todos los usuarios anteriores
  conexion.query("DELETE FROM usuarios", (errDel) => {
    if (errDel) {
      console.error("❌ Error al borrar:", errDel);
      conexion.end();
      return;
    }
    console.log("🧹 Usuarios anteriores eliminados");

    // Generar hashes FRESCOS
    const hashAdmin = bcrypt.hashSync("admin123", 8);
    const hashJuan = bcrypt.hashSync("juan123", 8);

    console.log("🔑 Hash admin:", hashAdmin);
    console.log("🔑 Hash juan :", hashJuan);

    // Insertar los nuevos usuarios
    const sql = "INSERT INTO usuarios (nombre, correo, password, rol) VALUES ?";
    const valores = [
      ["Administrador", "admin@test.com", hashAdmin, "admin"],
      ["Maestro Juan", "juan@test.com", hashJuan, "maestro"],
    ];

    conexion.query(sql, [valores], (errIns) => {
      if (errIns) {
        console.error("❌ Error al insertar:", errIns);
      } else {
        console.log("🎉 Usuarios creados correctamente");
        console.log("   → admin@test.com / admin123");
        console.log("   → juan@test.com / juan123");
      }
      conexion.end();
    });
  });
});