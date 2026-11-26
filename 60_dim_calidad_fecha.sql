-- ============================================================================
-- OT Consulting - consultas sobre DIM_CALIDAD_FECHA (que tan confiable es la fecha)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: DQ_calidad_de_fechas
-- dimension: DIM_CALIDAD_FECHA
-- pregunta: Que tan confiables son las fechas de las asignaciones?
SELECT q.fuente_fecha_inicio, q.fuente_fecha_fin, q.fecha_inicio_desconocida, q.fin_indefinido, q.ajustada_r08,
       COUNT(*) AS asignaciones
FROM HECHOS_ASIGNACION h
JOIN DIM_CALIDAD_FECHA q ON q.id_calidad_fecha = h.id_calidad_fecha
GROUP BY q.fuente_fecha_inicio, q.fuente_fecha_fin, q.fecha_inicio_desconocida, q.fin_indefinido, q.ajustada_r08
ORDER BY asignaciones DESC;

-- name: DQ_resumen_fechas
-- dimension: DIM_CALIDAD_FECHA
-- pregunta: Cuantas asignaciones tienen inicio desconocido, fin indefinido o fechas ajustadas por R08?
SELECT SUM(CASE WHEN q.fecha_inicio_desconocida = 'SI' THEN 1 ELSE 0 END) AS inicio_desconocido,
       SUM(CASE WHEN q.fin_indefinido = 'SI' THEN 1 ELSE 0 END)           AS fin_indefinido,
       SUM(CASE WHEN q.ajustada_r08 = 'SI' THEN 1 ELSE 0 END)             AS ajustadas_r08,
       COUNT(*)                                                           AS asignaciones
FROM HECHOS_ASIGNACION h
JOIN DIM_CALIDAD_FECHA q ON q.id_calidad_fecha = h.id_calidad_fecha;
