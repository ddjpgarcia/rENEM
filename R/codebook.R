#' Codebook armonizado de la serie ENEM
#'
#' Regresa el crosswalk que mapea, por año, la variable original al nombre
#' armonizado usado por [enem_load()] -- para las 5 variables que sí
#' cambian de nombre entre olas (sexo, edad, municipio, fecha, folio; el
#' ponderador y la ocupación ISCO-08 ya vienen con el mismo nombre en las
#' 10 olas, ver [enem_vars()]). Revisa la columna `notas`: varias filas
#' están marcadas `disponible = FALSE` (p. ej. no hay variable de
#' municipio en 2000) o traen advertencias importantes (p. ej. `folio` NO
#' es un identificador único de respondiente salvo en 2024 -- se repite
#' entre filas en el resto de las olas).
#'
#' @param year Entero opcional. Si se especifica, regresa solo las filas de
#'   esa ola.
#' @return Un `data.frame` con columnas `anio`, `concepto`, `var_original`,
#'   `var_armonizada`, `disponible`, `notas`.
#' @export
#' @examples
#' \dontrun{
#' enem_codebook()
#' enem_codebook(2012)
#' }
enem_codebook <- function(year = NULL) {
  .env <- new.env(parent = emptyenv())
  utils::data("enem_codebook", package = "rENEM", envir = .env)
  out <- .env[["enem_codebook"]]
  if (!is.null(year)) {
    out <- out[out$anio %in% year, ]
  }
  out
}

#' Buscar variables a través de todas las olas
#'
#' Busca en el inventario de variables (nombre o etiqueta) de las 10 olas
#' de ENEM. Útil para encontrar en qué años existe una variable antes de
#' intentar armonizarla.
#'
#' Dos variables ya vienen con el mismo nombre en las 10 olas sin necesidad
#' de armonización: el ponderador (`PONDERADOR`, `PONDFIN`) y la ocupación
#' codificada en ISCO-08 (`isco08_1_ES`, `isco08_2_ES`, `isco08_1_ENG`,
#' `isco08_2_ENG`, con la excepción de 2021 que solo trae la variante `_1`).
#' El resto de las variables (sexo, edad, geografía, fecha) cambian de
#' nombre entre olas y requieren el crosswalk de [enem_codebook()].
#'
#' @param pattern Cadena. Expresión regular a buscar en el nombre o la
#'   etiqueta de la variable (insensible a mayúsculas).
#' @param years Entero opcional. Restringe la búsqueda a un subconjunto de
#'   años.
#' @return Un `data.frame` (subconjunto del inventario) con columnas
#'   `anio`, `variable`, `etiqueta`, `pct_missing`, `n_categorias_unicas`.
#' @export
#' @examples
#' \dontrun{
#' enem_vars("pond")
#' enem_vars("voto|partido", years = c(2018, 2021, 2024))
#' }
enem_vars <- function(pattern, years = NULL) {
  inv <- utils::read.csv(
    system.file("extdata", "inventario_variables.csv", package = "rENEM"),
    stringsAsFactors = FALSE
  )
  hit <- grepl(pattern, inv$variable, ignore.case = TRUE) |
    grepl(pattern, inv$etiqueta, ignore.case = TRUE)
  out <- inv[hit, c("anio", "variable", "etiqueta", "pct_missing", "n_categorias_unicas")]
  if (!is.null(years)) {
    out <- out[out$anio %in% years, ]
  }
  out[order(out$anio, out$variable), ]
}
