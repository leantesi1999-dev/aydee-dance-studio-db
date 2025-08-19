# Aydee Dance Studio DB 🩰📊

Modelo relacional completo, datos de muestra y entorno Docker list-and-go para gestionar clases, horarios, matrículas y pagos de un estudio de danzas.

![MySQL 8](https://img.shields.io/badge/MySQL-8.0-informational?logo=mysql)
![Docker Compose](https://img.shields.io/badge/Docker%20Compose-yes-blue?logo=docker)

## 1 · Descripción

## Contexto

Este proyecto surge de la necesidad de **organizar académica y administrativamente** un estudio de danzas con múltiples **disciplinas**, dadas en distintas **salas**, **horarios** y **niveles**, con varios **docentes** y **planes de matrícula/pagos** (1×, 2× por semana y combo de 2 disciplinas).  
La base de datos permite registrar y relacionar todos estos elementos para:

- **Operación diaria:** altas de alumnas, matrículas por disciplina, armado de grilla semanal, generación automática de sesiones, control de asistencias y registro de pagos.
- **Gestión y estrategia:** seguimiento de ocupación de salas y cupos, rentabilidad por clase, distribución de cargas docentes, evaluación de demanda por franjas horarias, y apoyo para decisiones de precios y promoción.
- **Análisis y optimización:** elaboración de KPIs y reportes (MRR/ingresos mensuales, margen por sesión = ingresos − costo de sala, retención/churn de alumnas, tasa de asistencia, ticket promedio por plan, etc.), orientados a mejorar **eficiencia** y **uso de recursos**.

### Qué resuelve
- Estructura relacional con **integridad referencial** (FKs) para evitar inconsistencias.
- Modelo flexible: una misma clase puede tener **varios horarios** con **docentes** y **salas** diferentes.
- **Procedimiento** para generar sesiones por rango de fechas a partir de la grilla.
- Datos de ejemplo y **Docker Compose** (MySQL + Adminer) para levantar el entorno en 1 comando.

### KPIs sugeridos
- **Ocupación de salas** por día/franja.
- **Asistencias** efectivas vs. programadas por disciplina.
- **Ingresos** por clase/plan/periodo y **margen** por sesión.
- **Retención** y **churn** mensual de alumnas.
- **ARPU** (ingreso promedio por alumna) y mezcla de **planes**.

> Con esta base se puede llevar el **seguimiento administrativo**, definir **estrategias de crecimiento** y realizar **análisis** que ayuden a evaluar la eficiencia y optimizar recursos del estudio.
  
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
