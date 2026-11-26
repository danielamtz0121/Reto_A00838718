# Diagnóstico de las fuentes de datos de OT Consulting

**Entrega individual**  
**Nombre:** Daniela Martinez Sauceda  
**Fecha de referencia del respaldo:** 17 de noviembre de 2026

## Objeto de estudio

El estudio examina si OT Consulting puede planear la disponibilidad de su personal para proyectos de clientes y estimar el costo de esa capacidad. El hecho central es la **participación de una persona en un proyecto durante un intervalo**. A ese nivel se necesita distinguir el tipo de participación, el rol desempeñado, las fechas y la parte de la jornada comprometida. Los activos y las habilidades aportan información para evaluar si la persona podría incorporarse a otro trabajo.

El respaldo contiene 31 participaciones con estatus «En Curso», pero 24 carecen de fecha de fin y 21 registran el mismo inicio de 1990. El vínculo con el catálogo de proyectos se resolvió en los 31 casos después de normalizar los nombres. El cuello de botella está en determinar cuándo y con qué capacidad termina cada compromiso. Una persona sin participación registrada puede estar en gestión interna, de licencia o pendiente de captura. Además, sumar su sueldo completo a cada proyecto duplicaría el costo si tiene compromisos simultáneos.

La partición analítica propuesta es **persona × proyecto × intervalo** para asignaciones y **persona × proyecto × período** para horas y costo. Nómina, habilidades y activos conservan sus propios niveles de detalle. Las uniones para reportes deben agregar cada fuente a su granularidad pertinente antes de combinarlas.

## Fuentes y metadata

El JSON es una fotografía estructurada de la aplicación al corte indicado por el nombre del archivo. Su historial y período de los importes deben confirmarse con el dueño. El notebook recibido describe diez Excel y sus rutas en Colab. Esos Excel no se entregaron. En el respaldo la nómina figura dentro de colaboradores y la inversión en activos solo se observa mediante los campos de compra del inventario. El notebook individual perfila el JSON ejecutable.

| Sección | Registros | Una fila representa | Llave o relación |
| --- | ---: | --- | --- |
| colaboradores | 107 | Expediente de una persona | `uid` técnico y `id` interno |
| usuarios | 6 | Cuenta de aplicación | `uid` propio de la cuenta |
| habilidades | 71 | Habilidad del catálogo | `codigo` referenciado por la matriz |
| roles | 55 | Perfil de trabajo | `codigo`; el puesto se coteja por nombre |
| departamentos | 6 | Unidad organizacional | `codigo` de catálogo |
| matriz | 56 | Mapa de niveles para una persona | `uid_colaborador`; 1,539 evaluaciones al desanidar |
| clientes | 8 | Organización cliente | `uid` y `codigo`; 12 proyectos anidados |
| asignaciones | 30 | Contenedor de participaciones de una persona | `uid_colaborador`; 31 participaciones al desanidar |
| activos | 123 | Equipo inventariado | `uid` y `codigo`; 91 entregas anidadas |
| secuenciaOTC | 1 escalar | Contador técnico de la aplicación | Entero fuera del modelo de análisis |

### Correspondencia con los Excel mencionados en el cuaderno recibido

| Archivo citado | Cobertura en el respaldo JSON |
| --- | --- |
| Catalogo_Colaboradores.xlsx | `colaboradores` |
| Sueldos_Salarios_OTC.xlsx | Importes de `colaboradores`; no hay extracto independiente para conciliar |
| Asignaciones_Colaboradores.xlsx | `asignaciones.proyectos` |
| Catalogo_Clientes.xlsx | `clientes` y `clientes.proyectos` |
| Catalogo_Activos.xlsx | `activos` y `activos.asignaciones` |
| Inversion_Activos_OTC.xlsx | Campos de compra de `activos`; no hay detalle de transacciones |
| Catalogo_Roles.xlsx | `roles` |
| Catalogo_Departamentos.xlsx | `departamentos` |
| Catalogo_Habilidades.xlsx | `habilidades` |
| Matriz_Habilidades.xlsx | `matriz.habilidades` |

### Diccionario funcional

El perfil de la sección 2 del cuaderno complementa este diccionario con tipos JSON, claves ausentes, nulos, blancos, contenedores vacíos y valores distintos para cada columna.

| Fuente | Campos | Interpretación |
| --- | --- | --- |
| Colaboradores | `uid`, `id`, `nombre`, `estatus` | Llave técnica, identificador de RH, nombre y estado del expediente |
| Colaboradores | `puesto`, `depto`, `nomina` | Perfil de trabajo, unidad organizacional y modalidad de nómina |
| Colaboradores | `fechanac`, `fechainc`, `fechabaja` | Nacimiento, incorporación y separación |
| Colaboradores | `curp`, `rfc`, `nss`, `genero` | Identificadores oficiales y género consignado |
| Colaboradores | `email`, `telefono`, `domicilio`, `ciudad` | Datos de contacto y residencia |
| Colaboradores | `sueldo_imss`, `sueldo_asimilados`, `sueldo_complementos` | Componentes del pago neto |
| Colaboradores | `sueldo_neto_total`, `comision_nomina`, `impuestos_imss`, `sueldo_total_integrado` | Neto consolidado, cargos asociados y total integrado |
| Colaboradores | `sgmm`, `segvida`, `med_condiciones` | Registros de seguros de gastos médicos y de vida, y condiciones médicas |
| Colaboradores | `ben_nombre`, `ben_parentesco`, `ben_porcentaje` | Nombre, vínculo y porcentaje del beneficiario |
| Colaboradores | `doc_acta`, `doc_banco`, `doc_compdom`, `doc_contrato`, `doc_csf`, `doc_curp`, `doc_foto`, `doc_ine`, `doc_nss`, `doc_pasaporte`, `doc_visa` | Registro documental de acta, banco, domicilio, contrato, constancia fiscal, CURP, foto, INE, NSS, pasaporte y visa |
| Colaboradores | `aviso_infonavit`, `aviso_manutencion`, `formato_rh`, `notas`, `anexos` | Avisos del expediente, formato de RH, observaciones y archivos vinculados |
| Usuarios | `uid`, `nombre`, `login`, `rol`, `estatus`, `pass` | Identificación y estado de la cuenta, nombre de acceso, permisos y campo de autenticación |
| Habilidades | `uid`, `codigo`, `tecnologia`, `descripcion`, `tipo`, `estatus` | Llaves, etiqueta, alcance, tipo HARD/SOFT y estado |
| Roles | `uid`, `codigo`, `nombre`, `depto`, `descripcion`, `nivel`, `estatus` | Llaves, título, área, alcance, nivel y estado del rol |
| Departamentos | `uid`, `codigo`, `nombre`, `objetivo`, `responsable`, `centroCostos`, `estatus` | Llaves, denominación, propósito, titular, centro contable y estado |
| Matriz | `uid_colaborador`, `habilidades` | Persona y mapa de código de habilidad a nivel ordinal |
| Clientes | `uid`, `codigo`, `nombre`, `estatus`, `industria`, `rfc` | Identidad comercial, estado, sector e identificador fiscal |
| Clientes | `direccion`, `ciudad`, `estado`, `pais`, `telefono` | Ubicación y teléfono general |
| Clientes | `contacto_nom`, `contacto_email`, `contacto_tel`, `proyectos` | Datos de contacto y lista de proyectos por cliente |
| Proyectos | `nombre`, `estatus`, `inicio`, `fin`, `pm_otc`, `resp_cli`, `email_cli`, `tel_cli` | Nombre, estado, intervalo y contactos de la gestión del proyecto. El UID del cliente se hereda del padre |
| Asignaciones | `uid_colaborador`, `proyectos` | Persona y lista de participaciones |
| Participaciones | `proyecto_val`, `rol`, `tipo`, `estatus`, `inicio`, `fin` | Referencia compuesta de cliente y proyecto, rol desempeñado, tipo, estado e intervalo. El UID de persona se hereda del padre |
| Activos | `uid`, `codigo`, `desc`, `tipo`, `uom`, `estatus` | Llaves, descripción, categoría, unidad de medida y estado |
| Activos | `marca`, `modelo`, `serie`, `cargador` | Características de identificación física y dato de cargador |
| Activos | `esquema`, `proveedor`, `costo`, `fcompra`, `fgarantia`, `notas`, `asignaciones` | Esquema de provisión, origen, importe, fechas, observaciones e historial de entregas |
| Entregas | `uid_colab`, `f_ini`, `f_fin`, `notas` | Persona receptora, intervalo de resguardo y observaciones. El UID del activo se hereda del padre |

## Bitácora de calidad

| ID | Fuente y campo | Tipo | Casos / universo | Impacto | Tratamiento propuesto |
| --- | --- | --- | ---: | --- | --- |
| H01 | Participaciones, `inicio` | Centinela candidato | 21 / 31 | Sesga la antigüedad y la vigencia | Operaciones confirma o reemplaza la fecha |
| H02 | Participaciones, `fin` | Faltante | 24 / 31 | Limita la planeación de liberaciones | Registrar fin esperado y fin real |
| H03 | Proyectos, `inicio` y `fin` | Faltantes | 6 / 12 y 9 / 12 | Limita cruces temporales y fechas de arranque | Validar el cronograma con cada PM |
| H04 | Colaboradores, `fechabaja` entre bajas | Faltante | 18 / 32 | Impide ubicar esas bajas en un período | Conciliar con los movimientos de RH |
| H05 | Colaboradores, `depto` y `doc_contrato` | Faltantes | 95 / 107 y 92 / 107 | Limita segmentación y control del expediente | Completar desde RH y registrar aplicabilidad |
| H06 | Roles, departamento | Faltante | 2 / 55 | Dificulta la imputación por unidad | Confirmar si el rol es transversal |
| H07 | Departamentos, responsable y centro de costos | Faltantes | 6 / 6 en ambos | Impide asignar responsables y costos | Completar con RH y finanzas |
| H08 | Evaluaciones, `uid_colaborador` | Integridad referencial | 10 / 1,539 | Deja niveles sin persona conciliada | Excluir del indicador de cobertura y conservar para revisión |
| H09 | Activos, `costo` | Cero por aclarar | 70 / 123 | Puede subestimar inversión | Verificar si es real, comodato o valor sin captura |
| H10 | Activos, `fcompra`, `proveedor`, `fgarantia` | Faltantes | 70 / 123, 70 / 123 y 123 / 123 | Debilita la planeación de renovación | Conciliar con inventario y compras |

Los conteos corresponden a filas por control. Pueden coincidir en el mismo registro. El cuaderno conserva también los controles con cero casos, incluidos duplicados de las claves ensayadas, cuadre de nómina con tolerancia de un centavo y coincidencias de proyectos después de normalizar.

## Reglas de negocio propuestas

1. Conservar el valor fuente y su versión estandarizada. Interpretar blancos como dato faltante y mantener separado el estado «No aplica» cuando el área dueña lo confirme.
2. Usar claves técnicas de persona, cliente y activo. Crear un identificador persistente de proyecto. Durante la transición, resolver la referencia con UID de cliente y nombre normalizado. Poner coincidencias nulas o múltiples en revisión.
3. Admitir varias participaciones por persona si el modelo operativo lo autoriza y la suma de dedicaciones simultáneas cabe en su capacidad. La exclusividad por rol requiere acuerdo de Operaciones. Registrar las horas de gestión interna para estimar disponibilidad.
4. Conservar inicio, fin planificado y fin real. Validar su orden. Si el centinela de 1990 se confirma, clasificarlo como fecha desconocida. Distinguir vigencia confirmada, finalizada, futura e indeterminada.
5. Conciliar neto e integrado con Nómina. Validar MXN y período de pago. Costear con la capacidad pagada del período y la dedicación por proyecto. Mantener una categoría para importes y horas sin evidencia.
6. Conservar la escala ordinal de habilidades. Registrar fecha y método de evaluación. Tratar una combinación ausente como «sin evaluación». Aplicar mínimos de nivel por rol con aprobación del área técnica.
7. Registrar el historial de entrega y devolución por activo. Verificar solapes y permitir excepciones documentadas si se comparte equipo. Confirmar el costo de compra y las garantías con Compras.
8. Limitar datos de identidad, salud, autenticación y nómina al personal autorizado. Publicar resultados agregados. Revisar con el dueño del repositorio la exposición del respaldo, incluidos los valores de autenticación y los datos personales que contiene.

## Preguntas detonadoras, métricas e indicadores

Las preguntas quedan planteadas para la etapa de análisis. Las fórmulas definen qué se medirá y bajo qué condiciones.

| ID | Pregunta | Datos existentes | Métrica derivada | Indicador de análisis | Atributos por incorporar |
| --- | --- | --- | --- | --- | --- |
| P1 | ¿Qué especialistas concluirán una participación en los próximos 30 días y cuánta capacidad podrán liberar? | Persona, proyecto, rol, estatus, fechas | Días al fin planificado; horas comprometidas liberables | Especialistas con fin entre corte y corte + 30; porcentaje de participaciones con fin confiable | Fin planificado y real, horas semanales, demás compromisos y ausencias |
| P2 | ¿Qué personas podrían incorporarse a un proyecto nuevo en la fecha solicitada? | Puesto, estatus, participaciones y evaluaciones | Horas disponibles = capacidad laboral − ausencias − horas comprometidas, sin duplicar conceptos | Capacidad libre por semana y rol; porcentaje de demanda cubierta | Calendario laboral, jornada, horas internas y pagadas, dedicación y demanda por semana |
| P3 | ¿Cuál es el costo por hora de cada especialista y el costo laboral de cada proyecto por período? | Neto, comisión, impuestos y total integrado | Tarifa = costo integrado del período / horas pagadas del período; costo proyecto = suma de tarifa × horas imputadas | Costo laboral por proyecto/mes y porcentaje de horas con tarifa validada | Moneda y periodicidad, vigencia de nómina, horas pagadas y reales por persona/proyecto |
| P4 | ¿En qué competencias faltan candidatos para los próximos proyectos? | Código, nivel, tipo de habilidad, puesto y estatus | Candidatos disponibles cuyo nivel ≥ mínimo en cada habilidad requerida | Cobertura = plazas con candidato elegible / plazas requeridas; brecha por habilidad | Perfil requerido, nivel mínimo, plazas, fechas y vigencia de evaluación |
| P5 | ¿Qué equipos deberán renovarse o reasignarse para cumplir los próximos arranques? | Tipo, fecha de compra, fin de garantía y entregas | Antigüedad del equipo y días hasta garantía; inventario operable disponible | Equipos disponibles / equipos requeridos y porcentaje con garantía conocida | Estado físico, fin de garantía confirmado, política de vida útil y requisitos del proyecto |
| P6 | ¿Qué tan confiables son los datos semanales de planeación por área? | Estatus, fechas, claves y catálogos | Casos válidos por control / registros aplicables | Completitud de fechas, integridad referencial y casos abiertos por área | Área responsable confirmada, fecha de actualización y estado de corrección |

Las métricas de origen incluyen los importes de nómina, costo de compra y nivel ordinal registrado. Los conteos de personas, proyectos, participaciones y equipos se obtienen de su propia granularidad. Las tasas calculadas deben publicar su denominador. Un denominador vacío se reporta como «no calculable». Los indicadores deben acompañarse de cobertura cuando haya registros sin evidencia.

## Anexo de evidencia reproducible

[OTC_EDA_Individual.ipynb](OTC_EDA_Individual.ipynb)

| Sección | Evidencia conservada |
| --- | --- |
| 1. Ingesta | Nombre y tamaño del JSON, huella SHA-256 e inventario de secciones |
| 2. Perfil Python | Tipos y conteos por columna, incluidos los detalles anidados |
| 3. Validación | Código y resultados de fechas, llaves, referencias, dominios y cuadre |
| 4. SQLite | Código SQL y salidas agregadas de cobertura, vínculos y evaluaciones |

Para reproducir, colocar una copia autorizada del JSON junto al cuaderno o en `upload/` y ejecutar todas las celdas con Python 3. El respaldo contiene datos personales y campos de autenticación, por lo que el anexo muestra resultados agregados y se entrega sin una copia adicional del JSON.
