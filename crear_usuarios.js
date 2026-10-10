const bcrypt = require("bcryptjs");
const mysql = require("mysql2");

const conexion = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "2007",
  database: "inventario_db",
});

const usuarios = [
  {
    nombre: "Administrador",
    correo: "admin@test.com",
    password: "admin123",
    rol: "admin",
  },
  {
    nombre: "Maestro Juan",
    correo: "juan@test.com",
    password: "juan123",
    rol: "maestro",
  },
];

conexion.connect((err) => {
  if (err) {
    console.error("❌ Error al conectar a la base de datos:", err);
    return;
  }

  console.log("✅ Conectado a MariaDB");

  // 🧹 Limpiamos los correos para evitar errores de duplicados
  const correos = usuarios.map((u) => u.correo);
  conexion.query(
    "DELETE FROM usuarios WHERE correo IN (?, ?)",
    correos,
    (errDelete) => {
      if (errDelete) console.error("❌ Error al limpiar usuarios:", errDelete);

      // 🔁 Insertamos los nuevos usuarios
      usuarios.forEach((u) => {
        const hash = bcrypt.hashSync(u.password, 8);
        const sql =
          "INSERT INTO usuarios (nombre, correo, password, rol) VALUES (?, ?, ?, ?)";

        conexion.query(sql, [u.nombre, u.correo, hash, u.rol], (err2) => {
          if (err2) {
            console.error(`❌ Error al crear ${u.correo}:`, err2.message);
          } else {
            console.log(`✅ Creado: ${u.correo} / ${u.password}  (rol: ${u.rol})`);
          }
        });
      });

      setTimeout(() => {
        conexion.end();
        console.log("\n🎉 Listo. Ya puedes iniciar sesión en la app.");
        console.log("📱 Credenciales de prueba:");
        console.log("   Admin   → admin@test.com / admin123");
        console.log("   Maestro → juan@test.com / juan123");
      }, 2000);
    }
  );
});