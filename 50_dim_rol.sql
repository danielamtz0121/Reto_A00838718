-- ============================================================================
-- OT Consulting - consultas sobre DIM_ROL (con que funcion)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: P5_costo_por_rol
-- dimension: DIM_ROL
-- pregunta: P5. Cuanto cuesta al mes la plantilla asignada por rol efectivo?
SELECT r.rol_efectivo,
       COUNT(*)                                AS asignaciones,
       ROUND(SUM(h.costo_mensual_asignado), 0) AS costo_mensual,
       ROUND(AVG(h.costo_hora_persona), 0)     AS costo_hora_prom
FROM HECHOS_ASIGNACION h
JOIN DIM_ROL r ON r.id_rol = h.id_rol
GROUP BY r.rol_efectivo
ORDER BY costo_mensual DESC;

-- name: P4_origen_del_rol
-- dimension: DIM_ROL
-- pregunta: P4/P5. De donde sale el rol con el que se costea cada asignacion?
SELECT r.fuente_rol, r.rol_faltante, COUNT(*) AS asignaciones,
       ROUND(SUM(h.costo_mensual_asignado), 0) AS costo_mensual
FROM HECHOS_ASIGNACION h
JOIN DIM_ROL r ON r.id_rol = h.id_rol
GROUP BY r.fuente_rol, r.rol_faltante
ORDER BY asignaciones DESC;
