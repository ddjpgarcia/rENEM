# Buscar variables a través de todas las olas

Busca en el inventario de variables (nombre o etiqueta) de las 10 olas
de ENEM. Útil para encontrar en qué años existe una variable antes de
intentar armonizarla.

## Usage

``` r
enem_vars(pattern, years = NULL)
```

## Arguments

- pattern:

  Cadena. Expresión regular a buscar en el nombre o la etiqueta de la
  variable (insensible a mayúsculas).

- years:

  Entero opcional. Restringe la búsqueda a un subconjunto de años.

## Value

Un `data.frame` (subconjunto del inventario) con columnas `anio`,
`variable`, `etiqueta`, `pct_missing`, `n_categorias_unicas`.

## Details

Dos variables ya vienen con el mismo nombre en las 10 olas sin necesidad
de armonización: el ponderador (`PONDERADOR`, `PONDFIN`) y la ocupación
codificada en ISCO-08 (`isco08_1_ES`, `isco08_2_ES`, `isco08_1_ENG`,
`isco08_2_ENG`, con la excepción de 2021 que solo trae la variante
`_1`). El resto de las variables (sexo, edad, geografía, fecha) cambian
de nombre entre olas y requieren el crosswalk de
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md).

## Examples

``` r
if (FALSE) { # \dontrun{
enem_vars("pond")
enem_vars("voto|partido", years = c(2018, 2021, 2024))
} # }
```
