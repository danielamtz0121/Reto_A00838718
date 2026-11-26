-- ============================================================================
-- OT Consulting - consultas sobre DIM_FECHA (cuando; 4 roles: inicio/fin efectivo, inicio/fin registrado)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: FECHA_rango_calendario
-- dimension: DIM_FECHA
-- pregunta: Que rango de fechas cubre la dimension de tiempo? (excluye el miembro DESCONOCIDA)
SELECT MIN(fecha) AS fecha_mas_antigua, MAX(fecha) AS fecha_mas_reciente, COUNT(*) AS dias
FROM DIM_FECHA
WHERE id_fecha > 0;

-- name: FECHA_rango_por_rol
-- dimension: DIM_FECHA
-- pregunta: Que rango de fechas se usa realmente en cada rol de la tabla de hechos?
SELECT 'inicio efectivo' AS rol, MIN(f.fecha) AS mas_antigua, MAX(f.fecha) AS mas_reciente, COUNT(*) AS con_dato
FROM HECHOS_ASIGNACION h JOIN DIM_FECHA f ON f.id_fecha = h.id_fecha_inicio_efectiva WHERE h.id_fecha_inicio_efectiva > 0
UNION ALL
SELECT 'fin efectivo', MIN(f.fecha), MAX(f.fecha), COUNT(*)
FROM HECHOS_ASIGNACION h JOIN DIM_FECHA f ON f.id_fecha = h.id_fecha_fin_efectiva WHERE h.id_fecha_fin_efectiva > 0
UNION ALL
SELECT 'inicio registrado', MIN(f.fecha), MAX(f.fecha), COUNT(*)
FROM HECHOS_ASIGNACION h JOIN DIM_FECHA f ON f.id_fecha = h.id_fecha_inicio_registrada WHERE h.id_fecha_inicio_registrada > 0
UNION ALL
SELECT 'fin registrado', MIN(f.fecha), MAX(f.fecha), COUNT(*)
FROM HECHOS_ASIGNACION h JOIN DIM_FECHA f ON f.id_fecha = h.id_fecha_fin_registrada WHERE h.id_fecha_fin_registrada > 0
UNION ALL
SELECT 'inicio asignacion de equipo', MIN(f.fecha), MAX(f.fecha), COUNT(*)
FROM HECHOS_EQUIPO h JOIN DIM_FECHA f ON f.id_fecha = h.id_fecha_inicio_asignacion WHERE h.id_fecha_inicio_asignacion > 0
UNION ALL
SELECT 'fin asignacion de equipo', MIN(f.fecha), MAX(f.fecha), COUNT(*)
FROM HECHOS_EQUIPO h JOIN DIM_FECHA f ON f.id_fecha = h.id_fecha_fin_asignacion WHERE h.id_fecha_fin_asignacion > 0;

-- name: P2_vencimientos_por_mes
-- dimension: DIM_FECHA
-- pregunta: P2. En que meses terminan las asignaciones y cuanto costo mensual se libera?
SELECT f.anio, f.mes, f.nombre_mes,
       COUNT(*)                                AS asignaciones_que_terminan,
       COUNT(DISTINCT h.id_colaborador)        AS personas,
       ROUND(SUM(h.costo_mensual_asignado), 0) AS costo_mensual_que_se_libera
FROM HECHOS_ASIGNACION h
JOIN DIM_FECHA f ON f.id_fecha = h.id_fecha_fin_efectiva
WHERE h.id_fecha_fin_efectiva > 0
GROUP BY f.anio, f.mes, f.nombre_mes
ORDER BY f.anio, f.mes;

-- name: P2_inicios_por_trimestre
-- dimension: DIM_FECHA
-- pregunta: P2 (contexto). Cuando arrancaron las asignaciones con fecha de inicio conocida?
SELECT f.anio, f.trimestre, COUNT(*) AS asignaciones_que_inician
FROM HECHOS_ASIGNACION h
JOIN DIM_FECHA f ON f.id_fecha = h.id_fecha_inicio_efectiva
WHERE h.id_fecha_inicio_efectiva > 0
GROUP BY f.anio, f.trimestre
ORDER BY f.anio, f.trimestre;
