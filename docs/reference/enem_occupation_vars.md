# Variables de ocupación ISCO-08 disponibles en ENEM

Las 10 olas de ENEM ya traen la ocupación codificada en ISCO-08 a 2
dígitos, con nombre de columna consistente entre años – esta es una de
las pocas variables que NO requiere el crosswalk de
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
para compararse entre olas. Cada ola trae hasta 4 variantes:
`isco08_1_ES`/`isco08_1_ENG` (opción A: incluye a todos los
respondientes) e `isco08_2_ES`/`isco08_2_ENG` (opción B: solo
respondientes válidos), en español e inglés. La ola 2021 es la única
excepción: solo trae la variante `_1` (sin `_2`).

## Usage

``` r
enem_occupation_vars(data)
```

## Arguments

- data:

  Un `data.frame` de ENEM.

## Value

Un vector de las columnas `isco08_*` presentes en `data` (puede tener
longitud 0 si `data` no trae ninguna).

## Examples

``` r
if (FALSE) { # \dontrun{
enem_occupation_vars(datos_2015)
} # }
```
