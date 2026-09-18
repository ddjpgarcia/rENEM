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

- ideologia_lr:

  Autoubicación izquierda-derecha, escala 0-10 (0=izquierda,
  10=derecha). `NA` si no hubo respuesta válida (NS, NC, "no ha oído
  hablar de izquierda/derecha", etc. según el año – ver `notas` en
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)).

- eval_pan, eval_prd, eval_pri, eval_pt, eval_pvem:

  Evaluación del PAN/PRD/PRI/PT/PVEM, termómetro 0-10 (0=no le gusta
  nada, 10=le gusta mucho). `NA` si no hubo respuesta válida (NS, NC,
  "no lo conozco lo suficiente", "nunca ha oído del partido", "no aplica
  por versión del cuestionario", según el año – ver `notas` en
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)).

- ideologia_pan, ideologia_prd, ideologia_pri, ideologia_pt,
  ideologia_pvem:

  Ubicación izquierda-derecha DE CADA PARTIDO según el entrevistado
  (distinto de `ideologia_lr`, que es la autoubicación del propio
  entrevistado), escala 0-10 (0=izquierda, 10=derecha). `NA` si no hubo
  respuesta válida. OJO: en 2018 el cuestionario/Stata almacenan estas 5
  columnas con códigos 1-11 en vez de 0-10 – ya corregido en esta
  columna armonizada (ver `notas` en
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
  para el detalle del desplazamiento).

- pid_partido:

  Identificación partidista, categórica:
  `"PAN"`/`"PRI"`/`"PRD"`/`"PVEM"`/`"PT"`/`"MC"`/`"MORENA"`/`"Otro"`/
  `"Ninguno"`, o `NA` (no supo/no contestó). Reconstruida distinto según
  el diseño de pregunta de cada ola – ver `notas` en
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
  para el detalle completo por año. En 1997-2012 viene de un filtro
  binario ("¿simpatiza con algún partido?") más la primera mención de
  partido si contestó que sí; `"Ninguno"` ahí significa que contestó
  "No" al filtro (confirmado contra el filtro mismo, no inferido de que
  la variable de partido venga vacía). En 2015-2024 viene de una sola
  batería que ya incluye Otro/Ninguno/NS/NC como categorías explícitas.
  `"Otro"` agrupa partidos minoritarios NO comparables entre olas (la
  composición de partidos pequeños cambia cada año) y, en 2015-2024,
  cualquier partido fuera de PAN/PRI/PRD/MORENA en la pregunta principal
  (sin desagregar PVEM/PT/MC ahí, a diferencia de 1997-2012 donde sí
  pueden resolver directo). NO se usan las variables `pid<año>b` del
  cuestionario: el propio inventario advierte que el significado de sus
  códigos cambia entre olas (código 3 = PRD en 1997, código 3 = MORENA
  en 2021).

- limpieza_electoral:

  Percepción de limpieza de la elección referida por cada ola, escala
  1-5 (1=no fue limpia, 5=sí fue limpia). `NA` si no hubo respuesta
  válida. OJO: en 2003/2006/2018 el `.dta` original NO trae etiquetas de
  valor Stata para los códigos intermedios (2/3/4) – la ordinalidad se
  asume por diseño de la pregunta (tarjeta 1-5), no está confirmada por
  etiqueta directa esos tres años (ver `notas` en
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)).

- satisfaccion_democracia:

  Satisfacción con el funcionamiento de la democracia, escala 1-4
  orientada para que mayor valor = más satisfecho (1=Nada satisfecho,
  4=Muy satisfecho). `NA` si no hubo respuesta válida. El original viene
  en orden inverso en las 10 olas (1=Muy satisfecho); se invirtió para
  mantener la convención "mayor valor = más del concepto" de todo el
  panel.

- asistencia_religiosa:

  Frecuencia de asistencia a servicios religiosos, escala 1-6 orientada
  para que mayor valor = más frecuente (1=Nunca, 6=Una o más veces a la
  semana). `NA` si no hubo respuesta válida. El original SOLO viene en
  orden inverso en 1997/2000 (se invierte esos dos años); desde 2003 ya
  viene en la dirección correcta (sin invertir).

- etnia:

  Autoidentificación étnica/racial: `"Indigena"`, `"Mestizo"`,
  `"Blanco"`, `"Afrodescendiente"` (categoría explícita SOLO desde
  2024), `"Otro"`, o `NA`. `"Otro"` agrupa categorías residuales NO
  comparables entre olas (composición distinta cada año) – no asumir que
  "Otro" antes de 2024 incluye o excluye afrodescendientes de forma
  consistente.

- escolaridad:

  Nivel educativo por bloque: `"Ninguna"`, `"Primaria"`, `"Secundaria"`,
  `"Preparatoria"`, `"Universidad_o_mas"`, o `NA`. Colapsa
  incompleto+completo (y maestría/doctorado en `"Universidad_o_mas"`)
  dentro de cada bloque en las 10 olas, para evitar la ambigüedad de que
  el código "Universidad incompleta" existe como propio en 1997-2009
  pero no existe en el cuestionario desde 2012.

- estado_civil:

  Estado civil: `"Soltero"`, `"Casado_UnionLibre"`,
  `"Divorciado_Separado"`, `"Viudo"`, o `NA`. "Casado" y "Unión libre"
  son categorías separadas en el original 1997-2009 y se agrupan aquí en
  `"Casado_UnionLibre"` para poder comparar contra 2012+, donde el
  cuestionario ya las fusiona en una sola categoría.

- religion:

  Adscripción religiosa: `"Catolica"`, `"Otra"`, `"Ninguna"`, o `NA`.
  Reutiliza la variable ya recodificada por el proveedor (estable en las
  10 olas) en vez de reconstruir desde las ~15-28 categorías de
  denominación de cada año.

- econ_retro:

  Evaluación económica retrospectiva: `"Mejoro"`, `"Igual"`,
  `"Empeoro"`, o `NA`. Colapsa "igual de bien"/"igual de mal" (donde el
  cuestionario los distingue) en una sola categoría `"Igual"`.

- voto_reportado:

  Voto autorreportado en la elección referida por cada ola: `"Si"`,
  `"No"`, o `NA`. La elección referida ALTERNA entre presidencial y
  legislativa cada ola – no tratar como una serie continua de "votó en
  la última elección nacional" sin considerar cuál cargo se disputaba
  (ver `notas` en
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)).

- actividad_principal:

  Clasificación tipo OIT: `"Ocupado"`, `"Desocupado"`,
  `"Fuera_fuerza_laboral"`, o `NA`. Respuestas ambiguas/residuales
  ("Otro") se recodifican a `NA`, no se fuerzan a
  "Fuera_fuerza_laboral".

- conocimiento_camaras:

  Conocimiento de qué cámaras integran el Congreso:
  `"Correcto"`/`"Incorrecto"`/`NA`. En 1997/2000 la variable no
  distingue respuesta incorrecta de no sabe/no contestó (sin código
  NS/NC propio esos dos años).

- conocimiento_diputado_termino:

  Conocimiento de la duración del cargo de diputado federal:
  `"Correcto"`/`"Incorrecto"`/`NA`. En 2000 la variable no distingue
  respuesta incorrecta de no sabe/no contestó (mismo problema que
  `conocimiento_camaras` 2000; 1997 sí distingue).

- conocimiento_gobernador:

  Conocimiento del nombre del gobernador (o Jefe de Gobierno en CDMX):
  `"Correcto"`/`"Incorrecto"`/`NA`. Disponible SOLO en
  2006/2009/2012/2015/2021/2024 – 1997/2000/2003/ 2018 quedan
  deliberadamente sin implementar por ser respuesta abierta sin catálogo
  de gobernadores-por-estado-y-fecha disponible en este paquete para
  validarla.

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
