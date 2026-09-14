# Construye enem_codebook (el crosswalk) y enem_panel (el panel armonizado)
# a partir de los 10 .dta originales.
#
# NOTA: la primera versión de data/enem_codebook.rda y data/enem_panel.rda
# que trae este repo se construyó fuera de este script (procesando los
# .dta con pandas en la sesión donde se hizo el mapeo variable por
# variable) -- este script es la versión reproducible en R/haven para tu
# ambiente, y para cuando haya que regenerar los datos (nuevas olas,
# correcciones). Los resultados deben ser equivalentes.
#
# Mapa de columnas (confirmado a mano contra inst/extdata/inventario_variables.csv,
# ver también Reporte_ENEM_bases_1997_2024.xlsx hoja "Inventario_variables"):
#
#   - sexo: se usa female<anio>, YA recodificado en el .dta original. NO
#     uses la variable cruda (sex/s1/ps1/s2/S2) directamente: el número de
#     pregunta que corresponde a "sexo" CAMBIA de lugar entre olas -- en
#     2003/2006/2009 sexo es la pregunta "1" (s1/ps1) y edad es la "2", pero
#     desde 2012 se invirtió: sexo pasó a ser la pregunta "2" (s2/S2) y edad
#     la "1". female<anio> ya resuelve esa inconsistencia por ti.
#   - edad_grupo: se usa age<anio>b, ya recodificado a 4 categorías. La
#     variable cruda 'edad'/'EDAD' en algunos años ya viene pre-agrupada (solo
#     4-5 valores unicos) y en otros no existe -- age<anio>b es la unica
#     consistente en las 10 olas.
#   - municipio: NO hay nombre de variable único entre olas, y 2000 no
#     trae ninguna variable de geografía. Los códigos NO están armonizados
#     a un catálogo común (p.ej. INEGI) entre años -- se transportan tal
#     cual, como referencia, no como variable analítica lista para comparar
#     entre olas.
#   - fecha: falta en 1997/2000/2003/2012. En 2006 la columna 'fecha' EXISTE
#     mas esta 100% vacía en los .dta originales -- se trata igual que "no
#     disponible".
#   - folio: falta en 2018. Y OJO -- en 8 de las 10 olas 'folio' NO es un
#     identificador único por respondiente (se repite entre varias filas,
#     probablemente es folio de lote/cuestionario impreso, no de persona).
#     Solo en 2024 folio sí identifica de forma única a cada entrevistado
#     (nunique(folio) == n). Revisa `folio_es_id_unico` antes de usar folio
#     como llave.
#   - aprobacion (pdte_acuerdo / pdte_aprueba): pregunta presente en las 10
#     olas ("En general, esta usted de acuerdo o en desacuerdo con la
#     manera como esta gobernando el presidente [Nombre]?"), pero el nombre
#     de variable cambia en CADA ola (p23/pacu/p28/p46/pacu/p42/p48/p15/P2/P2)
#     y los codigos de no respuesta tambien migran: 5=NS/6=NC en 1997-2000,
#     8=NS/9=NC en 2003-2018, 98=NS/99=NC en 2021-2024. La escala sustantiva
#     SI es consistente en las 10 olas: 1-4 (no es binaria pese al fraseo de
#     la pregunta). No hay value labels en los .dta para confirmar el texto
#     exacto de las 4 categorias -- se asume 1=Muy de acuerdo, 2=Algo de
#     acuerdo, 3=Algo en desacuerdo, 4=Muy en desacuerdo, direccion
#     confirmada por consistencia con la evolucion historica conocida de
#     aprobacion presidencial (Pena Nieto con el minimo de "muy de acuerdo"
#     y maximo de "muy en desacuerdo" en 2018; AMLO con el maximo de "muy de
#     acuerdo" en 2021/2024). Ver R/data.R y enem_codebook() para el detalle.
#     ACTUALIZACION: tras cruzar con ENEM_candidatos_armonizacion_1997_2024.xlsx
#     (inventario mas riguroso, con cita a cuestionario PDF), se decidio
#     INVERTIR la escala armonizada (procesar_ola.R hace 5-val) para que quede
#     1=Muy en desacuerdo ... 4=Muy de acuerdo (mayor valor = mas aprobacion),
#     consistente con la convencion "mayor valor = mas del concepto" que se
#     usara para el resto del panel (ideologia, evaluacion de partidos, etc).
#   - id_ola / id_panel: la columna cruda 'id' (no 'folio') SI es unica dentro
#     de cada una de las 10 olas -- confirmado por conteo distinto == n filas
#     en las 10 bases. id_panel = anio + "_" + id (implementado en
#     procesar_ola.R) es la llave recomendada para unir enem_panel con otras
#     fuentes por ola; folio se conserva solo como referencia historica (ver
#     advertencia de unicidad de folio arriba).

mapa_columnas <- list(
  "1997" = list(archivo = "ENEM_1997_isco08.dta", sexo = "female1997", edad_grupo = "age1997b", municipio = "MUNICIPIO", fecha = NA, folio = "folio", aprobacion = "p23",  aprobacion_na = c(5, 6)),
  "2000" = list(archivo = "ENEM_2000_isco08.dta", sexo = "female2000", edad_grupo = "age2000b", municipio = NA,          fecha = NA, folio = "folio", aprobacion = "pacu", aprobacion_na = c(5, 6)),
  "2003" = list(archivo = "ENEM_2003_isco08.dta", sexo = "female2003", edad_grupo = "age2003b", municipio = "muni",      fecha = NA, folio = "folio", aprobacion = "p28",  aprobacion_na = c(8, 9)),
  "2006" = list(archivo = "ENEM_2006_isco08.dta", sexo = "female2006", edad_grupo = "age2006b", municipio = "MPIO",      fecha = NA, folio = "folio", aprobacion = "p46",  aprobacion_na = c(8, 9)), # 'fecha' existe pero vacia
  "2009" = list(archivo = "ENEM_2009_isco08.dta", sexo = "female2009", edad_grupo = "age2009b", municipio = "MPIO",      fecha = "fecha", folio = "folio", aprobacion = "pacu", aprobacion_na = c(8, 9)),
  "2012" = list(archivo = "ENEM_2012_isco08.dta", sexo = "female2012", edad_grupo = "age2012b", municipio = "edompio",   fecha = NA, folio = "folio", aprobacion = "p42",  aprobacion_na = c(8, 9)),
  "2015" = list(archivo = "ENEM_2015_isco08.dta", sexo = "female2015", edad_grupo = "age2015b", municipio = "mpio",      fecha = "fecha", folio = "folio", aprobacion = "p48",  aprobacion_na = c(8, 9)),
  "2018" = list(archivo = "ENEM_2018_isco08.dta", sexo = "female2018", edad_grupo = "age2018b", municipio = "MPIO",      fecha = "FECHA", folio = NA, aprobacion = "p15",  aprobacion_na = c(8, 9)),
  "2021" = list(archivo = "ENEM_2021_isco08.dta", sexo = "female2021", edad_grupo = "age2021b", municipio = "mpio",      fecha = "FECHAENT", folio = "folio", aprobacion = "P2", aprobacion_na = c(98, 99)),
  "2024" = list(archivo = "ENEM_2024_isco08.dta", sexo = "female2024", edad_grupo = "age2024b", municipio = "mpio",      fecha = "Fecha", folio = "folio", aprobacion = "P2", aprobacion_na = c(98, 99))
)

isco_cols <- c("isco08_1_ES", "isco08_2_ES", "isco08_1_ENG", "isco08_2_ENG")

# --- Fase 2 del plan "dataset principal": conceptos tipo "escala 0-10
# conservada tal cual" (tier "Priorizar" restante). Regla comun (ver
# ENEM_candidatos_armonizacion_1997_2024.xlsx, hoja Resumen): "Conservar
# 0-10; separar NS, NC y no conoce suficiente" -- se implementa como
# valido si 0 <= val <= 10, cualquier otro codigo a NA. Sin inversion (a
# diferencia de aprobacion presidencial): ideologia ya viene 0=izquierda/
# 10=derecha, y las evaluaciones de partido ya vienen 0=le gusta nada/
# 10=le gusta mucho.
escalas_0_10 <- list(
  ideologia_lr = c("1997" = "p16_1", "2000" = "p20_1", "2003" = "p24",   "2006" = "p13",  "2009" = "p13",  "2012" = "p19",   "2015" = "p21",  "2018" = "P24",   "2021" = "P25",   "2024" = "P20"),
  eval_pan     = c("1997" = "p7_1",  "2000" = "p10_1", "2003" = "p19_1", "2006" = "p9a",  "2009" = "p9a",  "2012" = "p16_1", "2015" = "p19a", "2018" = "P20_1", "2021" = "P22_1", "2024" = "P16_1"),
  eval_prd     = c("1997" = "p7_3",  "2000" = "p10_3", "2003" = "p19_3", "2006" = "p9c",  "2009" = "p9c",  "2012" = "p16_3", "2015" = "p19c", "2018" = "P20_3", "2021" = "P22_3", "2024" = "P16_3"),
  eval_pri     = c("1997" = "p7_2",  "2000" = "p10_2", "2003" = "p19_2", "2006" = "p9b",  "2009" = "p9b",  "2012" = "p16_2", "2015" = "p19b", "2018" = "P20_2", "2021" = "P22_2", "2024" = "P16_2")
)

# --- Fase 3 del plan "dataset principal" (subgrupo "Partidos/ideologia" del
# tier "Con ajustes"): like_pt/like_pvem son mecanicos, mismo patron exacto
# que eval_pan/prd/pri arriba (confirmado contra ENEM_candidatos_armonizacion_1997_2024.xlsx
# hoja Codigos: mismo esquema 0-10 + especiales en las 10 olas). Las 5
# ideology_<partido> (ubicacion izquierda-derecha DE cada partido, NO
# confundir con ideologia_lr que es autoubicacion) siguen el mismo patron
# 0-10 PERO 2018 desplaza los codigos +1 (ver escalas_0_10_offsets abajo).
escalas_0_10 <- c(escalas_0_10, list(
  eval_pt        = c("1997" = "p7_4",  "2000" = "p10_4", "2003" = "p19_5", "2006" = "p9e",  "2009" = "p9e",  "2012" = "p16_5", "2015" = "p19e", "2018" = "P20_5", "2021" = "P22_6", "2024" = "P16_6"),
  eval_pvem      = c("1997" = "p7_5",  "2000" = "p10_5", "2003" = "p19_4", "2006" = "p9d",  "2009" = "p9d",  "2012" = "p16_4", "2015" = "p19d", "2018" = "P20_4", "2021" = "P22_5", "2024" = "P16_5"),
  ideologia_pan  = c("1997" = "p16_2", "2000" = "p20_2", "2003" = "p20_1", "2006" = "p11a", "2009" = "p11a", "2012" = "p18_1", "2015" = "p20a", "2018" = "P22_1", "2021" = "P24_1", "2024" = "P18_1"),
  ideologia_prd  = c("1997" = "p16_4", "2000" = "p20_4", "2003" = "p20_3", "2006" = "p11c", "2009" = "p11c", "2012" = "p18_3", "2015" = "p20c", "2018" = "P22_3", "2021" = "P24_3", "2024" = "P18_3"),
  ideologia_pri  = c("1997" = "p16_3", "2000" = "p20_3", "2003" = "p20_2", "2006" = "p11b", "2009" = "p11b", "2012" = "p18_2", "2015" = "p20b", "2018" = "P22_2", "2021" = "P24_2", "2024" = "P18_2"),
  ideologia_pt   = c("1997" = "p16_5", "2000" = "p20_5", "2003" = "p20_5", "2006" = "p11e", "2009" = "p11e", "2012" = "p18_5", "2015" = "p20e", "2018" = "P22_5", "2021" = "P24_6", "2024" = "P18_6"),
  ideologia_pvem = c("1997" = "p16_6", "2000" = "p20_6", "2003" = "p20_4", "2006" = "p11d", "2009" = "p11d", "2012" = "p18_4", "2015" = "p20d", "2018" = "P22_4", "2021" = "P24_5", "2024" = "P18_5")
))

# 2018 almacena las 5 ideology_<partido> con codigos 1-11 (codigo 1 =
# respuesta sustantiva "0", ..., codigo 11 = respuesta sustantiva "10";
# 12/13/14 = "no lo conozco lo suficiente"/NS/NC) en vez de 0-10 directo
# como el resto de las olas -- confirmado contra la hoja Codigos del
# inventario. procesar_ola() resta el offset ANTES de validar 0-10.
escalas_0_10_offsets <- list(
  ideologia_pan  = c("2018" = 1),
  ideologia_prd  = c("2018" = 1),
  ideologia_pri  = c("2018" = 1),
  ideologia_pt   = c("2018" = 1),
  ideologia_pvem = c("2018" = 1)
)

# --- Fase 3 (subgrupo "Elecciones/opinion publica"): tres conceptos mas que
# reusan el mismo mecanismo "escala acotada conservada tal cual (o
# invertida)" que ideologia/evaluacion de partidos, pero con un rango propio
# (no 0-10) y, en dos casos, inversion de escala. Ver escalas_0_10_rango y
# escalas_0_10_invertir abajo.
escalas_0_10 <- c(escalas_0_10, list(
  limpieza_electoral      = c("1997" = "p2",  "2000" = "p5",  "2003" = "p31", "2006" = "p76", "2009" = "p66", "2012" = "p46", "2015" = "p49", "2018" = "P33", "2021" = "P19", "2024" = "P11"),
  satisfaccion_democracia = c("1997" = "p1",  "2000" = "p4",  "2003" = "p8",  "2006" = "p19", "2009" = "p19", "2012" = "p22", "2015" = "p23", "2018" = "p28", "2021" = "P29", "2024" = "P24"),
  asistencia_religiosa    = c("1997" = "se26","2000" = "se24","2003" = "s24", "2006" = "ps24","2009" = "ps24","2012" = "s28", "2015" = "ps20","2018" = "S13", "2021" = "S13", "2024" = "S12")
))

# `escalas_0_10_rango`: rango valido por concepto (min,max). Si un concepto
# no aparece aqui, se usa 0:10 (default, sin cambios para ideologia_lr/
# eval_*/ideologia_<partido>).
#   - limpieza_electoral: escala 1-5 de la pregunta "que tan limpia fue la
#     eleccion" (1=no limpia, 5=limpia). OJO: en 2003/2006/2018 el .dta NO
#     trae etiquetas de valor Stata para los codigos 2/3/4 (ni siquiera para
#     los extremos 1/5 en esos tres anios) -- la ordinalidad 1..5 se asume
#     por diseno de la pregunta (tarjeta 1-5), no esta confirmada por
#     etiqueta directa en esos anios. Ver ENEM_candidatos_armonizacion_1997_2024.xlsx.
#   - satisfaccion_democracia: escala 1-4 (ver invertir abajo).
#   - asistencia_religiosa: escala 1-6 (ver invertir abajo). Los codigos
#     especiales de no-respuesta caen fuera de 1:6 en todos los anios
#     (incluido 2018, que usa 7/8 en vez de 8/9 -- el mecanismo de rango los
#     excluye igual sin necesitar un caso especial). Tres anios (2003, 2006,
#     2009) tambien tienen un codigo residual sin etiqueta (0 o 999) fuera
#     de 1:6 que igualmente se descarta a NA por el mismo mecanismo; su
#     significado exacto (posible "no aplica") queda pendiente de confirmar
#     contra el .dta crudo.
escalas_0_10_rango <- list(
  limpieza_electoral      = c(1L, 5L),
  satisfaccion_democracia = c(1L, 4L),
  asistencia_religiosa    = c(1L, 6L)
)

# `escalas_0_10_invertir`: por concepto, vector nombrado por anio (TRUE si
# ese anio debe invertirse para dejar "mayor valor = mas del concepto").
#   - satisfaccion_democracia: el original viene 1=Muy satisfecho...4=Nada
#     satisfecho en las 10 olas (misma direccion siempre) -- se invierte
#     siempre para que 4 = Muy satisfecho. (1997/2000 llaman al nivel 2
#     "Regularmente satisfecho" en vez de "Satisfecho"; no cambia el orden,
#     solo la conexion semantica del nivel.)
#   - asistencia_religiosa: 1997/2000 vienen 1=Diario(mas frecuente)...
#     6=Nunca(menos frecuente) -- se invierten. 2003 en adelante YA vienen en
#     la direccion correcta (1=Nunca...6=Una o mas veces a la semana) -- no
#     se invierten.
escalas_0_10_invertir <- list(
  satisfaccion_democracia = c("1997" = TRUE, "2000" = TRUE, "2003" = TRUE, "2006" = TRUE, "2009" = TRUE,
                               "2012" = TRUE, "2015" = TRUE, "2018" = TRUE, "2021" = TRUE, "2024" = TRUE),
  asistencia_religiosa    = c("1997" = TRUE, "2000" = TRUE, "2003" = FALSE, "2006" = FALSE, "2009" = FALSE,
                               "2012" = FALSE, "2015" = FALSE, "2018" = FALSE, "2021" = FALSE, "2024" = FALSE)
)

# --- pid_partido (identificacion partidista) -----------------------------
# A diferencia de los conceptos "escala 0-10" de arriba, esta es una
# variable CATEGORICA reconstruida a partir del diseno de pregunta de cada
# ola, no un simple mapeo de nombre de columna (ver ENEM_candidatos_armonizacion_1997_2024.xlsx,
# hoja Resumen, concepto "pid": "Reconstruir desde originales y filtros;
# usar etiquetas de partido, no apilar codigos b").
#
#   - 1997-2012 ("filtro"): dos preguntas -- un filtro binario ("simpatiza
#     con algun partido? Si/No/NS/NC") y, SOLO si contesto "Si", una
#     pregunta abierta de "con cual partido" (se usa la primera mencion si
#     nombro varios). Confirmado por crosstab directo contra los .dta de
#     cada ola: quienes contestan "No" al filtro SIEMPRE quedan sin dato en
#     la variable de partido (sistema-perdido en la mayoria de las olas;
#     codigo centinela propio -- 0 en 2003, 998 en 2009 -- en vez de
#     sistema-perdido en esas dos). Por eso hay que leer el filtro, no solo
#     la variable de partido: es la unica forma de distinguir "Ninguno"
#     (contesto "No" al filtro) de "NS/NC" (no supo/no contesto el filtro
#     mismo) -- la variable de partido por si sola no lo permite de forma
#     consistente entre anios.
#   - 2015-2024 ("directo"): una sola pregunta de bateria ("se considera
#     panista, priista, perredista, ... o de otro partido, mucho o algo")
#     que YA incluye Otro/Ninguno/NS/NC como categorias explicitas de la
#     misma variable -- no hay filtro separado que leer.
#
# En ambos casos se colapsa a una columna categorica pid_partido con
# valores PAN/PRI/PRD/PVEM/PT/MC/MORENA/Otro/Ninguno/NA (NS/NC). "Otro"
# agrupa partidos minoritarios que NO son comparables entre olas (distinta
# composicion cada anio: PC/PPS/PDM en 1997, PARM/PCD/PDS en 2000, etc). La
# granularidad tampoco es simetrica entre disenos: en 1997-2012 la primera
# mencion SI puede resolver directo a PT/PVEM/MC; en 2015-2024 cualquier
# partido fuera de PAN/PRI/PRD/MORENA en la pregunta principal cae en
# "Otro" sin desagregar (el cuestionario detalla cual en una pregunta de
# seguimiento -- P5_1 en 2018, 3.1 en 2021 -- que no se usa aqui). NO se
# usan las variables pid<anio>b (version ya colapsada por el proveedor): el
# propio inventario advierte que el significado de sus codigos cambia entre
# olas (3 = PRD en pid1997b, 3 = MORENA en pid2021b).
pid_specs <- list(
  "1997" = list(tipo = "filtro", filtro = "p3", folup = "p3_1", si = 1, no = 2, ns_nc = c(3, 4),
                mapa = c(`1` = "PAN", `2` = "PRI", `3` = "PRD", `4` = "PT", `5` = "PVEM",
                         `6` = "Otro", `7` = "Otro", `8` = "Otro", `9` = "Otro", `10` = NA, `11` = NA)),
  "2000" = list(tipo = "filtro", filtro = "p6", folup = "p6a", si = 1, no = 2, ns_nc = c(3, 4),
                mapa = c(`1` = "PAN", `2` = "PRI", `3` = "PRD", `4` = "PT", `5` = "PVEM",
                         `6` = "Otro", `7` = "Otro", `8` = "Otro", `9` = "Otro", `10` = NA, `11` = NA)),
  "2003" = list(tipo = "filtro", filtro = "p18", folup = "p18a_1", si = 1, no = 2, ns_nc = c(8, 9),
                mapa = c(`0` = NA, `1` = "PAN", `2` = "PRI", `3` = "PRD", `4` = "PVEM", `5` = "PT",
                         `6` = "MC", `7` = "Otro", `8` = "Otro", `9` = "Otro", `10` = "Otro",
                         `11` = "Otro", `13` = "Otro", `98` = NA, `99` = NA)),
  "2006" = list(tipo = "filtro", filtro = "p20", folup = "p20a_1", si = 1, no = 2, ns_nc = c(8, 9),
                mapa = c(`1` = "PAN", `2` = "PRI", `3` = "PRD", `4` = "PVEM", `5` = "PT",
                         `6` = "MC", `7` = "Otro", `8` = "Otro", `9` = "Otro", `97` = NA, `98` = NA)),
  "2009" = list(tipo = "filtro", filtro = "p20", folup = "p20a_1", si = 1, no = 2, ns_nc = c(8, 9),
                mapa = c(`1` = "PAN", `2` = "PRI", `3` = "PRD", `4` = "PVEM", `5` = "PT",
                         `6` = "MC", `7` = "Otro", `8` = "Otro", `9` = "Otro", `97` = NA, `98` = NA, `998` = NA)),
  "2012" = list(tipo = "filtro", filtro = "p23", folup = "p23_a1", si = 1, no = 2, ns_nc = c(8, 9),
                mapa = c(`1` = "PAN", `2` = "PRI", `3` = "PRD", `4` = "PVEM", `5` = "PT",
                         `6` = "MC", `7` = "Otro", `8` = "Otro", `98` = NA, `99` = NA)),
  "2015" = list(tipo = "directo", var = "p9",
                mapa = c(`1` = "PAN", `2` = "PAN", `3` = "PRI", `4` = "PRI", `5` = "PRD", `6` = "PRD",
                         `7` = "PVEM", `8` = "PVEM", `9` = "MORENA", `10` = "MORENA",
                         `96` = "Otro", `97` = "Ninguno", `98` = NA, `99` = NA)),
  "2018" = list(tipo = "directo", var = "P5",
                mapa = c(`1` = "PAN", `2` = "PAN", `3` = "PRI", `4` = "PRI", `5` = "PRD", `6` = "PRD",
                         `9` = "MORENA", `10` = "MORENA", `96` = "Otro", `97` = "Ninguno", `98` = NA, `99` = NA)),
  "2021" = list(tipo = "directo", var = "P3",
                mapa = c(`1` = "PAN", `2` = "PAN", `3` = "PRI", `4` = "PRI", `5` = "PRD", `6` = "PRD",
                         `7` = "MORENA", `8` = "MORENA", `96` = "Otro", `97` = "Ninguno", `98` = NA, `99` = NA)),
  "2024" = list(tipo = "directo", var = "P4",
                mapa = c(`1` = "PAN", `2` = "PAN", `3` = "PRI", `4` = "PRI", `5` = "PRD", `6` = "PRD",
                         `7` = "MORENA", `8` = "MORENA", `96` = "Otro", `97` = "Ninguno", `98` = NA, `99` = NA))
)

# --- Fase 3 (subgrupos "Demografia", "Conocimiento politico", y el resto de
# "Elecciones/opinion publica"/"Religion-trabajo" que no son escala
# acotada): conceptos CATEGORICOS reconstruidos por un mapa fijo de codigo
# crudo -> categoria armonizada, por anio. Mecanismo generico en
# procesar_ola() (generaliza el patron "directo" ya usado para pid_partido).
# `recodes_categoricas[[concepto]][[anio]] <- list(var = <nombre variable
# original>, mapa = c(`codigo` = "Categoria", ...), notas = "...")`; un anio
# ausente de la lista de un concepto se trata como no disponible ese anio
# (ver el caso de conocimiento_gobernador, con solo 6/10 anios).
recodes_categoricas <- list()

# --- etnia --------------------------------------------------------------
# Regla del inventario: "Conservar indigena/mestizo/blanco/otro y categorias
# nuevas; no suponer equivalencia del residual" (ENEM_candidatos_armonizacion_1997_2024.xlsx).
notas_etnia <- "Categoria armonizada: Indigena/Mestizo/Blanco/Afrodescendiente (solo 2024)/Otro. 'Otro' agrupa categorias residuales NO comparables entre anios (composicion distinta cada ola -- ver hoja Resumen: 'no asignar equivalencia del residual'). Afrodescendiente es explicito solo desde 2024; en anios anteriores la autoidentificacion afrodescendiente, si la hay, queda indistinguible dentro de 'Otro'."
recodes_categoricas$etnia <- list(
  "1997" = list(var = "se29",  mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `4` = "Otro", `5` = NA), notas = notas_etnia),
  "2000" = list(var = "se22",  mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `4` = "Otro", `5` = NA, `10` = "Otro", `11` = "Otro"), notas = notas_etnia),
  "2003" = list(var = "s22",   mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `4` = "Otro", `5` = "Otro", `99` = NA), notas = notas_etnia),
  "2006" = list(var = "ps22",  mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `4` = "Otro", `96` = "Otro", `97` = NA, `99` = NA), notas = notas_etnia),
  "2009" = list(var = "ps22",  mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `4` = "Otro", `5` = "Otro", `6` = "Otro", `7` = "Otro", `96` = "Otro", `97` = NA, `99` = NA), notas = notas_etnia),
  "2012" = list(var = "s32",   mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `99` = NA), notas = paste(notas_etnia, "2012 no tiene categoria 'Otro' explicita en el cuestionario: todo caso valido cae en Indigena/Mestizo/Blanco.")),
  "2015" = list(var = "ps26",  mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `4` = "Otro", `97` = NA, `99` = NA), notas = notas_etnia),
  "2018" = list(var = "S16_1", mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `96` = "Otro", `99` = NA), notas = notas_etnia),
  "2021" = list(var = "S16",   mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `4` = "Otro", `98` = NA, `99` = NA), notas = notas_etnia),
  "2024" = list(var = "S15",   mapa = c(`1` = "Indigena", `2` = "Mestizo", `3` = "Blanco", `4` = "Afrodescendiente", `5` = "Otro", `98` = NA, `99` = NA), notas = notas_etnia)
)

# --- escolaridad ----------------------------------------------------------
# Regla: "Construir niveles desde etiquetas originales; documentar inclusion
# de sin estudios." Se colapsa incompleta+completa dentro de cada bloque
# (Ninguna/Primaria/Secundaria/Preparatoria/Universidad_o_mas) precisamente
# para evitar la ambiguedad de que el codigo "Universidad incompleta" existe
# como propio en 1997-2009 pero desaparece del cuestionario desde 2012 (no
# se puede distinguir "universidad incompleta" de "no fue a la universidad"
# en 2012+): al resolver por bloque completo desde los codigos crudos (no
# reusando el recode "existente" del proveedor, cuyo tratamiento de ese
# codigo no quedo confirmado), el bloque "Universidad_o_mas" incluye
# incompleta+completa+maestria+doctorado en TODOS los anios por igual.
notas_escol <- "Niveles ordinales por bloque (Ninguna/Primaria/Secundaria/Preparatoria/Universidad_o_mas), colapsando incompleta+completa (y maestria/doctorado en Universidad_o_mas) dentro de cada bloque en los 10 anios, para evitar la ambiguedad de que 'Universidad incompleta' es un codigo propio en 1997-2009 pero no existe en el cuestionario desde 2012."
recodes_categoricas$escolaridad <- list(
  "1997" = list(var = "escol", mapa = c(`1` = "Ninguna", `2` = "Primaria", `3` = "Primaria", `4` = "Secundaria", `5` = "Secundaria", `6` = "Preparatoria", `7` = "Preparatoria", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas"), notas = notas_escol),
  "2000" = list(var = "escol", mapa = c(`1` = "Ninguna", `2` = "Primaria", `3` = "Primaria", `4` = "Secundaria", `5` = "Secundaria", `6` = "Preparatoria", `7` = "Preparatoria", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas"), notas = notas_escol),
  "2003" = list(var = "s3",    mapa = c(`1` = "Ninguna", `2` = "Primaria", `3` = "Primaria", `4` = "Secundaria", `5` = "Secundaria", `6` = "Preparatoria", `7` = "Preparatoria", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas", `98` = NA, `99` = NA), notas = notas_escol),
  "2006" = list(var = "ps3",   mapa = c(`1` = "Ninguna", `2` = "Primaria", `3` = "Primaria", `4` = "Secundaria", `5` = "Secundaria", `6` = "Preparatoria", `7` = "Preparatoria", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas", `98` = NA, `99` = NA), notas = notas_escol),
  "2009" = list(var = "ps3",   mapa = c(`1` = "Ninguna", `2` = "Primaria", `3` = "Primaria", `4` = "Secundaria", `5` = "Secundaria", `6` = "Preparatoria", `7` = "Preparatoria", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas", `98` = NA, `99` = NA), notas = notas_escol),
  "2012" = list(var = "s3",    mapa = c(`1` = "Primaria", `2` = "Primaria", `3` = "Secundaria", `4` = "Secundaria", `5` = "Preparatoria", `6` = "Preparatoria", `7` = "Universidad_o_mas", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas", `96` = "Ninguna", `98` = NA, `99` = NA), notas = notas_escol),
  "2015" = list(var = "ps3",   mapa = c(`1` = "Primaria", `2` = "Primaria", `3` = "Secundaria", `4` = "Secundaria", `5` = "Preparatoria", `6` = "Preparatoria", `7` = "Universidad_o_mas", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas", `96` = "Ninguna", `97` = NA, `98` = NA, `99` = NA, `998` = NA), notas = notas_escol),
  "2018" = list(var = "S3",    mapa = c(`1` = "Primaria", `2` = "Primaria", `3` = "Secundaria", `4` = "Secundaria", `5` = "Preparatoria", `6` = "Preparatoria", `7` = "Universidad_o_mas", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas", `96` = "Ninguna", `98` = NA, `99` = NA), notas = notas_escol),
  "2021" = list(var = "PC",    mapa = c(`1` = "Primaria", `2` = "Primaria", `3` = "Secundaria", `4` = "Secundaria", `5` = "Preparatoria", `6` = "Preparatoria", `7` = "Universidad_o_mas", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas", `96` = "Ninguna", `98` = NA, `99` = NA), notas = notas_escol),
  "2024" = list(var = "S3",    mapa = c(`1` = "Primaria", `2` = "Primaria", `3` = "Secundaria", `4` = "Secundaria", `5` = "Preparatoria", `6` = "Preparatoria", `7` = "Universidad_o_mas", `8` = "Universidad_o_mas", `9` = "Universidad_o_mas", `96` = "Ninguna", `98` = NA, `99` = NA), notas = notas_escol)
)

# --- estado_civil -----------------------------------------------------
# Regla: "Mapa por etiquetas a categorias comunes, conservando original."
notas_civil <- "Categorias: Soltero/Casado_UnionLibre/Divorciado_Separado/Viudo. En 1997-2009 'Casado' y 'Union libre' son codigos separados en el original y se agrupan aqui en 'Casado_UnionLibre' para poder comparar contra 2012+, donde el cuestionario ya los fusiona en una sola categoria ('Casado o en union libre'). OJO: el codigo numerico de cada categoria TAMBIEN cambia de orden entre 1997-2009 y 2012+ (no solo la fusion Casado/Union libre) -- el mapeo es por texto de etiqueta, nunca por codigo crudo compartido entre las dos eras."
recodes_categoricas$estado_civil <- list(
  "1997" = list(var = "se20", mapa = c(`1` = "Soltero", `2` = "Casado_UnionLibre", `3` = "Divorciado_Separado", `4` = "Viudo", `5` = "Casado_UnionLibre", `6` = NA), notas = notas_civil),
  "2000" = list(var = "se16", mapa = c(`1` = "Soltero", `2` = "Casado_UnionLibre", `3` = "Divorciado_Separado", `4` = "Viudo", `5` = "Casado_UnionLibre", `6` = NA), notas = notas_civil),
  "2003" = list(var = "s16",  mapa = c(`1` = "Soltero", `2` = "Casado_UnionLibre", `3` = "Divorciado_Separado", `4` = "Viudo", `5` = "Casado_UnionLibre", `9` = NA), notas = notas_civil),
  "2006" = list(var = "ps16", mapa = c(`1` = "Soltero", `2` = "Casado_UnionLibre", `3` = "Divorciado_Separado", `4` = "Viudo", `5` = "Casado_UnionLibre", `9` = NA), notas = notas_civil),
  "2009" = list(var = "ps16", mapa = c(`1` = "Soltero", `2` = "Casado_UnionLibre", `3` = "Divorciado_Separado", `4` = "Viudo", `5` = "Casado_UnionLibre", `9` = NA), notas = notas_civil),
  "2012" = list(var = "s4",   mapa = c(`1` = "Casado_UnionLibre", `2` = "Viudo", `3` = "Divorciado_Separado", `4` = "Soltero", `8` = NA, `9` = NA), notas = notas_civil),
  "2015" = list(var = "ps4",  mapa = c(`1` = "Casado_UnionLibre", `2` = "Viudo", `3` = "Divorciado_Separado", `4` = "Soltero", `8` = NA, `9` = NA, `97` = NA, `998` = NA), notas = notas_civil),
  "2018" = list(var = "S4",   mapa = c(`1` = "Casado_UnionLibre", `2` = "Viudo", `3` = "Divorciado_Separado", `4` = "Soltero", `8` = NA, `9` = NA), notas = notas_civil),
  "2021" = list(var = "S4",   mapa = c(`1` = "Casado_UnionLibre", `2` = "Viudo", `3` = "Divorciado_Separado", `4` = "Soltero", `8` = NA, `9` = NA), notas = notas_civil),
  "2024" = list(var = "S4",   mapa = c(`1` = "Casado_UnionLibre", `2` = "Viudo", `3` = "Divorciado_Separado", `4` = "Soltero", `98` = NA, `99` = NA), notas = notas_civil)
)

# --- religion ---------------------------------------------------------
# Regla: "Usar catolica, otra religion, ninguna; conservar desagregacion
# original." A diferencia de pid_partido (que se reconstruyo desde variables
# crudas porque el inventario documenta bien sus pocos codigos), aqui se
# reutiliza la variable YA recodificada por el proveedor (religion<anio>b),
# que colapsa de forma estable Catolica/Otra/Ninguna en las 10 olas
# (verificado por conteo contra las variables originales de cada anio) --
# la version cruda tiene ~15-28 categorias de denominacion por anio sin un
# listado completo en el inventario, lo que haria muy facil dejar
# denominaciones reales mal clasificadas como "fuera del mapa" (-> NA) por
# error de omision.
# OJO: el nombre exacto religion<anio>b se infiere por analogia con el
# patron de nombres de otras variables ya recodificadas en este dataset
# (p.ej. age<anio>b) -- NO esta confirmado contra el .dta real. Si el
# nombre real difiere, procesar_ola() simplemente marca el anio como no
# disponible (ver incidencias.csv), sin fallar -- confirma/corrige el
# nombre real antes de confiar en esta columna.
notas_religion <- "Reusa la variable ya recodificada por el proveedor (religion<anio>b: 1=Catolica/2=Otra/3=Ninguna, estable en las 10 olas). Nombre de variable INFERIDO por analogia (no confirmado contra el .dta) -- verificar antes de confiar en esta columna."
recodes_categoricas$religion <- list(
  "1997" = list(var = "religion1997b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = notas_religion),
  "2000" = list(var = "religion2000b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = notas_religion),
  "2003" = list(var = "religion2003b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = notas_religion),
  "2006" = list(var = "religion2006b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = paste(notas_religion, "2006: 'Ninguna' equivale aqui a 'insuficientemente especificado' en el original (el proveedor no distingue un codigo propio de 'no tiene religion' ese anio) -- supuesto del proveedor, no una etiqueta directa.")),
  "2009" = list(var = "religion2009b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = paste(notas_religion, "2009: mismo supuesto que 2006 ('Ninguna' = 'insuficientemente especificado' en el original).")),
  "2012" = list(var = "religion2012b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = notas_religion),
  "2015" = list(var = "religion2015b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = notas_religion),
  "2018" = list(var = "religion2018b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = notas_religion),
  "2021" = list(var = "religion2021b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = paste(notas_religion, "2021/2024: el cuestionario ya no pregunta la denominacion detallada, solo Catolica/Otra/Ninguna/NC directo.")),
  "2024" = list(var = "religion2024b", mapa = c(`1` = "Catolica", `2` = "Otra", `3` = "Ninguna"), notas = paste(notas_religion, "2021/2024: el cuestionario ya no pregunta la denominacion detallada, solo Catolica/Otra/Ninguna/NC directo."))
)

# --- econ_retro (evaluacion economica retrospectiva) -------------------
# Regla: "Mejoro / igual / empeoro; intensidad en variable separada."
notas_econ <- "Colapsado a 3 categorias (Mejoro/Igual/Empeoro): 1997/2012/2015 preguntan ya en 3 puntos; 2000/2003/2006/2009/2018/2021/2024 preguntan en 4 puntos separando 'igual de bien'/'igual de mal', que aqui se fusionan en 'Igual' (la distincion bien/mal se pierde; no se genero variable auxiliar de intensidad en esta fase). OJO 2006: ~50% de missing del sistema en esta pregunta (posible version de cuestionario dividida) -- usar con cautela. OJO 2015: ~50% de los casos vienen 'no aplica por version' (bateria dividida) -- la n util efectiva es aprox. la mitad de la muestra ese anio."
recodes_categoricas$econ_retro <- list(
  "1997" = list(var = "p10",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Empeoro", `4` = NA, `5` = NA), notas = notas_econ),
  "2000" = list(var = "p13",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Igual", `4` = "Empeoro", `5` = NA, `6` = NA), notas = notas_econ),
  "2003" = list(var = "p35",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Igual", `4` = "Empeoro", `8` = NA, `9` = NA), notas = notas_econ),
  "2006" = list(var = "p30",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Igual", `4` = "Empeoro", `8` = NA, `9` = NA), notas = notas_econ),
  "2009" = list(var = "p63",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Igual", `4` = "Empeoro", `8` = NA, `9` = NA), notas = notas_econ),
  "2012" = list(var = "p12",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Empeoro", `8` = NA, `9` = NA), notas = notas_econ),
  "2015" = list(var = "p15",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Empeoro", `8` = NA, `9` = NA, `97` = NA), notas = notas_econ),
  "2018" = list(var = "P17",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Igual", `4` = "Empeoro", `8` = NA, `9` = NA), notas = notas_econ),
  "2021" = list(var = "P15",  mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Igual", `4` = "Empeoro", `98` = NA, `99` = NA), notas = notas_econ),
  "2024" = list(var = "P15B", mapa = c(`1` = "Mejoro", `2` = "Igual", `3` = "Igual", `4` = "Empeoro", `98` = NA, `99` = NA), notas = notas_econ)
)

# --- voto_reportado (turnout) -------------------------------------------
# Regla: "Si/no con tipo y ano de eleccion; no confundir no voto con no
# respuesta."
notas_voto <- "Si/No de voto autorreportado. La eleccion referida ALTERNA entre presidencial y legislativa (diputados federales) cada ola: 1997/2003/2009/2015/2021 = legislativa, 2000/2006/2012/2018/2024 = presidencial -- no tratar como una serie continua de 'voto en la ultima eleccion nacional' sin anotar cual cargo se disputaba. El codigo especial 'No tenia edad' (donde existe) se recodifica a NA: no es un reporte de comportamiento de voto, es inelegibilidad."
recodes_categoricas$voto_reportado <- list(
  "1997" = list(var = "p17", mapa = c(`1` = "Si", `2` = "No", `3` = NA, `4` = NA), notas = notas_voto),
  "2000" = list(var = "p1",  mapa = c(`1` = "Si", `2` = "No", `3` = NA, `4` = NA), notas = notas_voto),
  "2003" = list(var = "p3",  mapa = c(`1` = "Si", `2` = "No", `8` = NA, `9` = NA), notas = notas_voto),
  "2006" = list(var = "pi",  mapa = c(`1` = "Si", `2` = "No", `3` = NA, `8` = NA, `9` = NA), notas = notas_voto),
  "2009" = list(var = "pi",  mapa = c(`1` = "Si", `2` = "No", `3` = NA, `8` = NA, `9` = NA), notas = notas_voto),
  "2012" = list(var = "p3",  mapa = c(`1` = "Si", `2` = "No", `3` = NA, `8` = NA, `9` = NA), notas = notas_voto),
  "2015" = list(var = "p3",  mapa = c(`1` = "Si", `2` = "No", `3` = NA, `8` = NA, `9` = NA, `97` = NA), notas = notas_voto),
  "2018" = list(var = "P9",  mapa = c(`1` = "Si", `2` = "No", `3` = NA, `8` = NA, `9` = NA), notas = notas_voto),
  "2021" = list(var = "P16", mapa = c(`1` = "Si", `2` = "No", `98` = NA, `99` = NA), notas = notas_voto),
  "2024" = list(var = "P8",  mapa = c(`1` = "Si", `2` = "No", `3` = NA, `98` = NA, `99` = NA), notas = notas_voto)
)

# --- actividad_principal --------------------------------------------------
# Regla: "Ocupado / desocupado / fuera de fuerza laboral solo con definicion
# y seguimientos consistentes."
notas_actividad <- "Clasificacion tipo OIT en 3 categorias: Ocupado (trabajo/tiene trabajo pero no trabajo esa semana), Desocupado (busca trabajo activamente), Fuera_fuerza_laboral (hogar/estudiante/jubilado/incapacitado). Codigos 'Otro'/ocupaciones ambiguas (agricultor, renta de autos en 2006; 'Otro' generico con n no trivial en 2021/2024) se recodifican a NA por no poder clasificarse con certeza en ninguna de las 3 categorias -- no se fuerzan a 'Fuera_fuerza_laboral'."
recodes_categoricas$actividad_principal <- list(
  "1997" = list(var = "se4", mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `10` = NA, `97` = NA, `98` = NA, `99` = NA), notas = notas_actividad),
  "2000" = list(var = "se4", mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `10` = NA, `97` = NA, `98` = NA, `99` = NA), notas = notas_actividad),
  "2003" = list(var = "s4",  mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `98` = NA, `99` = NA), notas = notas_actividad),
  "2006" = list(var = "ps4", mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `8` = NA, `9` = NA, `10` = NA, `98` = NA, `99` = NA), notas = notas_actividad),
  "2009" = list(var = "ps4", mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `98` = NA, `99` = NA), notas = notas_actividad),
  "2012" = list(var = "s8",  mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `8` = NA, `9` = NA, `98` = NA, `99` = NA), notas = notas_actividad),
  "2015" = list(var = "ps5", mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `8` = NA, `97` = NA, `98` = NA, `99` = NA, `998` = NA), notas = notas_actividad),
  "2018" = list(var = "S7",  mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `9` = NA, `10` = NA), notas = paste(notas_actividad, "2018: codigos de NS/NC son 9/10 (no 8/9 ni 98/99 como el resto de las olas).")),
  "2021" = list(var = "S7",  mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `8` = NA, `98` = NA, `99` = NA), notas = notas_actividad),
  "2024" = list(var = "S6",  mapa = c(`1` = "Ocupado", `2` = "Ocupado", `3` = "Fuera_fuerza_laboral", `4` = "Fuera_fuerza_laboral", `5` = "Fuera_fuerza_laboral", `6` = "Desocupado", `7` = "Fuera_fuerza_laboral", `8` = NA, `98` = NA, `99` = NA), notas = notas_actividad)
)

# --- conocimiento_camaras -------------------------------------------------
# Regla: "Correcto = diputados y senadores; separar incorrecto y NS/NC."
# Diferencias del inventario: "1997 separa menciones; olas recientes pueden
# almacenar correcto/incorrecto. 2018 contiene duplicados" -- esta ultima
# nota se investigo en esta fase contra el inventario (ids unicos en 2018,
# sin variable ni filas duplicadas visibles ahi) sin poder confirmar a que
# se refiere exactamente; queda pendiente de revisar contra el .dta crudo de
# 2018 antes de confiar del todo en ese anio.
notas_camaras <- "Correcto/Incorrecto sobre que camaras integran el Congreso (respuesta completa = Diputados y Senadores). Nota pendiente del inventario ('2018 contiene duplicados') no se pudo corroborar en esta fase -- revisar directo contra el .dta crudo de 2018."
notas_camaras_1997 <- paste(notas_camaras, "1997: se usa unicamente p52_1 ('mencion de Diputados y Senadores') de una bateria de 4 sub-variables (p52_1..p52_4). OJO: esta sub-variable NO tiene codigo NS/NC propio (solo 1=Si mencion/2=No mencion) -- 'Incorrecto' en 1997 MEZCLA respuesta incorrecta real con no sabe/no contesto, sin forma de separarlos.")
notas_camaras_2000 <- paste(notas_camaras, "2000: variable pre-codificada binaria por el proveedor (0=Incorrecto/1=Correcto), sin codigo NS/NC propio -- misma limitacion que 1997: 'Incorrecto' mezcla respuesta incorrecta real con no sabe/no contesto.")
recodes_categoricas$conocimiento_camaras <- list(
  "1997" = list(var = "p52_1",  mapa = c(`1` = "Correcto", `2` = "Incorrecto"), notas = notas_camaras_1997),
  "2000" = list(var = "pcam",   mapa = c(`0` = "Incorrecto", `1` = "Correcto"), notas = notas_camaras_2000),
  "2003" = list(var = "p25",    mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = "Incorrecto", `4` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_camaras),
  "2006" = list(var = "p27",    mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = "Incorrecto", `4` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_camaras),
  "2009" = list(var = "p24",    mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = "Incorrecto", `4` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_camaras),
  "2012" = list(var = "p69",    mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = "Incorrecto", `4` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_camaras),
  "2015" = list(var = "p67",    mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = "Incorrecto", `4` = "Incorrecto", `8` = NA, `9` = NA, `97` = NA), notas = notas_camaras),
  "2018" = list(var = "CAMARAS",mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = "Incorrecto", `4` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_camaras),
  "2021" = list(var = "P47",    mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = "Incorrecto", `4` = "Incorrecto", `98` = NA, `99` = NA), notas = notas_camaras),
  "2024" = list(var = "P26_1",  mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = "Incorrecto", `4` = "Incorrecto", `98` = NA, `99` = NA), notas = notas_camaras)
)

# --- conocimiento_diputado_termino ----------------------------------------
# Regla: "Tres anios = correcto; no confundir codigo 1 con un anio."
notas_termino <- "Correcto/Incorrecto sobre la duracion del cargo de diputado federal (respuesta correcta = 3 anios)."
notas_termino_1997 <- paste(notas_termino, "1997: a diferencia de conocimiento_camaras el mismo anio, esta pregunta (p53) SI tiene codigo NS propio (3=Ns) ademas de NC (4) -- aqui SI se puede distinguir respuesta incorrecta de no sabe/no contesto; no aplica la misma limitacion que camaras 1997.")
notas_termino_2000 <- paste(notas_termino, "2000: variable pre-codificada binaria por el proveedor (0=Incorrecto/1=Correcto), sin codigo NS/NC propio -- misma limitacion que conocimiento_camaras 2000 (mezcla incorrecto real con no sabe/no contesto).")
recodes_categoricas$conocimiento_diputado_termino <- list(
  "1997" = list(var = "p53",       mapa = c(`1` = "Correcto", `2` = "Incorrecto", `3` = NA, `4` = NA), notas = notas_termino_1997),
  "2000" = list(var = "pdip",      mapa = c(`0` = "Incorrecto", `1` = "Correcto"), notas = notas_termino_2000),
  "2003" = list(var = "p26",       mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_termino),
  "2006" = list(var = "p27a",      mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_termino),
  "2009" = list(var = "p24a",      mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_termino),
  "2012" = list(var = "p70",       mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_termino),
  "2015" = list(var = "p68",       mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA, `97` = NA), notas = notas_termino),
  "2018" = list(var = "DIPUTADOS", mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_termino),
  "2021" = list(var = "P48",       mapa = c(`1` = "Correcto", `2` = "Incorrecto", `98` = NA, `99` = NA), notas = notas_termino),
  "2024" = list(var = "P26_2",     mapa = c(`1` = "Correcto", `2` = "Incorrecto", `98` = NA, `99` = NA), notas = notas_termino)
)

# --- conocimiento_gobernador (SOLO 6 de 10 anios, deliberadamente) --------
# Regla: "Usar indicador de conocimiento cuando exista; validar textos por
# estado y fecha."
# Implementado UNICAMENTE en los 6 anios donde el proveedor ya entrega un
# indicador Correcto/Incorrecto pre-validado. 1997/2000/2003/2018 solo
# traen el nombre abierto mencionado por el entrevistado (decenas de
# codigos distintos por persona/entidad), y este paquete no cuenta con un
# catalogo de gobernadores por estado y fecha para validar esas respuestas
# -- se prefirio dejarlos como no disponible en vez de adivinar la
# correccion (mismo criterio que llevo a excluir esos anios de este
# concepto desde el diseno, no un descuido).
notas_gobernador <- "Correcto/Incorrecto sobre el nombre del gobernador (o Jefe de Gobierno en CDMX) del estado del entrevistado. Implementado SOLO en 2006/2009/2012/2015/2021/2024 (los unicos anios con indicador pre-validado por el proveedor). 1997/2000/2003/2018 quedan deliberadamente NO disponibles: son respuesta abierta (nombre mencionado) sin catalogo de gobernadores-por-estado-y-fecha disponible en este paquete para validar."
recodes_categoricas$conocimiento_gobernador <- list(
  "2006" = list(var = "p27b", mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_gobernador),
  "2009" = list(var = "p24b", mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_gobernador),
  "2012" = list(var = "p71",  mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA), notas = notas_gobernador),
  "2015" = list(var = "p69",  mapa = c(`1` = "Correcto", `2` = "Incorrecto", `8` = NA, `9` = NA, `97` = NA), notas = notas_gobernador),
  "2021" = list(var = "P49",  mapa = c(`1` = "Correcto", `2` = "Incorrecto", `98` = NA, `99` = NA), notas = notas_gobernador),
  "2024" = list(var = "P26_3",mapa = c(`1` = "Correcto", `2` = "Incorrecto", `98` = NA, `99` = NA), notas = notas_gobernador)
)

# --- tipo_seccion (urban) -- NO IMPLEMENTADO EN ESTA FASE -----------------
# Regla: "Rural/mixta/urbana por etiqueta; no asignar mixta en olas donde no
# se distingue." Diferencias: "1997/2000: recodificadas 0 rural, 1 urbana.
# Desde 2003: 1 rural, 2 mixta, 3 urbana."
# Se investigaron los CODIGOS (confirmados: 1997/2000 solo Rural/Urbana con
# el mismo digito significando lo opuesto que 2003+; desde 2003, Rural/
# Mixta/Urbana con el digito 1=Mixta,2=Rural,3=Urbana en el original antes
# de re-numerar), PERO el nombre real de la variable fuente NO esta
# confirmado en el inventario para 7 de los 10 anios (solo la ETIQUETA
# Stata "TIPO" se confirmo para 2003/2006/2021, que no es lo mismo que el
# nombre de columna) -- el propio inventario marca el metodo de
# localizacion como "No localizado automaticamente" para este concepto en
# todos los anios. Adivinar un nombre de columna aqui tiene un riesgo real
# de colisionar con una variable no relacionada y producir datos
# silenciosamente incorrectos (a diferencia de otros conceptos, donde un
# nombre equivocado simplemente marca el anio como no disponible). Por eso
# se deja PENDIENTE: falta confirmar el nombre real de columna por anio
# contra los .dta crudos antes de implementarlo con el mismo mecanismo de
# recodes_categoricas ya construido (el mapeo de codigos ya esta resuelto,
# ver arriba).

source("data-raw/procesar_ola.R")

resultados <- lapply(names(mapa_columnas), function(anio_chr) {
  spec <- mapa_columnas[[anio_chr]]
  procesar_ola(
    anio = as.integer(anio_chr),
    # OJO Dan: en tu maquina datos_stata/ vive un nivel arriba del paquete
    # (C:/enemR-project/datos_stata, hermano de C:/enemR-project/rENEM), no
    # dentro de rENEM/ -- por eso el "..". Si algun dia mueves esa carpeta
    # adentro de rENEM/, quita el "..".
    ruta = file.path("..", "datos_stata", spec$archivo),
    spec = spec,
    isco_cols = isco_cols,
    escalas_0_10 = escalas_0_10,
    escalas_0_10_offsets = escalas_0_10_offsets,
    pid_specs = pid_specs,
    escalas_0_10_rango = escalas_0_10_rango,
    escalas_0_10_invertir = escalas_0_10_invertir,
    recodes_categoricas = recodes_categoricas
  )
})

enem_panel <- do.call(rbind, lapply(resultados, `[[`, "armonizado"))
enem_codebook <- do.call(rbind, lapply(resultados, `[[`, "crosswalk"))
incidencias <- do.call(rbind, lapply(resultados, `[[`, "incidencias"))

rownames(enem_panel) <- NULL
rownames(enem_codebook) <- NULL
rownames(incidencias) <- NULL

usethis::use_data(enem_panel, overwrite = TRUE, compress = "xz")
usethis::use_data(enem_codebook, overwrite = TRUE, compress = "xz")

# incidencias no se distribuye con el paquete, es solo para revisar al
# regenerar los datos
write.csv(incidencias, "data-raw/incidencias.csv", row.names = FALSE)

cat(sprintf("enem_panel: %d filas, %d olas\n", nrow(enem_panel), length(unique(enem_panel$anio))))
cat(sprintf("incidencias encontradas: %d (ver data-raw/incidencias.csv)\n", nrow(incidencias)))
