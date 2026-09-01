# Abrir una conexión DuckDB a los datos completos de ENEM

Se asegura de que `enem_data.duckdb` esté descargado (ver
[`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md))
y abre una conexión de solo lectura. Las tablas disponibles son
`enem_1997` ... `enem_2024` (datos completos originales de cada ola, con
los nombres de columna tal cual venían en el `.dta` – no traen una
columna de año, ya que el año es el nombre de la tabla), `enem_panel`
(el mismo panel armonizado de
[`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md),
este sí trae `anio`), y
`_codebook_variables`/`_codebook_crosswalk`/`_diseno_muestral` (la
metadata que también trae el paquete en `inst/extdata/`).

## Usage

``` r
enem_connect(years = NULL)
```

## Arguments

- years:

  Entero o vector de enteros opcional. Si se especifica, solo valida que
  esas olas existan en el archivo (no cambia qué tan rápido se abre –
  las 10 tablas ya están en el mismo archivo local).

## Value

Un objeto `DBIConnection` (ver
[`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)).
Ciérralo con `DBI::dbDisconnect(con, shutdown = TRUE)` cuando termines.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- enem_connect()
DBI::dbListTables(con)
# tabla cruda: nombres originales del .dta, sin columna de año
DBI::dbGetQuery(con, "SELECT folio, PONDFIN, PONDERADOR FROM enem_2024 LIMIT 5")
# tabla armonizada: sí trae anio
DBI::dbGetQuery(con, "SELECT anio, peso_final FROM enem_panel WHERE anio = 2024 LIMIT 5")
DBI::dbDisconnect(con, shutdown = TRUE)
} # }
```
