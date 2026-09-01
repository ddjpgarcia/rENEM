# Configuracion del hosting de datos completos ------------------------------
# Los datos completos de las 10 olas viven en UN SOLO archivo duckdb
# (enem_data.duckdb: una tabla enem_<anio> por ola con TODAS sus variables
# originales, mas enem_panel y las tablas _codebook_*/_diseno_muestral),
# publicado como asset de un GitHub Release en este mismo repo. El release
# puede estar privado o publico -- ver mas abajo.
.enem_gh_repo <- "ddjpgarcia/rENEM"
.enem_gh_asset_name <- "enem_data.duckdb"

#' @keywords internal
.enem_release_tag <- function() {
  getOption("rENEM.data_tag", "data-v1")
}

#' @keywords internal
.enem_cache_path <- function() {
  dir <- tools::R_user_dir("rENEM", "cache")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  file.path(dir, .enem_gh_asset_name)
}

#' @keywords internal
.enem_github_pat <- function() {
  pat <- Sys.getenv("GITHUB_PAT", unset = NA)
  if (is.na(pat) || !nzchar(pat)) NULL else pat
}

#' Descargar (o localizar en caché) el archivo completo de datos de ENEM
#'
#' Se asegura de que `enem_data.duckdb` -- el archivo con los datos
#' completos de las 10 olas -- esté disponible localmente, descargándolo
#' del Release de GitHub si hace falta. El repo puede ser privado: si la
#' variable de ambiente `GITHUB_PAT` está definida, se usa para
#' autenticar la descarga vía la API de GitHub; si el repo es público, no
#' hace falta token.
#'
#' @keywords internal
.enem_ensure_cached <- function(overwrite = FALSE) {
  destino <- .enem_cache_path()
  if (file.exists(destino) && !overwrite) {
    return(destino)
  }

  rlang::check_installed("httr2", "para descargar los datos de ENEM.")
  tag <- .enem_release_tag()
  pat <- .enem_github_pat()

  repo <- .enem_gh_repo
  cli::cli_inform("Buscando el release {.val {tag}} en {.val {repo}}...")

  req_release <- httr2::request(sprintf(
    "https://api.github.com/repos/%s/releases/tags/%s", .enem_gh_repo, tag
  ))
  if (!is.null(pat)) {
    req_release <- httr2::req_headers(req_release, Authorization = paste("token", pat))
  }
  req_release <- httr2::req_error(req_release, is_error = function(resp) FALSE)
  resp_release <- httr2::req_perform(req_release)

  if (httr2::resp_status(resp_release) == 404) {
    stop(sprintf(paste(
      "No se encontro el release '%s' en %s (o no tienes acceso).",
      "Si el repo es privado, confirma que la variable de ambiente",
      "GITHUB_PAT este definida con un token que tenga permiso de lectura.",
      "Si el release existe con otro tag, ajustalo con",
      "options(rENEM.data_tag = \"tu-tag\")."
    ), tag, .enem_gh_repo), call. = FALSE)
  }
  if (httr2::resp_status(resp_release) >= 400) {
    stop(sprintf(
      "Error %s consultando el release de datos: %s",
      httr2::resp_status(resp_release), httr2::resp_body_string(resp_release)
    ), call. = FALSE)
  }

  release <- httr2::resp_body_json(resp_release)
  assets <- release$assets
  nombres <- vapply(assets, function(a) a$name, character(1))
  idx <- match(.enem_gh_asset_name, nombres)
  if (is.na(idx)) {
    stop(sprintf(
      "El release '%s' no tiene un asset llamado '%s'. Assets disponibles: %s",
      tag, .enem_gh_asset_name, paste(nombres, collapse = ", ")
    ), call. = FALSE)
  }
  asset <- assets[[idx]]

  asset_name <- .enem_gh_asset_name
  cli::cli_inform("Descargando {.val {asset_name}} ({round(asset$size / 1e6, 1)} MB)...")

  tmp <- tempfile(fileext = ".duckdb")
  if (!is.null(pat)) {
    # Repo privado: hay que pasar por el endpoint de la API con
    # Accept: application/octet-stream para bajar el binario autenticado
    # (la browser_download_url normal NO funciona con un token asi nada mas).
    req_dl <- httr2::request(sprintf(
      "https://api.github.com/repos/%s/releases/assets/%s", .enem_gh_repo, asset$id
    ))
    req_dl <- httr2::req_headers(req_dl, Authorization = paste("token", pat), Accept = "application/octet-stream")
  } else {
    # Repo publico: la URL de descarga normal funciona sin autenticacion.
    req_dl <- httr2::request(asset$browser_download_url)
  }
  httr2::req_perform(req_dl, path = tmp)

  file.rename(tmp, destino)
  cli::cli_inform(c("v" = "Guardado en cache: {.path {destino}}"))
  destino
}

#' Descargar datos completos de ENEM (todas las olas o algunas)
#'
#' Se asegura de que el archivo completo de datos esté disponible
#' localmente (lo descarga la primera vez, después usa la copia en caché),
#' y regresa los datos en el formato que pidas. El archivo que se
#' descarga siempre es el mismo (`enem_data.duckdb`, ~22 MB, las 10 olas
#' juntas) -- `year`/`format` solo controlan qué te regresa esta función a
#' partir de esa copia local, no cuánto se descarga por red.
#'
#' @param year Entero o vector de enteros opcional. Si `NULL` (default),
#'   incluye las 10 olas.
#' @param format Uno de `"duckdb"` (default -- regresa la ruta al archivo
#'   completo, para abrir tú mismo con [enem_connect()] o [DBI::dbConnect()]),
#'   `"dta"` o `"csv"` (exporta la(s) tabla(s) pedidas a archivos locales en
#'   `tempdir()` y regresa sus rutas).
#' @param overwrite Lógico. Si `TRUE`, vuelve a descargar el archivo
#'   completo aunque ya exista en caché (para refrescar una versión nueva
#'   del Release).
#' @return Invisiblemente, la ruta (o vector de rutas) de los archivos
#'   resultantes.
#' @export
#' @examples
#' \dontrun{
#' enem_download() # asegura la copia local, regresa la ruta al .duckdb
#' enem_download(2024, format = "csv")
#' enem_download(format = "dta") # las 10 olas, un .dta por año
#' }
enem_download <- function(year = NULL, format = c("duckdb", "dta", "csv"), overwrite = FALSE) {
  format <- match.arg(format)
  ruta_duckdb <- .enem_ensure_cached(overwrite = overwrite)

  if (format == "duckdb") {
    if (!is.null(year)) {
      cli::cli_warn("`year` se ignora con format = \"duckdb\": el archivo cacheado siempre trae las 10 olas.")
    }
    return(invisible(ruta_duckdb))
  }

  rlang::check_installed(c("duckdb", "DBI"), "para exportar a dta/csv.")
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ruta_duckdb, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  anios <- if (is.null(year)) c(1997, 2000, 2003, 2006, 2009, 2012, 2015, 2018, 2021, 2024) else year
  salidas <- character(0)
  for (a in anios) {
    tabla <- sprintf("enem_%s", a)
    datos <- DBI::dbReadTable(con, tabla)
    archivo <- file.path(tempdir(), sprintf("ENEM_%s.%s", a, format))
    if (format == "dta") {
      rlang::check_installed("haven", "para exportar a .dta.")
      haven::write_dta(datos, archivo)
    } else {
      utils::write.csv(datos, archivo, row.names = FALSE)
    }
    salidas <- c(salidas, archivo)
  }
  invisible(salidas)
}

#' Abrir una conexión DuckDB a los datos completos de ENEM
#'
#' Se asegura de que `enem_data.duckdb` esté descargado (ver
#' [enem_download()]) y abre una conexión de solo lectura. Las tablas
#' disponibles son `enem_1997` ... `enem_2024` (datos completos originales
#' de cada ola, con los nombres de columna tal cual venían en el `.dta` --
#' no traen una columna de año, ya que el año es el nombre de la tabla),
#' `enem_panel` (el mismo panel armonizado de [enem_load()], este sí trae
#' `anio`), y `_codebook_variables`/`_codebook_crosswalk`/`_diseno_muestral`
#' (la metadata que también trae el paquete en `inst/extdata/`).
#'
#' @param years Entero o vector de enteros opcional. Si se especifica, solo
#'   valida que esas olas existan en el archivo (no cambia qué tan rápido
#'   se abre -- las 10 tablas ya están en el mismo archivo local).
#' @return Un objeto `DBIConnection` (ver [DBI::dbConnect()]). Ciérralo con
#'   `DBI::dbDisconnect(con, shutdown = TRUE)` cuando termines.
#' @export
#' @examples
#' \dontrun{
#' con <- enem_connect()
#' DBI::dbListTables(con)
#' # tabla cruda: nombres originales del .dta, sin columna de año
#' DBI::dbGetQuery(con, "SELECT folio, PONDFIN, PONDERADOR FROM enem_2024 LIMIT 5")
#' # tabla armonizada: sí trae anio
#' DBI::dbGetQuery(con, "SELECT anio, peso_final FROM enem_panel WHERE anio = 2024 LIMIT 5")
#' DBI::dbDisconnect(con, shutdown = TRUE)
#' }
enem_connect <- function(years = NULL) {
  rlang::check_installed(c("duckdb", "DBI"), "para conectarte a los datos de ENEM.")
  ruta_duckdb <- .enem_ensure_cached()
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ruta_duckdb, read_only = TRUE)

  if (!is.null(years)) {
    tablas <- DBI::dbListTables(con)
    esperadas <- sprintf("enem_%s", years)
    faltantes <- setdiff(esperadas, tablas)
    if (length(faltantes) > 0) {
      cli::cli_warn("No se encontraron estas tablas en el archivo: {faltantes}")
    }
  }

  con
}
