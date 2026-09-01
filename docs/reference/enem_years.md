# Años disponibles en la serie ENEM

Regresa metadata básica de las 10 olas de la serie: año, tamaño de
muestra, y si el diseño muestral de esa ola viene de una ficha
metodológica oficial o fue inferido de los datos/cuestionario.

## Usage

``` r
enem_years()
```

## Value

Un `data.frame` con columnas `anio`, `n`, `fuente_diseno`.

## Examples

``` r
enem_years()
#>    anio    n                     fuente_diseno
#> 1  1997 2033                     Ficha oficial
#> 2  2000 1766                     Ficha oficial
#> 3  2003 1991                     Ficha oficial
#> 4  2006 1591                     Ficha oficial
#> 5  2009 2400              Ficha oficial (CSES)
#> 6  2012 2400 INFERIDO (sin ficha metodológica)
#> 7  2015 2397 INFERIDO (sin ficha metodológica)
#> 8  2018 1239        Ficha oficial (panel CSES)
#> 9  2021 1800 INFERIDO (sin ficha metodológica)
#> 10 2024 2700 INFERIDO (sin ficha metodológica)
```
