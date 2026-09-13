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
  única a cada entrevistado. Para una llave única en las 10 olas, usa
  `id_ola`/`id_panel` en vez de `folio`.

- pdte_acuerdo:

  Aprobación presidencial, escala de 4 puntos orientada para que mayor
  valor = mayor aprobación: 1=Muy en desacuerdo, 2=Algo en desacuerdo,
  3=Algo de acuerdo, 4=Muy de acuerdo con la manera como está gobernando
  el presidente. `NA` si no hubo respuesta. El original venía en orden
  inverso (1=Muy de acuerdo); se invirtió para dejar una convención
  consistente de "mayor valor = más del concepto" en el panel
  (confirmado contra un inventario metodológico externo con cita a
  cuestionario – ver `notas` en
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
  para el detalle).

- pdte_aprueba:

  Versión binaria de `pdte_acuerdo`: 1=aprueba (`pdte_acuerdo` 3-4),
  0=desaprueba (`pdte_acuerdo` 1-2), `NA` si no hubo respuesta.

- id_ola:

  Identificador único DENTRO de cada ola (columna `id` original). NO es
  un identificador longitudinal entre olas – ENEM es transversal salvo
  el panel de 2018.

- id_panel:

  Llave compuesta `"<anio>_<id_ola>"`, única en todo `enem_panel`.
  Recomendada para unir con otras fuentes por ola en vez de
  `folio_original`.

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
