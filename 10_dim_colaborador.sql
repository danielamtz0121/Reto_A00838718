-- ============================================================================
-- OT Consulting - consultas sobre DIM_COLABORADOR (quien)
-- MySQL 8.0 o superior. Primero cargue la base con 00_cargar_datos.sql.
-- En MySQL Workbench: abra este archivo y ejecute todo (rayo); cada consulta abre su pestana de resultados.
-- Para correr solo una consulta, seleccionela y use Ctrl+Enter.
-- ============================================================================
USE otc_dw;
SET SESSION group_concat_max_len = 100000;

-- name: P1_tasa_utilizacion
-- dimension: DIM_COLABORADOR
-- pregunta: P1. Que porcentaje de los activos esta asignado a un proyecto y cuantos estan en banca?
WITH asignados AS (
  SELECT DISTINCT h.id_colaborador
  FROM HECHOS_ASIGNACION h
  JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
  WHERE e.estatus_asignacion = 'EN CURSO'
)
SELECT COUNT(*)                                                         AS activos,
       SUM(CASE WHEN a.id_colaborador IS NOT NULL THEN 1 ELSE 0 END)    AS con_asignacion,
       SUM(CASE WHEN a.id_colaborador IS NULL THEN 1 ELSE 0 END)        AS en_banca,
       ROUND(100.0 * SUM(CASE WHEN a.id_colaborador IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS tasa_utilizacion_pct
FROM DIM_COLABORADOR c
LEFT JOIN asignados a ON a.id_colaborador = c.id_colaborador
WHERE c.es_activo = 1;

-- name: P1_banca_sensibilidad
-- dimension: DIM_COLABORADOR
-- pregunta: P1 (sensibilidad). Cuantos activos quedan en banca si se excluyen las asignaciones ya vencidas?
WITH vigentes AS (
  SELECT DISTINCT h.id_colaborador
  FROM HECHOS_ASIGNACION h
  JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
  WHERE e.estatus_asignacion = 'EN CURSO' AND e.estado_vigencia <> 'VENCIDA'
)
SELECT COUNT(*) AS en_banca_ajustada
FROM DIM_COLABORADOR c
LEFT JOIN vigentes v ON v.id_colaborador = c.id_colaborador
WHERE c.es_activo = 1 AND v.id_colaborador IS NULL;

-- name: P1_banca_detalle
-- dimension: DIM_COLABORADOR
-- pregunta: P1. Quienes estan en banca? (lista para que Direccion les busque proyecto)
SELECT c.id_colaborador, c.nombre_colaborador,
       COALESCE(c.puesto, 'SIN PUESTO REGISTRADO') AS puesto,
       c.familia_puesto, c.tipo_banca, c.esquema_nomina, c.costo_mensual
FROM DIM_COLABORADOR c
WHERE c.es_activo = 1
  AND c.id_colaborador NOT IN (
        SELECT h.id_colaborador
        FROM HECHOS_ASIGNACION h
        JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
        WHERE e.estatus_asignacion = 'EN CURSO')
ORDER BY c.tipo_banca, c.costo_mensual DESC;

-- name: P4_costo_hora_global
-- dimension: DIM_COLABORADOR
-- pregunta: P4. Cuanto cuesta por hora un colaborador activo en promedio? (horas por mes en PARAMETROS)
SELECT COUNT(costo_hora)               AS personas_con_sueldo,
       ROUND(AVG(costo_hora), 1)       AS promedio,
       ROUND(MIN(costo_hora), 1)       AS minimo,
       ROUND(MAX(costo_hora), 1)       AS maximo,
       SUM(CASE WHEN costo_mensual IS NULL THEN 1 ELSE 0 END) AS activos_sin_sueldo
FROM DIM_COLABORADOR
WHERE es_activo = 1;

-- name: P4_costo_hora_esquema
-- dimension: DIM_COLABORADOR
-- pregunta: P4. Cuanto cuesta por hora cada colaborador segun su esquema de nomina?
-- nota: la mediana se calcula en Python (la mediana se calcula en Python); ver python/consultas_pandas.py
SELECT esquema_nomina,
       COUNT(costo_hora)          AS personas,
       ROUND(AVG(costo_hora), 1)  AS promedio,
       ROUND(MIN(costo_hora), 1)  AS minimo,
       ROUND(MAX(costo_hora), 1)  AS maximo
FROM DIM_COLABORADOR
WHERE es_activo = 1 AND costo_hora IS NOT NULL
GROUP BY esquema_nomina
ORDER BY personas DESC;

-- name: P6_costo_banca
-- dimension: DIM_COLABORADOR
-- pregunta: P6. Cuanto paga OTC al mes por gente sin proyecto?
WITH asignados AS (
  SELECT DISTINCT h.id_colaborador
  FROM HECHOS_ASIGNACION h
  JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
  WHERE e.estatus_asignacion = 'EN CURSO'
)
SELECT c.tipo_banca,
       COUNT(*)                            AS personas,
       ROUND(SUM(c.costo_mensual), 0)      AS costo_mensual,
       SUM(CASE WHEN c.costo_mensual IS NULL THEN 1 ELSE 0 END) AS sin_sueldo
FROM DIM_COLABORADOR c
LEFT JOIN asignados a ON a.id_colaborador = c.id_colaborador
WHERE c.es_activo = 1 AND a.id_colaborador IS NULL
GROUP BY c.tipo_banca
ORDER BY costo_mensual DESC;

-- name: P6_peso_banca
-- dimension: DIM_COLABORADOR
-- pregunta: P6. Que parte de la nomina activa es banca? (meta sugerida <= 10%)
WITH asignados AS (
  SELECT DISTINCT h.id_colaborador
  FROM HECHOS_ASIGNACION h
  JOIN DIM_ESTADO_ASIGNACION e ON e.id_estado_asignacion = h.id_estado_asignacion
  WHERE e.estatus_asignacion = 'EN CURSO'
)
SELECT ROUND(SUM(CASE WHEN a.id_colaborador IS NULL THEN c.costo_mensual ELSE 0 END), 0) AS costo_banca,
       ROUND(SUM(c.costo_mensual), 0)                                                    AS nomina_activa,
       ROUND(100.0 * SUM(CASE WHEN a.id_colaborador IS NULL THEN c.costo_mensual ELSE 0 END)
             / SUM(c.costo_mensual), 1)                                                  AS peso_banca_pct
FROM DIM_COLABORADOR c
LEFT JOIN asignados a ON a.id_colaborador = c.id_colaborador
WHERE c.es_activo = 1;

-- name: P9_bajas_por_mes
-- dimension: DIM_COLABORADOR
-- pregunta: P9. Cuantas bajas hay por mes? (rotacion = bajas / headcount al inicio del mes)
WITH meses AS (
  SELECT anio_mes_baja AS mes, COUNT(*) AS bajas
  FROM DIM_COLABORADOR
  WHERE anio_mes_baja IS NOT NULL AND estatus_corte = 'BAJA'   -- la baja programada futura no cuenta
  GROUP BY anio_mes_baja
)
SELECT m.mes, m.bajas,
       (SELECT COUNT(*) FROM DIM_COLABORADOR c
        WHERE c.fecha_incorporacion < CAST(CONCAT(m.mes, '-01') AS DATE)
          AND (c.fecha_baja IS NULL OR c.fecha_baja >= CAST(CONCAT(m.mes, '-01') AS DATE))
          AND (c.es_activo = 1 OR c.fecha_baja IS NOT NULL))                       AS headcount_inicio,
       ROUND(100.0 * m.bajas /
             (SELECT COUNT(*) FROM DIM_COLABORADOR c
              WHERE c.fecha_incorporacion < CAST(CONCAT(m.mes, '-01') AS DATE)
                AND (c.fecha_baja IS NULL OR c.fecha_baja >= CAST(CONCAT(m.mes, '-01') AS DATE))
                AND (c.es_activo = 1 OR c.fecha_baja IS NOT NULL)), 1)             AS rotacion_pct
FROM meses m
ORDER BY m.mes;

-- name: P9_bajas_por_puesto
-- dimension: DIM_COLABORADOR
-- pregunta: P9. En que puestos se concentran las bajas?
SELECT COALESCE(puesto, 'SIN PUESTO REGISTRADO') AS puesto, COUNT(*) AS bajas
FROM DIM_COLABORADOR
WHERE estatus_corte = 'BAJA'
GROUP BY COALESCE(puesto, 'SIN PUESTO REGISTRADO')
ORDER BY bajas DESC, puesto;

-- name: P9_bajas_sin_fecha
-- dimension: DIM_COLABORADOR
-- pregunta: P9. Cuantas bajas tienen fecha y cuantas no (rotacion no calculable)?
SELECT SUM(CASE WHEN baja_sin_fecha = 0 THEN 1 ELSE 0 END) AS bajas_con_fecha,
       SUM(CASE WHEN baja_sin_fecha = 1 THEN 1 ELSE 0 END) AS bajas_sin_fecha
FROM DIM_COLABORADOR
WHERE estatus_corte = 'BAJA';

-- name: P10_expediente_resumen
-- dimension: DIM_COLABORADOR
-- pregunta: P10. Que tan completo esta el expediente de RH de los activos?
SELECT COUNT(*)                                                       AS activos,
       SUM(CASE WHEN docs_basicos_ok = 7 THEN 1 ELSE 0 END)           AS expedientes_completos,
       ROUND(100.0 * SUM(CASE WHEN docs_basicos_ok = 7 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_completos,
       SUM(CASE WHEN contrato_estatus = 'PENDIENTE' THEN 1 ELSE 0 END) AS contratos_pendientes
FROM DIM_COLABORADOR
WHERE es_activo = 1;

-- name: P10_expediente_por_documento
-- dimension: DIM_COLABORADOR
-- pregunta: P10. Que documentos son los que mas faltan?
SELECT 'ACTA'                  AS documento, SUM(doc_acta = 'PENDIENTE')                AS pendientes FROM DIM_COLABORADOR WHERE es_activo = 1
UNION ALL SELECT 'INE',                       SUM(doc_ine = 'PENDIENTE')                FROM DIM_COLABORADOR WHERE es_activo = 1
UNION ALL SELECT 'CURP',                      SUM(doc_curp = 'PENDIENTE')               FROM DIM_COLABORADOR WHERE es_activo = 1
UNION ALL SELECT 'CONSTANCIA FISCAL',         SUM(doc_const_fiscal = 'PENDIENTE')       FROM DIM_COLABORADOR WHERE es_activo = 1
UNION ALL SELECT 'NSS',                       SUM(doc_nss = 'PENDIENTE')                FROM DIM_COLABORADOR WHERE es_activo = 1
UNION ALL SELECT 'COMPROBANTE DOMICILIO',     SUM(doc_comprobante_domicilio = 'PENDIENTE') FROM DIM_COLABORADOR WHERE es_activo = 1
UNION ALL SELECT 'DATOS BANCARIOS',           SUM(doc_banco = 'PENDIENTE')              FROM DIM_COLABORADOR WHERE es_activo = 1
UNION ALL SELECT 'FOTO',                      SUM(doc_foto = 'PENDIENTE')               FROM DIM_COLABORADOR WHERE es_activo = 1
ORDER BY pendientes DESC;
