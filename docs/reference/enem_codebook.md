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

El crosswalk que devuelve `enem_codebook()`: mapea, por año, la variable
original de cada ola al nombre armonizado usado en
[enem_panel](https://ddjpgarcia.github.io/rENEM/reference/enem_panel.md),
para las variables que sí cambian de nombre entre olas (sexo, edad,
municipio, fecha, folio, aprobación presidencial).

## Usage

``` r
enem_codebook(year = NULL)

enem_codebook
```

## Format

Un data frame con las columnas:

- anio:

  Año de la ola (1997-2024).

- concepto:

  Nombre armonizado del concepto (`sexo`, `edad`, `municipio`, `fecha`,
  `folio`, `aprobacion_pdte`, `aprobacion_pdte_binaria`, `id_ola`,
  `ideologia_lr`, `eval_pan`, `eval_prd`, `eval_pri`).

- var_original:

  Nombre de la variable en el `.dta` original de esa ola para ese
  concepto.

- var_armonizada:

  Nombre de la columna correspondiente en
  [enem_panel](https://ddjpgarcia.github.io/rENEM/reference/enem_panel.md).

- disponible:

  Lógico. `FALSE` cuando esa ola no trae el concepto (p. ej. no hay
  variable de municipio en 2000).

- notas:

  Advertencias relevantes (p. ej. que `folio` no es un identificador
  único salvo en 2024).

## Source

Construido en `data-raw/build_codebook.R` a partir de los 10 `.dta`
originales del Estudio Nacional Electoral de México (ENEM).

## Arguments

- year:

  Entero opcional. Si se especifica, regresa solo las filas de esa ola.

## Value

Un `data.frame` con columnas `anio`, `concepto`, `var_original`,
`var_armonizada`, `disponible`, `notas`.

## See also

`enem_codebook()`,
[enem_panel](https://ddjpgarcia.github.io/rENEM/reference/enem_panel.md)

## Examples

``` r
if (FALSE) { # \dontrun{
enem_codebook()
enem_codebook(2012)
} # }
```
