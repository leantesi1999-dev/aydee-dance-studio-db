# Aydee Dance Studio DB 🩰📊

Modelo relacional completo, datos de muestra y entorno Docker list-and-go para gestionar clases, horarios, matrículas y pagos de un estudio de danzas.

![MySQL 8](https://img.shields.io/badge/MySQL-8.0-informational?logo=mysql)
![Docker Compose](https://img.shields.io/badge/Docker%20Compose-yes-blue?logo=docker)

## 1 · Descripción

Este proyecto surge de la necesidad de **organizar académica y administrativamente** un estudio con varias disciplinas, múltiples docentes y distintos planes de matrícula (1×, 2× y combo de 2 disciplinas).  
Incluye:

* **Esquema relacional** con integridad referencial completa  
* Sesiones generadas automáticamente vía _stored procedure_  
* Datos de ejemplo para pruebas rápidas  
* Stack Docker (MySQL 8 + Adminer) listo para levantar en un comando

<p align="center">
  <img src="docs/er_diagram_Aydee.png" width="600" alt="ER diagram">
</p>

## 2 · Levantar en local

```bash
git clone https://github.com/<tu_usuario>/aydee-dance-studio-db.git
cd aydee-dance-studio-db
docker compose up -d
