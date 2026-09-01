#' Cargar el panel armonizado de ENEM
#'
#' Carga `enem_panel`, el panel armonizado pequeño que se distribuye con el
#' paquete: variables comunes a las 10 olas (`mujer`, `edad_grupo`, peso de
#' diseño y final, ocupación ISCO-08, y geografía/fecha/folio cuando
#' existen -- ver [enem_codebook()] para qué está disponible en cada año y
#' con qué advertencias). Para los datos completos de una ola (todas sus
#' variables originales), usa [enem_download()] / [enem_connect()].
#'
#' @section Advertencias importantes:
#' `mujer` y `edad_grupo` vienen de variables ya recodificadas en los
#' `.dta` originales (`female<año>`, `age<año>b`) que NO traen etiquetas de
#' valor -- se asume la convención estándar (`mujer`: 0/1; `edad_grupo`:
#' 1-4, de menor a mayor) pero no se confirmó contra el cuestionario.
#' `municipio_original` y `fecha_original` NO están armonizados entre años
#' (mismos códigos no son comparables entre olas) y pueden ser `NA` (no
#' existen en 2000 y en 1997/2000/2003/2006/2012 respectivamente).
#' `folio_original` NO es un identificador único de respondiente salvo en
#' 2024 -- ver la columna `folio_es_id_unico`.
#'
#' @param years Entero o vector de enteros opcional. Si se especifica,
#'   regresa solo esas olas del panel.
#' @return Un `data.frame` largo, con una fila por entrevistado y una
#'   columna `anio`.
#' @export
#' @examples
#' \dontrun{
#' enem_load()
#' enem_load(years = c(1997, 2024))
#' }
enem_load <- function(years = NULL) {
  .env <- new.env(parent = emptyenv())
  utils::data("enem_panel", package = "rENEM", envir = .env)
  out <- .env[["enem_panel"]]
  if (!is.null(years)) {
    out <- out[out$anio %in% years, ]
  }
  out
}
