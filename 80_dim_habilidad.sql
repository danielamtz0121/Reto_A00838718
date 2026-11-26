-- ============================================================================
-- OT Consulting - consultas sobre DIM_HABILIDAD (complementaria)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: P7_cobertura_por_habilidad
-- dimension: DIM_HABILIDAD
-- pregunta: P7. Que habilidades tienen menos de 2 personas activas en nivel Avanzado o Experto?
SELECT d.codigo_habilidad, d.habilidad, d.tecnologia, d.tipo_habilidad,
       COUNT(h.id_colaborador)                                                              AS evaluados_activos,
       COALESCE(SUM(CASE WHEN h.nivel_num >= 3 THEN 1 ELSE 0 END), 0)                       AS personas_nivel_3_mas
FROM DIM_HABILIDAD d
LEFT JOIN (
    SELECT hh.* FROM HECHOS_HABILIDAD hh
    JOIN DIM_COLABORADOR c ON c.id_colaborador = hh.id_colaborador AND c.es_activo = 1
) h ON h.codigo_habilidad = d.codigo_habilidad
GROUP BY d.codigo_habilidad, d.habilidad, d.tecnologia, d.tipo_habilidad
HAVING COALESCE(SUM(CASE WHEN h.nivel_num >= 3 THEN 1 ELSE 0 END), 0) < 2
ORDER BY personas_nivel_3_mas, d.habilidad;

-- name: P7_resumen
-- dimension: DIM_HABILIDAD
-- pregunta: P7. Cuantas habilidades tienen menos de 2 y cuantas tienen 0 personas activas en nivel 3+?
WITH cob AS (
  SELECT d.codigo_habilidad,
         COALESCE(SUM(CASE WHEN h.nivel_num >= 3 THEN 1 ELSE 0 END), 0) AS n3
  FROM DIM_HABILIDAD d
  LEFT JOIN (
      SELECT hh.* FROM HECHOS_HABILIDAD hh
      JOIN DIM_COLABORADOR c ON c.id_colaborador = hh.id_colaborador AND c.es_activo = 1
  ) h ON h.codigo_habilidad = d.codigo_habilidad
  GROUP BY d.codigo_habilidad
)
SELECT COUNT(*)                                       AS habilidades,
       SUM(CASE WHEN n3 < 2 THEN 1 ELSE 0 END)        AS con_menos_de_2,
       SUM(CASE WHEN n3 = 0 THEN 1 ELSE 0 END)        AS con_cero
FROM cob;

-- name: P8_banca_con_perfil
-- dimension: DIM_HABILIDAD
-- pregunta: P8. Cuantos de la banca tienen una matriz de habilidades confiable (>= 4 habilidades evaluadas)?
SELECT COUNT(*) AS banca_total,
       SUM(CASE WHEN c.matriz_confiable = 1 THEN 1 ELSE 0 END) AS con_matriz_confiable
FROM DIM_COLABORADOR c
WHERE c.es_activo = 1
  AND c.id_colaborador NOT IN (
        SELECT h.id_colaborador
        FROM HECHOS_ASIGNACION h
        JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
        WHERE e.estatus_asignacion = 'EN CURSO');

-- name: P8_banca_para_cerrar_brechas
-- dimension: DIM_HABILIDAD
-- pregunta: P8 (aproximacion). Quien de la banca tiene nivel 3+ en las habilidades con cobertura baja?
-- nota: Clientes no trae el perfil que pide cada proyecto, asi que el cruce exacto con proyectos sin
--       personal no se puede hacer; esta consulta usa como referencia las brechas de P7.
WITH cob AS (
  SELECT d.codigo_habilidad, d.habilidad,
         COALESCE(SUM(CASE WHEN h.nivel_num >= 3 THEN 1 ELSE 0 END), 0) AS n3
  FROM DIM_HABILIDAD d
  LEFT JOIN (
      SELECT hh.* FROM HECHOS_HABILIDAD hh
      JOIN DIM_COLABORADOR c ON c.id_colaborador = hh.id_colaborador AND c.es_activo = 1
  ) h ON h.codigo_habilidad = d.codigo_habilidad
  GROUP BY d.codigo_habilidad, d.habilidad
  HAVING n3 < 2
),
banca AS (
  SELECT c.id_colaborador, c.nombre_colaborador
  FROM DIM_COLABORADOR c
  WHERE c.es_activo = 1 AND c.matriz_confiable = 1
    AND c.id_colaborador NOT IN (
          SELECT h.id_colaborador
          FROM HECHOS_ASIGNACION h
          JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
          WHERE e.estatus_asignacion = 'EN CURSO')
)
SELECT cob.habilidad, cob.n3 AS personas_nivel_3_mas_hoy,
       COUNT(DISTINCT b.id_colaborador) AS banca_con_nivel_3_mas,
       GROUP_CONCAT(DISTINCT b.nombre_colaborador) AS quienes
FROM cob
JOIN HECHOS_HABILIDAD hh ON hh.codigo_habilidad = cob.codigo_habilidad AND hh.nivel_num >= 3
JOIN banca b ON b.id_colaborador = hh.id_colaborador
GROUP BY cob.habilidad, cob.n3
ORDER BY banca_con_nivel_3_mas DESC, cob.habilidad;
