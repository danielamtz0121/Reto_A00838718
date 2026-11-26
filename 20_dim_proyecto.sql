-- ============================================================================
-- OT Consulting - consultas sobre DIM_PROYECTO (para quien y en que)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: P3_proyectos_en_curso
-- dimension: DIM_PROYECTO
-- pregunta: P3. Que proyectos en curso no tienen personal o ya vencieron?
SELECT p.id_proyecto, p.cliente, p.proyecto, p.estatus_proyecto, p.fecha_fin,
       COUNT(h.id_asignacion)                                           AS personas_asignadas,
       CASE WHEN COUNT(h.id_asignacion) = 0 THEN 1 ELSE 0 END           AS sin_personal,
       CASE WHEN p.fecha_fin IS NOT NULL
             AND p.fecha_fin < CAST((SELECT valor FROM PARAMETROS WHERE clave = 'fecha_corte') AS DATE)
            THEN 1 ELSE 0 END                                           AS vencido,
       COALESCE(p.pm_otc, 'SIN PM')                                     AS pm_otc
FROM DIM_PROYECTO p
LEFT JOIN HECHOS_ASIGNACION h ON h.id_proyecto = p.id_proyecto
WHERE p.estatus_proyecto = 'EN CURSO'
GROUP BY p.id_proyecto, p.cliente, p.proyecto, p.estatus_proyecto, p.fecha_fin, p.pm_otc
ORDER BY sin_personal DESC, vencido DESC, p.cliente;

-- name: P3_resumen
-- dimension: DIM_PROYECTO
-- pregunta: P3. Cuantos proyectos en curso estan sin personal, cuantos vencidos y cuantos sin PM de OTC?
WITH ec AS (
  SELECT p.id_proyecto, p.fecha_fin, p.pm_otc, COUNT(h.id_asignacion) AS n
  FROM DIM_PROYECTO p
  LEFT JOIN HECHOS_ASIGNACION h ON h.id_proyecto = p.id_proyecto
  WHERE p.estatus_proyecto = 'EN CURSO'
  GROUP BY p.id_proyecto, p.fecha_fin, p.pm_otc
)
SELECT COUNT(*)                                                                  AS proyectos_en_curso,
       SUM(CASE WHEN n = 0 THEN 1 ELSE 0 END)                                    AS sin_personal,
       ROUND(100.0 * SUM(CASE WHEN n = 0 THEN 1 ELSE 0 END) / COUNT(*), 0)       AS sin_cobertura_pct,
       SUM(CASE WHEN fecha_fin IS NOT NULL
                 AND fecha_fin < CAST((SELECT valor FROM PARAMETROS WHERE clave = 'fecha_corte') AS DATE)
                THEN 1 ELSE 0 END)                                               AS vencidos,
       (SELECT COUNT(*) FROM DIM_PROYECTO WHERE pm_otc IS NULL)                  AS proyectos_sin_pm_todos
FROM ec;

-- name: P5_costo_por_proyecto
-- dimension: DIM_PROYECTO
-- pregunta: P5. Cuanto cuesta al mes cada proyecto en plantilla asignada?
SELECT p.cliente, p.proyecto,
       COUNT(DISTINCT h.id_colaborador)           AS personas,
       ROUND(SUM(h.costo_mensual_asignado), 0)    AS costo_mensual,
       ROUND(AVG(h.costo_hora_persona), 0)        AS costo_hora_prom
FROM HECHOS_ASIGNACION h
JOIN DIM_PROYECTO p ON p.id_proyecto = h.id_proyecto
GROUP BY p.cliente, p.proyecto
ORDER BY costo_mensual DESC;

-- name: P5_costo_por_cliente
-- dimension: DIM_PROYECTO
-- pregunta: P5. Cuanto cuesta al mes cada cliente en plantilla asignada?
SELECT p.cliente,
       COUNT(DISTINCT h.id_colaborador)           AS personas,
       ROUND(SUM(h.costo_mensual_asignado), 0)    AS costo_mensual
FROM HECHOS_ASIGNACION h
JOIN DIM_PROYECTO p ON p.id_proyecto = h.id_proyecto
GROUP BY p.cliente
ORDER BY costo_mensual DESC;

-- name: P5_costo_total_asignado
-- dimension: DIM_PROYECTO
-- pregunta: P5. Cuanto cuesta en total la plantilla asignada? (debe cuadrar con nomina = asignado + banca)
SELECT ROUND(SUM(costo_mensual_asignado), 0) AS costo_mensual_asignado_total,
       COUNT(*)                              AS asignaciones
FROM HECHOS_ASIGNACION;

-- name: P5_costo_por_industria
-- dimension: DIM_PROYECTO
-- pregunta: P5 (extra). Cuanto cuesta la plantilla asignada por industria del cliente?
SELECT p.industria, COUNT(DISTINCT p.cliente) AS clientes,
       ROUND(SUM(h.costo_mensual_asignado), 0) AS costo_mensual
FROM HECHOS_ASIGNACION h
JOIN DIM_PROYECTO p ON p.id_proyecto = h.id_proyecto
GROUP BY p.industria
ORDER BY costo_mensual DESC;
