-- ============================================================================
-- OT Consulting - consultas sobre DIM_ESTADO_ASIGNACION (en que situacion esta)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: P2_asignaciones_por_estado
-- dimension: DIM_ESTADO_ASIGNACION
-- pregunta: P2. Como se reparten las asignaciones segun su vigencia?
SELECT e.estado_vigencia, e.tipo_asignacion, e.persona_libre_al_vencer,
       COUNT(*)                                AS asignaciones,
       COUNT(DISTINCT h.id_colaborador)        AS personas,
       ROUND(SUM(h.costo_mensual_asignado), 0) AS costo_mensual
FROM HECHOS_ASIGNACION h
JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
GROUP BY e.estado_vigencia, e.tipo_asignacion, e.persona_libre_al_vencer
ORDER BY e.estado_vigencia, e.tipo_asignacion;

-- name: P2_vencen_30_60_90
-- dimension: DIM_ESTADO_ASIGNACION
-- pregunta: P2. Que asignaciones terminan en los proximos 30, 60 y 90 dias?
SELECT SUM(CASE WHEN h.dias_para_fin < 0 THEN 1 ELSE 0 END)                  AS vencidas,
       SUM(CASE WHEN h.dias_para_fin BETWEEN 0  AND 30 THEN 1 ELSE 0 END)    AS vencen_0_30,
       SUM(CASE WHEN h.dias_para_fin BETWEEN 31 AND 60 THEN 1 ELSE 0 END)    AS vencen_31_60,
       SUM(CASE WHEN h.dias_para_fin BETWEEN 61 AND 90 THEN 1 ELSE 0 END)    AS vencen_61_90,
       SUM(CASE WHEN h.dias_para_fin > 90 THEN 1 ELSE 0 END)                 AS mas_de_90,
       SUM(CASE WHEN h.dias_para_fin IS NULL THEN 1 ELSE 0 END)              AS sin_fecha_fin
FROM HECHOS_ASIGNACION h;

-- name: P2_personas_libres
-- dimension: DIM_ESTADO_ASIGNACION
-- pregunta: P2. Quien queda libre cuando termina su asignacion (vencida o por vencer en <= 90 dias)?
SELECT h.id_asignacion, c.nombre_colaborador, p.cliente, p.proyecto, e.estado_vigencia,
       h.dias_para_fin, ROUND(h.costo_mensual_persona, 0) AS costo_mensual_liberado
FROM HECHOS_ASIGNACION h
JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
JOIN DIM_COLABORADOR c       ON c.id_colaborador = h.id_colaborador
JOIN DIM_PROYECTO p          ON p.id_proyecto = h.id_proyecto
WHERE e.persona_libre_al_vencer = 'SI' AND h.dias_para_fin <= 90
ORDER BY h.dias_para_fin;
