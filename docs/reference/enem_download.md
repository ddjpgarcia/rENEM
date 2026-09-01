# Descargar datos completos de ENEM (todas las olas o algunas)

Se asegura de que el archivo completo de datos esté disponible
localmente (lo descarga la primera vez, después usa la copia en caché),
y regresa los datos en el formato que pidas. El archivo que se descarga
siempre es el mismo (`enem_data.duckdb`, ~22 MB, las 10 olas juntas) –
`year`/`format` solo controlan qué te regresa esta función a partir de
esa copia local, no cuánto se descarga por red.

## Usage

``` r
enem_download(
  year = NULL,
  format = c("duckdb", "dta", "csv"),
  overwrite = FALSE
)
```

## Arguments

- year:

  Entero o vector de enteros opcional. Si `NULL` (default), incluye las
  10 olas.

- format:

  Uno de `"duckdb"` (default – regresa la ruta al archivo completo, para
  abrir tú mismo con
  [`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md)
  o
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)),
  `"dta"` o `"csv"` (exporta la(s) tabla(s) pedidas a archivos locales
  en [`tempdir()`](https://rdrr.io/r/base/tempfile.html) y regresa sus
  rutas).

- overwrite:

  Lógico. Si `TRUE`, vuelve a descargar el archivo completo aunque ya
  exista en caché (para refrescar una versión nueva del Release).

## Value

Invisiblemente, la ruta (o vector de rutas) de los archivos resultantes.

## Examples

``` r
if (FALSE) { # \dontrun{
enem_download() # asegura la copia local, regresa la ruta al .duckdb
enem_download(2024, format = "csv")
enem_download(format = "dta") # las 10 olas, un .dta por año
} # }
```
