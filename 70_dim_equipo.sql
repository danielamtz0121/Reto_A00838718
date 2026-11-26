-- ============================================================================
-- OT Consulting - consultas sobre DIM_EQUIPO (complementaria)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: P11_equipos_por_situacion
-- dimension: DIM_EQUIPO
-- pregunta: P11. Como se reparten los equipos segun su situacion y cuanto valen?
SELECT e.situacion_equipo,
       COUNT(*)                                                       AS equipos,
       ROUND(SUM(h.costo_equipo), 0)                                  AS valor_conocido,
       SUM(CASE WHEN h.costo_equipo IS NULL THEN 1 ELSE 0 END)        AS sin_costo
FROM DIM_EQUIPO e
JOIN HECHOS_EQUIPO h ON h.cod_activo = e.cod_activo
GROUP BY e.situacion_equipo
ORDER BY equipos DESC;

-- name: P11_equipos_a_nombre_de_bajas
-- dimension: DIM_EQUIPO
-- pregunta: P11. Cuantos equipos siguen a nombre de bajas y cuanto valen?
SELECT COUNT(*)                                                       AS equipos_a_nombre_de_bajas,
       SUM(CASE WHEN e.equipo_por_recuperar = 1 THEN 1 ELSE 0 END)    AS por_recuperar,
       ROUND(SUM(CASE WHEN e.equipo_por_recuperar = 1 THEN h.costo_equipo END), 0) AS valor_por_recuperar,
       SUM(CASE WHEN e.equipo_por_recuperar = 1 AND h.costo_equipo IS NULL THEN 1 ELSE 0 END) AS por_recuperar_sin_costo
FROM DIM_EQUIPO e
JOIN HECHOS_EQUIPO h ON h.cod_activo = e.cod_activo
WHERE e.equipo_a_nombre_de_baja = 1;

-- name: P11_equipos_por_recuperar_detalle
-- dimension: DIM_EQUIPO
-- pregunta: P11. Cuales son los equipos por recuperar y a nombre de quien estan?
SELECT e.cod_activo, e.tipo, e.marca, e.modelo, c.nombre_colaborador AS a_nombre_de, c.fecha_baja, h.costo_equipo
FROM DIM_EQUIPO e
JOIN HECHOS_EQUIPO h ON h.cod_activo = e.cod_activo
JOIN DIM_COLABORADOR c ON c.id_colaborador = h.id_colaborador
WHERE e.equipo_por_recuperar = 1
ORDER BY c.fecha_baja, e.cod_activo;

-- name: DQ_costo_equipos
-- dimension: DIM_EQUIPO
-- pregunta: Cuantos equipos no tienen costo registrado? (la inversion real es mayor al valor conocido)
SELECT COUNT(*) AS equipos,
       SUM(CASE WHEN h.costo_equipo IS NULL THEN 1 ELSE 0 END) AS sin_costo,
       ROUND(100.0 * SUM(CASE WHEN h.costo_equipo IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_sin_costo,
       ROUND(SUM(h.costo_equipo), 0) AS inversion_conocida
FROM HECHOS_EQUIPO h;

-- name: DQ_fecha_equipo_anomala
-- dimension: DIM_EQUIPO
-- pregunta: Hay equipos con fechas imposibles? (se tratan como desconocidas)
SELECT cod_activo, tipo, marca, modelo
FROM DIM_EQUIPO
WHERE anomalia_fecha_inicio_asignacion = 1;
