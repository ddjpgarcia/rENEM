# Construir un diseño muestral ponderado para datos de ENEM

Envuelve
[`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html)
usando el ponderador estandarizado de ENEM. Las 10 olas ya traen, con el
mismo nombre, dos ponderadores: `PONDERADOR` (ponderador de diseño) y
`PONDFIN` (ponderador final, con ajustes de no respuesta y
postestratificación cuando aplica) – por eso esta función funciona igual
sin importar de qué ola vienen los datos, a diferencia de otras
variables que sí cambian de nombre entre años (ver
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)).

## Usage

``` r
enem_svy(data, weight = c("PONDFIN", "PONDERADOR"))
```

## Arguments

- data:

  Un `data.frame` con los datos completos de una ola (de
  [`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)
  /
  [`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md))
  que incluya la columna de ponderador.

- weight:

  Cadena. Cuál ponderador usar: `"PONDFIN"` (default, recomendado –
  incluye ajustes de no respuesta) o `"PONDERADOR"` (ponderador de
  diseño puro).

## Value

Un objeto `survey.design` (ver
[`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html)).

## Details

No se documentan unidades primarias de muestreo (UPM) ni estratos
explícitos en los `.dta`, así que el diseño se construye como muestreo
aleatorio simple ponderado (`ids = ~1`). Si en el futuro se recupera la
sección electoral como UPM (ver `Pendientes` del reporte de datos),
actualiza esta función para pasarla a `ids`.

Esta función es para los datos **completos** de una ola (de
[`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)
/
[`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md),
con columnas `PONDERADOR`/ `PONDFIN`). El panel armonizado de
[`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md)
usa otros nombres (`peso_diseno`/`peso_final`) – para agregados sobre el
panel usa
[`enem_trend()`](https://ddjpgarcia.github.io/rENEM/reference/enem_trend.md),
que ya sabe cuál ponderador usar.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- enem_connect()
datos_2024 <- DBI::dbGetQuery(con, "SELECT * FROM enem_2024")
DBI::dbDisconnect(con, shutdown = TRUE)
d <- enem_svy(datos_2024)
survey::svymean(~EDAD, d, na.rm = TRUE)
} # }
```
