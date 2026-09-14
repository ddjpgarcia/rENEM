#' Construir un diseño muestral ponderado para datos de ENEM
#'
#' Envuelve [survey::svydesign()] usando el ponderador estandarizado de
#' ENEM. Las 10 olas ya traen, con el mismo nombre, dos ponderadores:
#' `PONDERADOR` (ponderador de diseño) y `PONDFIN` (ponderador final, con
#' ajustes de no respuesta y postestratificación cuando aplica) -- por eso
#' esta función funciona igual sin importar de qué ola vienen los datos, a
#' diferencia de otras variables que sí cambian de nombre entre años (ver
#' [enem_codebook()]).
#'
#' No se documentan unidades primarias de muestreo (UPM) ni estratos
#' explícitos en los `.dta`, así que el diseño se construye como muestreo
#' aleatorio simple ponderado (`ids = ~1`). Si en el futuro se recupera la
#' sección electoral como UPM (ver `Pendientes` del reporte de datos),
#' actualiza esta función para pasarla a `ids`.
#'
#' Esta función es para los datos **completos** de una ola (de
#' [enem_download()] / [enem_connect()], con columnas `PONDERADOR`/
#' `PONDFIN`). El panel armonizado de [enem_load()] usa otros nombres
#' (`peso_diseno`/`peso_final`) -- para agregados sobre el panel usa
#' [enem_trend()], que ya sabe cuál ponderador usar.
#'
#' @param data Un `data.frame` con los datos completos de una ola (de
#'   [enem_download()] / [enem_connect()]) que incluya la columna de
#'   ponderador.
#' @param weight Cadena. Cuál ponderador usar: `"PONDFIN"` (default,
#'   recomendado -- incluye ajustes de no respuesta) o `"PONDERADOR"`
#'   (ponderador de diseño puro).
#' @return Un objeto `survey.design` (ver [survey::svydesign()]).
#' @export
#' @examples
#' \dontrun{
#' con <- enem_connect()
#' datos_2024 <- DBI::dbGetQuery(con, "SELECT * FROM enem_2024")
#' DBI::dbDisconnect(con, shutdown = TRUE)
#' d <- enem_svy(datos_2024)
#' survey::svymean(~EDAD, d, na.rm = TRUE)
#' }
enem_svy <- function(data, weight = c("PONDFIN", "PONDERADOR")) {
  weight <- match.arg(weight)
  if (!weight %in% names(data)) {
    stop(sprintf(
      "La columna de ponderador '%s' no esta en `data`. Columnas disponibles: %s",
      weight, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  }
  survey::svydesign(
    ids = ~1,
    weights = stats::as.formula(paste0("~", weight)),
    data = data
  )
}

#' Agregado ponderado de una variable de ENEM
#'
#' Calcula la media (o proporción, si `var` es categórica) ponderada de una
#' variable, opcionalmente desglosada por grupo -- por ejemplo, intención
#' de voto ponderada por partido y año.
#'
#' @param data Un `data.frame` de ENEM con columna de ponderador.
#' @param var Cadena. Nombre de la variable a resumir.
#' @param by Cadena opcional. Nombre de la variable de agrupación (p. ej.
#'   `"anio"` o `"region"`).
#' @param weight Ver [enem_svy()].
#' @return Un `data.frame` con la media/proporción ponderada y su error
#'   estándar (vía [survey::svyby()] cuando `by` no es `NULL`, o
#'   [survey::svymean()] si es `NULL`).
#' @export
#' @examples
#' \dontrun{
#' con <- enem_connect()
#' datos_2024 <- DBI::dbGetQuery(con, "SELECT * FROM enem_2024")
#' DBI::dbDisconnect(con, shutdown = TRUE)
#' enem_weighted_summary(datos_2024, "EDAD", by = "EDO")
#' }
enem_weighted_summary <- function(data, var, by = NULL, weight = c("PONDFIN", "PONDERADOR")) {
  weight <- match.arg(weight)
  disenio <- enem_svy(data, weight = weight)
  formula_var <- stats::as.formula(paste0("~", var))
  if (is.null(by)) {
    return(as.data.frame(survey::svymean(formula_var, disenio, na.rm = TRUE)))
  }
  formula_by <- stats::as.formula(paste0("~", paste(by, collapse = "+")))
  survey::svyby(formula_var, formula_by, disenio, survey::svymean, na.rm = TRUE)
}

#' Serie temporal comparada de una variable armonizada
#'
#' Calcula el agregado ponderado de una variable del panel armonizado
#' ([enem_load()]) a lo largo de las olas donde existe, para ver su
#' evolución 1997-2024. Como `enem_panel` solo trae `mujer`, `edad_grupo`,
#' ocupación ISCO-08, y municipio/fecha/folio (parcialmente disponibles,
#' no armonizados), por ahora esta función solo tiene sentido para esas
#' columnas -- las variables sustantivas de opinión (voto, aprobación,
#' etc.) todavía no están en el panel armonizado, solo en los datos
#' completos de cada ola ([enem_download()]).
#'
#' @param var Cadena. Nombre de la variable en `enem_panel` (p. ej.
#'   `"mujer"`).
#' @param years Entero opcional. Subconjunto de años a comparar.
#' @return Un `data.frame` con una fila por año (media/proporción
#'   ponderada con `peso_final` y su error estándar).
#' @export
#' @examples
#' \dontrun{
#' enem_trend("mujer") # deberia rondar 50-55% en todas las olas
#' enem_trend("pdte_aprueba") # serie de aprobacion presidencial, 1997-2024
#' enem_trend("eval_pri") # evaluacion del PRI: pico en 2009/2012, colapso post-2018
#' }
enem_trend <- function(var, years = NULL) {
  panel <- enem_load(years = years)
  if (!var %in% names(panel)) {
    stop(sprintf(
      "'%s' no esta en enem_panel. Columnas disponibles: %s",
      var, paste(names(panel), collapse = ", ")
    ), call. = FALSE)
  }
  disenio <- survey::svydesign(ids = ~1, weights = ~peso_final, data = panel)
  formula_var <- stats::as.formula(paste0("~", var))
  survey::svyby(formula_var, ~anio, disenio, survey::svymean, na.rm = TRUE)
}
