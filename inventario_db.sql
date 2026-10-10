CREATE DATABASE inventario_db;
USE inventario_db;

CREATE TABLE materiales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    cantidad INT NOT NULL,
    estado VARCHAR(20) NOT NULL
);