# Codebook armonizado de la serie ENEM

Regresa el crosswalk que mapea, por año, la variable original al nombre
armonizado usado por
[`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md)
– para las 5 variables que sí cambian de nombre entre olas (sexo, edad,
municipio, fecha, folio; el ponderador y la ocupación ISCO-08 ya vienen
con el mismo nombre en las 10 olas, ver
[`enem_vars()`](https://ddjpgarcia.github.io/rENEM/reference/enem_vars.md)).
Revisa la columna `notas`: varias filas están marcadas
`disponible = FALSE` (p. ej. no hay variable de municipio en 2000) o
traen advertencias importantes (p. ej. `folio` NO es un identificador
único de respondiente salvo en 2024 – se repite entre filas en el resto
de las olas).

## Usage

``` r
enem_codebook(year = NULL)
```

## Arguments

- year:

  Entero opcional. Si se especifica, regresa solo las filas de esa ola.

## Value

Un `data.frame` con columnas `anio`, `concepto`, `var_original`,
`var_armonizada`, `disponible`, `notas`.

## Examples

``` r
if (FALSE) { # \dontrun{
enem_codebook()
enem_codebook(2012)
} # }
```
