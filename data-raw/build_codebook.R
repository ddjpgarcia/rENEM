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

source("data-raw/procesar_ola.R")

resultados <- lapply(names(mapa_columnas), function(anio_chr) {
  spec <- mapa_columnas[[anio_chr]]
  procesar_ola(
    anio = as.integer(anio_chr),
    ruta = file.path("datos_stata", spec$archivo), # ajusta si tu carpeta datos_stata/ vive en otro lado
    spec = spec,
    isco_cols = isco_cols,
    escalas_0_10 = escalas_0_10
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
