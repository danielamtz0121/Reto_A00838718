-- ============================================================================
-- OT Consulting - consultas sobre DIM_DEPARTAMENTO (complementaria; propuesta de la Etapa 2)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: DEP_plantilla_y_costo
-- dimension: DIM_DEPARTAMENTO
-- pregunta: Cuantas personas activas y cuanto cuesta al mes cada departamento?
SELECT COALESCE(d.departamento, 'SIN DEPARTAMENTO (SIN PUESTO)') AS departamento,
       COUNT(*)                                                 AS activos,
       ROUND(SUM(c.costo_mensual), 0)                           AS costo_mensual,
       ROUND(AVG(c.antiguedad_anios), 1)                        AS antiguedad_prom_anios
FROM DIM_COLABORADOR c
LEFT JOIN DIM_DEPARTAMENTO d ON d.codigo_departamento = c.departamento_codigo
WHERE c.es_activo = 1
GROUP BY COALESCE(d.departamento, 'SIN DEPARTAMENTO (SIN PUESTO)')
ORDER BY activos DESC;
