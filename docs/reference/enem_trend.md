# Serie temporal comparada de una variable armonizada

Calcula el agregado ponderado de una variable del panel armonizado
([`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md))
a lo largo de las olas donde existe, para ver su evolución 1997-2024.
Como `enem_panel` solo trae `mujer`, `edad_grupo`, ocupación ISCO-08, y
municipio/fecha/folio (parcialmente disponibles, no armonizados), por
ahora esta función solo tiene sentido para esas columnas – las variables
sustantivas de opinión (voto, aprobación, etc.) todavía no están en el
panel armonizado, solo en los datos completos de cada ola
([`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)).

## Usage

``` r
enem_trend(var, years = NULL)
```

## Arguments

- var:

  Cadena. Nombre de la variable en `enem_panel` (p. ej. `"mujer"`).

- years:

  Entero opcional. Subconjunto de años a comparar.

## Value

Un `data.frame` con una fila por año (media/proporción ponderada con
`peso_final` y su error estándar).

## Examples

``` r
if (FALSE) { # \dontrun{
enem_trend("mujer") # deberia rondar 50-55% en todas las olas
enem_trend("pdte_aprueba") # serie de aprobacion presidencial, 1997-2024
enem_trend("eval_pri") # evaluacion del PRI: pico en 2009/2012, colapso post-2018
} # }
```
