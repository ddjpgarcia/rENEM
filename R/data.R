#' Panel armonizado de ENEM (1997-2024)
#'
#' El panel armonizado pequeño que se distribuye con el paquete y carga
#' [enem_load()]: variables comunes a las 10 olas (sexo, edad agrupada,
#' pesos de diseño y final, ocupación ISCO-08, y geografía/fecha/folio
#' cuando existen). Ver [enem_codebook()] para el crosswalk completo de qué
#' variable original corresponde a cada columna aquí, y la sección
#' "Advertencias importantes" de [enem_load()] antes de usar
#' `municipio_original`, `fecha_original` o `folio_original`.
#'
#' @format Un data frame con una fila por entrevistado y las columnas:
#' \describe{
#'   \item{anio}{Año de la ola (1997-2024).}
#'   \item{mujer}{Indicador (0/1) de sexo, recodificado desde `female<año>`.}
#'   \item{edad_grupo}{Edad agrupada (1-4), recodificada desde `age<año>b`.}
#'   \item{peso_diseno}{Ponderador de diseño (`PONDERADOR` original de cada ola).}
#'   \item{peso_final}{Ponderador final, con ajustes de no respuesta y
#'     postestratificación cuando aplica (`PONDFIN` original de cada ola).}
#'   \item{municipio_original}{Código de municipio tal cual venía en la ola
#'     original (no armonizado entre años; `NA` si esa ola no lo trae).}
#'   \item{fecha_original}{Fecha de entrevista tal cual venía en la ola
#'     original (no armonizada entre años; `NA` si esa ola no la trae).}
#'   \item{folio_original}{Folio tal cual venía en la ola original. NO es un
#'     identificador único de respondiente salvo en 2024 -- ver
#'     `folio_es_id_unico`.}
#'   \item{folio_es_id_unico}{Lógico. `TRUE` solo para 2024, donde `folio`
#'     sí identifica de forma única a cada entrevistado. Para una llave
#'     única en las 10 olas, usa `id_ola`/`id_panel` en vez de `folio`.}
#'   \item{pdte_acuerdo}{Aprobación presidencial, escala de 4 puntos
#'     orientada para que mayor valor = mayor aprobación: 1=Muy en
#'     desacuerdo, 2=Algo en desacuerdo, 3=Algo de acuerdo, 4=Muy de acuerdo
#'     con la manera como está gobernando el presidente. `NA` si no hubo
#'     respuesta. El original venía en orden inverso (1=Muy de acuerdo); se
#'     invirtió para dejar una convención consistente de "mayor valor = más
#'     del concepto" en el panel (confirmado contra un inventario
#'     metodológico externo con cita a cuestionario -- ver `notas` en
#'     [enem_codebook()] para el detalle).}
#'   \item{pdte_aprueba}{Versión binaria de `pdte_acuerdo`: 1=aprueba
#'     (`pdte_acuerdo` 3-4), 0=desaprueba (`pdte_acuerdo` 1-2), `NA` si no
#'     hubo respuesta.}
#'   \item{id_ola}{Identificador único DENTRO de cada ola (columna `id`
#'     original). NO es un identificador longitudinal entre olas -- ENEM es
#'     transversal salvo el panel de 2018.}
#'   \item{id_panel}{Llave compuesta `"<anio>_<id_ola>"`, única en todo
#'     `enem_panel`. Recomendada para unir con otras fuentes por ola en vez
#'     de `folio_original`.}
#' }
#' Además de las columnas `isco08_*` de ocupación (ver
#' [enem_occupation_vars()]), presentes cuando la ola las trae.
#' @source Construido en `data-raw/build_codebook.R` y
#'   `data-raw/procesar_ola.R` a partir de los 10 `.dta` originales del
#'   Estudio Nacional Electoral de México (ENEM).
#' @seealso [enem_load()], [enem_codebook()]
"enem_panel"

#' Codebook armonizado de la serie ENEM (crosswalk)
#'
#' El crosswalk que devuelve [enem_codebook()]: mapea, por año, la variable
#' original de cada ola al nombre armonizado usado en [enem_panel], para las
#' variables que sí cambian de nombre entre olas (sexo, edad, municipio,
#' fecha, folio, aprobación presidencial).
#'
#' @format Un data frame con las columnas:
#' \describe{
#'   \item{anio}{Año de la ola (1997-2024).}
#'   \item{concepto}{Nombre armonizado del concepto (`sexo`, `edad`,
#'     `municipio`, `fecha`, `folio`, `aprobacion_pdte`,
#'     `aprobacion_pdte_binaria`, `id_ola`).}
#'   \item{var_original}{Nombre de la variable en el `.dta` original de esa
#'     ola para ese concepto.}
#'   \item{var_armonizada}{Nombre de la columna correspondiente en
#'     [enem_panel].}
#'   \item{disponible}{Lógico. `FALSE` cuando esa ola no trae el concepto
#'     (p. ej. no hay variable de municipio en 2000).}
#'   \item{notas}{Advertencias relevantes (p. ej. que `folio` no es un
#'     identificador único salvo en 2024).}
#' }
#' @source Construido en `data-raw/build_codebook.R` a partir de los 10
#'   `.dta` originales del Estudio Nacional Electoral de México (ENEM).
#' @seealso [enem_codebook()], [enem_panel]
"enem_codebook"
