/* ---------------------------------------------------------------
   0) CREACIÓN DE ESQUEMA
----------------------------------------------------------------*/
CREATE DATABASE IF NOT EXISTS aydee
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE aydee;

/* ---------------------------------------------------------------
   1) TABLAS DE REFERENCIA BÁSICAS
----------------------------------------------------------------*/
CREATE TABLE salas (
  sala_id           INT AUTO_INCREMENT PRIMARY KEY,
  nombre_sala       VARCHAR(40) NOT NULL,
  capacidad_adultos SMALLINT UNSIGNED NOT NULL,
  capacidad_ninos   SMALLINT UNSIGNED NOT NULL,
  costo_hora        DECIMAL(12,2) NOT NULL,
  equipamiento      VARCHAR(255),
  UNIQUE KEY u_nombre_sala (nombre_sala)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE profes (
  profe_id                 INT AUTO_INCREMENT PRIMARY KEY,
  nombre                   VARCHAR(80) NOT NULL,
  apellido                 VARCHAR(80) NOT NULL,
  cel                      VARCHAR(40),
  direccion_barrio         VARCHAR(120),
  modalidad_contratacion   ENUM('porcentaje','monto_fijo','propietaria') NOT NULL DEFAULT 'porcentaje',
  porcentaje_participacion DECIMAL(5,2),
  KEY idx_prof_apell_nom (apellido, nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/* ---------------------------------------------------------------
   2) ESTRUCTURA ACADÉMICA (docente asignado por horario)
----------------------------------------------------------------*/
CREATE TABLE clases (
  clase_id           INT AUTO_INCREMENT PRIMARY KEY,
  nombre_clase       VARCHAR(120) NOT NULL,
  nivel              ENUM('Inicial','Intermedio','Avanzado') NULL,
  sala_preferente_id INT,                   -- opcional (p. ej. la más habitual)
  duracion_minutos   SMALLINT UNSIGNED NOT NULL,
  precio_mensual_1x  DECIMAL(12,2) NOT NULL,
  precio_mensual_2x  DECIMAL(12,2) NOT NULL,
  observaciones      VARCHAR(255),
  CONSTRAINT fk_clases_sala_pref FOREIGN KEY (sala_preferente_id)
      REFERENCES salas(sala_id)
      ON UPDATE CASCADE ON DELETE SET NULL,
  UNIQUE KEY u_nombre_nivel (nombre_clase, nivel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE clases_horarios (
  clase_horario_id INT AUTO_INCREMENT PRIMARY KEY,
  clase_id         INT NOT NULL,
  profe_id         INT NOT NULL,
  dia_semana       ENUM('Lun','Mar','Mie','Jue','Vie','Sab','Dom') NOT NULL,
  hora_inicio      TIME NOT NULL,
  hora_fin         TIME NOT NULL,
  sala_id          INT NOT NULL,
  CONSTRAINT fk_ch_clase FOREIGN KEY (clase_id)
      REFERENCES clases(clase_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ch_profe FOREIGN KEY (profe_id)
      REFERENCES profes(profe_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ch_sala FOREIGN KEY (sala_id)
      REFERENCES salas(sala_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY u_horario (clase_id, dia_semana, hora_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/* ---------------------------------------------------------------
   3) ALUMNAS, MATRÍCULAS Y PAGOS
----------------------------------------------------------------*/
CREATE TABLE alumnas (
  alumna_id        INT AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(80) NOT NULL,
  apellido         VARCHAR(80) NOT NULL,
  dni              VARCHAR(20) UNIQUE,
  email            VARCHAR(120),
  celular          VARCHAR(40),
  direccion_barrio VARCHAR(120),
  fecha_alta       DATE NOT NULL DEFAULT (CURRENT_DATE),
  estado           ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  KEY idx_alumna_apell_nom (apellido, nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE matriculas (
  matricula_id INT AUTO_INCREMENT PRIMARY KEY,
  alumna_id    INT NOT NULL,
  clase_id     INT NOT NULL,
  fecha_inicio DATE NOT NULL DEFAULT (CURRENT_DATE),
  fecha_fin    DATE,
  plan         ENUM('1x/semana','2x/semana','combo_2_disciplinas') NOT NULL,
  estado       ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  CONSTRAINT fk_mat_alumna FOREIGN KEY (alumna_id)
      REFERENCES alumnas(alumna_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_mat_clase FOREIGN KEY (clase_id)
      REFERENCES clases(clase_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE KEY u_matricula_activa (alumna_id, clase_id, estado),
  CONSTRAINT chk_mat_rango_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE pagos (
  pago_id      INT AUTO_INCREMENT PRIMARY KEY,
  matricula_id INT NOT NULL,
  fecha_pago   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  periodo      CHAR(7) NOT NULL, -- YYYY-MM
  monto        DECIMAL(12,2) NOT NULL,
  metodo_pago  ENUM('efectivo','transferencia','debito','credito') NOT NULL,
  observaciones VARCHAR(255),
  CONSTRAINT fk_pagos_matricula FOREIGN KEY (matricula_id)
      REFERENCES matriculas(matricula_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT u_pago UNIQUE (matricula_id, periodo),
  CONSTRAINT chk_monto_pos CHECK (monto > 0),
  CONSTRAINT chk_periodo_yyyy_mm CHECK (REGEXP_LIKE(periodo, '^[0-9]{4}-[0-9]{2}$')),
  KEY idx_pagos_periodo (periodo),
  KEY idx_pagos_mat_periodo (matricula_id, periodo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/* ---------------------------------------------------------------
   4) SESIONES Y ASISTENCIAS
----------------------------------------------------------------*/
CREATE TABLE sesiones (
  sesion_id        INT AUTO_INCREMENT PRIMARY KEY,
  clase_horario_id INT NOT NULL,
  fecha            DATE NOT NULL,
  sala_id          INT NOT NULL,
  costo_sala       DECIMAL(12,2) NOT NULL,
  capacidad        SMALLINT UNSIGNED NOT NULL,
  estado           ENUM('programada','dictada','cancelada','reprogramada') NOT NULL DEFAULT 'programada',
  observaciones    VARCHAR(255),
  CONSTRAINT fk_ses_ch FOREIGN KEY (clase_horario_id)
      REFERENCES clases_horarios(clase_horario_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ses_sala FOREIGN KEY (sala_id)
      REFERENCES salas(sala_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY u_sesion (clase_horario_id, fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE asistencias (
  asistencia_id INT AUTO_INCREMENT PRIMARY KEY,
  sesion_id     INT NOT NULL,
  alumna_id     INT NOT NULL,
  estado        ENUM('asistio','falto','justificada') NOT NULL,
  reposicion    TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_as_sesion FOREIGN KEY (sesion_id)
      REFERENCES sesiones(sesion_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_as_alumna FOREIGN KEY (alumna_id)
      REFERENCES alumnas(alumna_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE KEY u_asistencia (sesion_id, alumna_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/* ---------------------------------------------------------------
   4.b) ÍNDICES ADICIONALES PARA CONSULTAS COMUNES
----------------------------------------------------------------*/
CREATE INDEX idx_ch_dia_sala_inicio ON clases_horarios (dia_semana, sala_id, hora_inicio);
CREATE INDEX idx_as_alumna ON asistencias (alumna_id);
CREATE INDEX idx_ses_fecha ON sesiones (fecha);

/* ---------------------------------------------------------------
   4.c) TRIGGERS: EVITAR SOLAPES DE SALA Y PROFESOR/A
----------------------------------------------------------------*/
DELIMITER //
CREATE TRIGGER trg_ch_no_overlap_sala
BEFORE INSERT ON clases_horarios
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM clases_horarios x
    WHERE x.sala_id = NEW.sala_id
      AND x.dia_semana = NEW.dia_semana
      AND NOT (NEW.hora_fin <= x.hora_inicio OR NEW.hora_inicio >= x.hora_fin)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Conflicto: la sala ya está ocupada en ese horario';
  END IF;
END//
CREATE TRIGGER trg_ch_no_overlap_profe
BEFORE INSERT ON clases_horarios
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM clases_horarios x
    WHERE x.profe_id = NEW.profe_id
      AND x.dia_semana = NEW.dia_semana
      AND NOT (NEW.hora_fin <= x.hora_inicio OR NEW.hora_inicio >= x.hora_fin)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Conflicto: el/la profe ya tiene clase en ese horario';
  END IF;
END//
DELIMITER ;

/* ---------------------------------------------------------------
   5) PROCEDIMIENTO PARA GENERAR SESIONES
----------------------------------------------------------------*/
DELIMITER //
CREATE PROCEDURE sp_generar_sesiones(IN p_desde DATE, IN p_hasta DATE)
BEGIN
  DECLARE v_dia DATE;
  SET v_dia = p_desde;
  WHILE v_dia <= p_hasta DO
    INSERT IGNORE INTO sesiones (clase_horario_id, fecha, sala_id, costo_sala, capacidad)
    SELECT ch.clase_horario_id, v_dia, ch.sala_id, s.costo_hora, s.capacidad_adultos
    FROM clases_horarios ch
    JOIN salas s ON s.sala_id = ch.sala_id
    WHERE ch.dia_semana = ELT(DAYOFWEEK(v_dia),'Dom','Lun','Mar','Mie','Jue','Vie','Sab');
    SET v_dia = v_dia + INTERVAL 1 DAY;
  END WHILE;
END //
DELIMITER ;

/* ---------------------------------------------------------------
   6) VISTA KPI DE OCUPACIÓN
----------------------------------------------------------------*/
CREATE OR REPLACE VIEW v_ocupacion AS
SELECT s.sesion_id,
       s.fecha,
       ch.dia_semana,
       c.nombre_clase,
       COUNT(a.alumna_id) AS asistentes,
       s.capacidad,
       ROUND(100.0 * COUNT(a.alumna_id) / NULLIF(s.capacidad,0), 1) AS ocupacion_pct
FROM sesiones s
JOIN clases_horarios ch USING (clase_horario_id)
JOIN clases c ON c.clase_id = ch.clase_id
LEFT JOIN asistencias a
  ON a.sesion_id = s.sesion_id AND a.estado = 'asistio'
GROUP BY s.sesion_id, s.fecha, ch.dia_semana, c.nombre_clase, s.capacidad;

/* ---------------------------------------------------------------
   7) DATOS DE EJEMPLO
   (copia y ejecuta a partir de aquí)
----------------------------------------------------------------*/

/* ---- Salas ---------------------------------------------------*/
INSERT INTO salas (nombre_sala, capacidad_adultos, capacidad_ninos,
                   costo_hora, equipamiento)
VALUES
  ('chica',   8, 10, 13500.00, '1 espejo; 1 equipo de música'),
  ('mediana',16, 16, 16000.00, '3 espejos; 3 barras; 1 equipo de música'),
  ('grande', 25, 25, 18500.00, '5 espejos; 1 equipo de música');

/* ---- Profesoras ---------------------------------------------*/
INSERT INTO profes (nombre, apellido, modalidad_contratacion, porcentaje_participacion)
VALUES
  ('Marisol','Soler',    'propietaria', NULL),
  ('Rocio',  'Montero',  'porcentaje', 30.00),
  ('Evelyn', 'Leguizamon','porcentaje',30.00);

/* ---- Clases (sin docente; docente se asigna por horario) -----*/
INSERT INTO clases (nombre_clase, nivel, sala_preferente_id,
                    duracion_minutos, precio_mensual_1x, precio_mensual_2x, observaciones)
VALUES
  ('Danza Jazz niños',             'Inicial',
     (SELECT sala_id FROM salas WHERE nombre_sala='chica'),
     60, 38000, 0,'Niñas/os 6-10 años'),
  ('Danza Jazz desde cero - Adultos','Inicial',
     (SELECT sala_id FROM salas WHERE nombre_sala='grande'),     -- preferente
     60, 40000, 50000,'Adultos sin experiencia'),
  ('Danza Jazz intermedio',        'Intermedio',
     (SELECT sala_id FROM salas WHERE nombre_sala='mediana'),
     90, 42000, 0,'Requiere base previa'),
  ('Clásico niños',                'Inicial',
     (SELECT sala_id FROM salas WHERE nombre_sala='chica'),
     60, 38000, 0,'Niñas/os 6-10 años'),
  ('Danza clásica intermedio',     'Intermedio',
     (SELECT sala_id FROM salas WHERE nombre_sala='mediana'),
     60, 40000, 0,'Para base clásica'),
  ('Bachata',                      'Inicial',
     (SELECT sala_id FROM salas WHERE nombre_sala='chica'),
     60, 35000, 0,'Baile social – parejas no excluyente');

/* ---- Horarios con docente y sala específica -----------------*/
-- Lunes 20 h • Danza Jazz desde cero – Prof. Marisol • sala grande
INSERT INTO clases_horarios (clase_id, profe_id, dia_semana,
                             hora_inicio, hora_fin, sala_id)
SELECT  c.clase_id,
        p.profe_id,
        'Lun','20:00:00','21:00:00',
        s.sala_id
FROM clases c, profes p, salas s
WHERE c.nombre_clase='Danza Jazz desde cero - Adultos'
  AND p.apellido='Soler'
  AND s.nombre_sala='grande';

-- Jueves 20 h • Danza Jazz desde cero – Prof. Evelyn • sala mediana
INSERT INTO clases_horarios (clase_id, profe_id, dia_semana,
                             hora_inicio, hora_fin, sala_id)
SELECT  c.clase_id,
        p.profe_id,
        'Jue','20:00:00','21:00:00',
        s.sala_id
FROM clases c, profes p, salas s
WHERE c.nombre_clase='Danza Jazz desde cero - Adultos'
  AND p.apellido='Leguizamon'
  AND s.nombre_sala='mediana';

-- Lunes 18 h 30 • Danza Jazz niños – Prof. Rocio • sala chica
INSERT INTO clases_horarios (clase_id, profe_id, dia_semana,
                             hora_inicio, hora_fin, sala_id)
SELECT  c.clase_id,
        p.profe_id,
        'Lun','18:30:00','19:30:00',
        s.sala_id
FROM clases c, profes p, salas s
WHERE c.nombre_clase='Danza Jazz niños'
  AND p.apellido='Montero'
  AND s.nombre_sala='chica';

-- Jueves 18 h 30 • Danza Jazz intermedio – Prof. Rocio • sala mediana
INSERT INTO clases_horarios (clase_id, profe_id, dia_semana,
                             hora_inicio, hora_fin, sala_id)
SELECT  c.clase_id,
        p.profe_id,
        'Jue','18:30:00','20:00:00',
        s.sala_id
FROM clases c, profes p, salas s
WHERE c.nombre_clase='Danza Jazz intermedio'
  AND p.apellido='Montero'
  AND s.nombre_sala='mediana';

-- Martes 18 h 30 • Clásico niños – Prof. Marisol • sala chica
INSERT INTO clases_horarios (clase_id, profe_id, dia_semana,
                             hora_inicio, hora_fin, sala_id)
SELECT  c.clase_id,
        p.profe_id,
        'Mar','18:30:00','19:30:00',
        s.sala_id
FROM clases c, profes p, salas s
WHERE c.nombre_clase='Clásico niños'
  AND p.apellido='Soler'
  AND s.nombre_sala='chica';

-- Viernes 18 h 30 • Danza clásica intermedio – Prof. Marisol • sala mediana
INSERT INTO clases_horarios (clase_id, profe_id, dia_semana,
                             hora_inicio, hora_fin, sala_id)
SELECT  c.clase_id,
        p.profe_id,
        'Vie','18:30:00','19:30:00',
        s.sala_id
FROM clases c, profes p, salas s
WHERE c.nombre_clase='Danza clásica intermedio'
  AND p.apellido='Soler'
  AND s.nombre_sala='mediana';

-- Martes 20 h • Bachata – Prof. Rocio • sala chica
INSERT INTO clases_horarios (clase_id, profe_id, dia_semana,
                             hora_inicio, hora_fin, sala_id)
SELECT  c.clase_id,
        p.profe_id,
        'Mar','20:00:00','21:00:00',
        s.sala_id
FROM clases c, profes p, salas s
WHERE c.nombre_clase='Bachata'
  AND p.apellido='Montero'
  AND s.nombre_sala='chica';

/* ---- Alumnas de prueba --------------------------------------*/
INSERT INTO alumnas (nombre, apellido, dni, email)
VALUES
  ('Ana',   'Pérez',     '11111111', 'ana@example.com'),
  ('Carla', 'Gómez',     '22222222', 'carla@example.com'),
  ('Lucía', 'Martínez',  '33333333', 'lucia@example.com');

/* ---- Matrículas de prueba -----------------------------------*/
-- Ana: Danza Jazz niños (1×/semana)
INSERT INTO matriculas (alumna_id, clase_id, plan)
SELECT a.alumna_id, c.clase_id, '1x/semana'
FROM alumnas a, clases c
WHERE a.apellido='Pérez'
  AND c.nombre_clase='Danza Jazz niños';

-- Carla: Clásico niños (2×/semana)  
INSERT INTO matriculas (alumna_id, clase_id, plan)
SELECT a.alumna_id, c.clase_id, '2x/semana'
FROM alumnas a, clases c
WHERE a.apellido='Gómez'
  AND c.nombre_clase='Clásico niños';

-- Lucía: Bachata (1×/semana)
INSERT INTO matriculas (alumna_id, clase_id, plan)
SELECT a.alumna_id, c.clase_id, '1x/semana'
FROM alumnas a, clases c
WHERE a.apellido='Martínez'
  AND c.nombre_clase='Bachata';

/* ---- Generar sesiones de septiembre-2025 --------------------*/
CALL sp_generar_sesiones('2025-09-01','2025-09-30');
