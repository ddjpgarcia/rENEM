# Ficha de diseño muestral de una ola

Regresa el diseño muestral documentado (o inferido) de una ola de la
encuesta ENEM. Para 1997, 2000, 2003, 2006, 2009 y 2018 el diseño viene
de la nota tecnica/ficha metodologica oficial. Para 2012, 2015, 2021 y
2024, que no tienen ficha, el diseno se reconstruyo a partir del
cuestionario y de las variables de peso/geografia presentes en los datos
– revisa la columna `fuente` antes de citar estos campos como oficiales.

## Usage

``` r
enem_design(year)
```

## Arguments

- year:

  Entero. Año de la ola (uno de los valores de
  [`enem_years()`](https://ddjpgarcia.github.io/rENEM/reference/enem_years.md)).

## Value

Una lista con los campos del diseño (universo, modo, fechas de
levantamiento, tamaño de muestra, dominios/estratos, método de
selección, margen de error, ponderadores) y un campo `fuente`
(`"oficial"` o `"inferido"`).

## Examples

``` r
if (FALSE) { # \dontrun{
enem_design(2009)
enem_design(2012) # diseño inferido, sin ficha
} # }
```
