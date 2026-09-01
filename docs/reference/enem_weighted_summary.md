# Agregado ponderado de una variable de ENEM

Calcula la media (o proporción, si `var` es categórica) ponderada de una
variable, opcionalmente desglosada por grupo – por ejemplo, intención de
voto ponderada por partido y año.

## Usage

``` r
enem_weighted_summary(
  data,
  var,
  by = NULL,
  weight = c("PONDFIN", "PONDERADOR")
)
```

## Arguments

- data:

  Un `data.frame` de ENEM con columna de ponderador.

- var:

  Cadena. Nombre de la variable a resumir.

- by:

  Cadena opcional. Nombre de la variable de agrupación (p. ej. `"anio"`
  o `"region"`).

- weight:

  Ver
  [`enem_svy()`](https://ddjpgarcia.github.io/rENEM/reference/enem_svy.md).

## Value

Un `data.frame` con la media/proporción ponderada y su error estándar
(vía [`survey::svyby()`](https://rdrr.io/pkg/survey/man/svyby.html)
cuando `by` no es `NULL`, o
[`survey::svymean()`](https://rdrr.io/pkg/survey/man/surveysummary.html)
si es `NULL`).

## Examples

``` r
if (FALSE) { # \dontrun{
con <- enem_connect()
datos_2024 <- DBI::dbGetQuery(con, "SELECT * FROM enem_2024")
DBI::dbDisconnect(con, shutdown = TRUE)
enem_weighted_summary(datos_2024, "EDAD", by = "EDO")
} # }
```
