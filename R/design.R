#' Años disponibles en la serie ENEM
#'
#' Regresa metadata básica de las 10 olas de la serie: año, tamaño de
#' muestra, y si el diseño muestral de esa ola viene de una ficha
#' metodológica oficial o fue inferido de los datos/cuestionario.
#'
#' @return Un `data.frame` con columnas `anio`, `n`, `fuente_diseno`.
#' @export
#' @examples
#' enem_years()
enem_years <- function() {
  resumen <- utils::read.csv(
    system.file("extdata", "resumen_encuestas.csv", package = "rENEM"),
    stringsAsFactors = FALSE
  )
  diseno <- utils::read.csv(
    system.file("extdata", "diseno_muestral.csv", package = "rENEM"),
    stringsAsFactors = FALSE
  )
  out <- merge(
    resumen[, c("anio", "n_obs")],
    diseno[, c("anio", "fuente")],
    by = "anio"
  )
  names(out) <- c("anio", "n", "fuente_diseno")
  out[order(out$anio), ]
}

#' Ficha de diseño muestral de una ola
#'
#' Regresa el diseño muestral documentado (o inferido) de una ola de la
#' encuesta ENEM. Para 1997, 2000, 2003, 2006, 2009 y 2018 el diseño viene
#' de la nota tecnica/ficha metodologica oficial. Para 2012, 2015, 2021 y
#' 2024, que no tienen ficha, el diseno se reconstruyo a partir del
#' cuestionario y de las variables de peso/geografia presentes en los datos
#' -- revisa la columna `fuente` antes de citar estos campos como oficiales.
#'
#' @param year Entero. Año de la ola (uno de los valores de
#'   [enem_years()]).
#' @return Una lista con los campos del diseño (universo, modo, fechas de
#'   levantamiento, tamaño de muestra, dominios/estratos, método de
#'   selección, margen de error, ponderadores) y un campo `fuente`
#'   (`"oficial"` o `"inferido"`).
#' @export
#' @examples
#' \dontrun{
#' enem_design(2009)
#' enem_design(2012) # diseño inferido, sin ficha
#' }
enem_design <- function(year) {
  diseno <- utils::read.csv(
    system.file("extdata", "diseno_muestral.csv", package = "rENEM"),
    stringsAsFactors = FALSE
  )
  fila <- diseno[diseno$anio == year, ]
  if (nrow(fila) == 0) {
    stop(sprintf(
      "No hay ficha de diseno para %s. Anios disponibles: %s",
      year, paste(sort(unique(diseno$anio)), collapse = ", ")
    ), call. = FALSE)
  }
  as.list(fila)
}
