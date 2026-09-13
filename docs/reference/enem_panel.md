# Panel armonizado de ENEM (1997-2024)

El panel armonizado pequeño que se distribuye con el paquete y carga
[`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md):
variables comunes a las 10 olas (sexo, edad agrupada, pesos de diseño y
final, ocupación ISCO-08, y geografía/fecha/folio cuando existen). Ver
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
para el crosswalk completo de qué variable original corresponde a cada
columna aquí, y la sección "Advertencias importantes" de
[`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md)
antes de usar `municipio_original`, `fecha_original` o `folio_original`.

## Usage

``` r
enem_panel
```

## Format

Un data frame con una fila por entrevistado y las columnas:

- anio:

  Año de la ola (1997-2024).

- mujer:

  Indicador (0/1) de sexo, recodificado desde `female<año>`.

- edad_grupo:

  Edad agrupada (1-4), recodificada desde `age<año>b`.

- peso_diseno:

  Ponderador de diseño (`PONDERADOR` original de cada ola).

- peso_final:

  Ponderador final, con ajustes de no respuesta y postestratificación
  cuando aplica (`PONDFIN` original de cada ola).

- municipio_original:

  Código de municipio tal cual venía en la ola original (no armonizado
  entre años; `NA` si esa ola no lo trae).

- fecha_original:

  Fecha de entrevista tal cual venía en la ola original (no armonizada
  entre años; `NA` si esa ola no la trae).

- folio_original:

  Folio tal cual venía en la ola original. NO es un identificador único
  de respondiente salvo en 2024 – ver `folio_es_id_unico`.

- folio_es_id_unico:

  Lógico. `TRUE` solo para 2024, donde `folio` sí identifica de forma
  única a cada entrevistado.

- pdte_acuerdo:

  Aprobación presidencial, escala de 4 puntos: 1=Muy de acuerdo, 2=Algo
  de acuerdo, 3=Algo en desacuerdo, 4=Muy en desacuerdo con la manera
  como está gobernando el presidente. `NA` si no hubo respuesta. Sin
  value labels en los `.dta` originales para confirmar el texto exacto
  de las 4 categorías – dirección de la escala inferida por consistencia
  con la evolución histórica conocida de aprobación presidencial en
  México (ver `notas` en
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
  para el detalle).

- pdte_aprueba:

  Versión binaria de `pdte_acuerdo`: 1=aprueba (`pdte_acuerdo` 1-2),
  0=desaprueba (`pdte_acuerdo` 3-4), `NA` si no hubo respuesta.

Además de las columnas `isco08_*` de ocupación (ver
[`enem_occupation_vars()`](https://ddjpgarcia.github.io/rENEM/reference/enem_occupation_vars.md)),
presentes cuando la ola las trae.

## Source

Construido en `data-raw/build_codebook.R` y `data-raw/procesar_ola.R` a
partir de los 10 `.dta` originales del Estudio Nacional Electoral de
México (ENEM).

## See also

[`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md),
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
