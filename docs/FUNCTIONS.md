# Lista de funciones de rENEM

Estado a partir del inventario real de las 10 bases
(`Reporte_ENEM_bases_1997_2024.xlsx`) y del crosswalk armonizado ya
construido (`data/enem_codebook.rda`, `data/enem_panel.rda`).
“Funcional” = ya corre de verdad. “Esqueleto” = firma y documentación
listas, cuerpo pendiente de una decisión concreta.

| Función | Qué hace | Estado | Depende de |
|----|----|----|----|
| [`enem_years()`](https://ddjpgarcia.github.io/rENEM/reference/enem_years.md) | Metadata de las 10 olas: n y si el diseño es oficial/inferido | **Funcional** | — |
| `enem_design(year)` | Ficha de diseño muestral de una ola (oficial o inferido) | **Funcional** | — |
| `enem_vars(pattern, years)` | Busca variables por nombre/etiqueta en las 10 olas | **Funcional** | — |
| `enem_occupation_vars(data)` | Identifica las columnas ISCO-08 en un data.frame | **Funcional** | — |
| `enem_codebook(year)` | Crosswalk var. original ↔︎ var. armonizada, con notas de qué no está disponible/armonizado | **Funcional** | — |
| `enem_load(years)` | Carga el panel armonizado bundleado (`mujer`, `edad_grupo`, pesos, ISCO-08, aprobación presidencial (`pdte_acuerdo`/`pdte_aprueba`), ideología propia (`ideologia_lr`), evaluación de partidos (`eval_pan`/`eval_prd`/`eval_pri`/`eval_pt`/`eval_pvem`), ubicación izquierda-derecha DE cada partido (`ideologia_pan`/`ideologia_prd`/`ideologia_pri`/`ideologia_pt`/`ideologia_pvem`), identificación partidista (`pid_partido`), limpieza electoral (`limpieza_electoral`), satisfacción con la democracia (`satisfaccion_democracia`), asistencia religiosa (`asistencia_religiosa`), demografía adicional (`etnia`, `escolaridad`, `estado_civil`, `religion`), evaluación económica retrospectiva (`econ_retro`), voto reportado (`voto_reportado`), actividad principal (`actividad_principal`), conocimiento político (`conocimiento_camaras`, `conocimiento_diputado_termino`, `conocimiento_gobernador`), `id_ola`/`id_panel`, municipio/fecha/folio parciales) | **Funcional** | — |
| `enem_svy(data, weight)` | Construye [`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html) con `PONDERADOR`/`PONDFIN` sobre datos **completos** de una ola | Funcional (necesita paquete `survey` instalado) | [`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)/[`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md) para tener datos completos que pasarle |
| `enem_weighted_summary(data, var, by)` | Media/proporción ponderada sobre datos completos, con o sin desglose | Funcional (necesita `survey`) | [`enem_svy()`](https://ddjpgarcia.github.io/rENEM/reference/enem_svy.md) |
| `enem_trend(var, years)` | Serie temporal ponderada de una variable del **panel armonizado** (cualquier columna numérica de [`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md), p.ej. `pdte_aprueba`, `eval_pri`, `ideologia_pan`) | Funcional (necesita `survey`) | [`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md) |
| `enem_download(year, format)` | Descarga (cachea) `enem_data.duckdb` y opcionalmente exporta a dta/csv | **Funcional, probado en vivo** | Release publicado en GitHub (`SETUP_RELEASE.md`) |
| `enem_connect(years)` | Conexión DuckDB de solo lectura a los datos completos (10 tablas `enem_<año>` + `enem_panel` + metadata) | **Funcional, probado en vivo** | [`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md) |

### Sobre “probado en vivo”

Confirmado por Dan corriendo
[`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)
y
[`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md)
contra el Release real (repo público, sin necesidad de `GITHUB_PAT`).
Dos cosas que salieron de esa primera prueba y ya quedaron corregidas:

- Un bug real en `R/download.R`: los mensajes de
  [`cli::cli_inform()`](https://cli.r-lib.org/reference/cli_abort.html)
  interpolaban `.enem_gh_repo`/`.enem_gh_asset_name` (nombres internos
  que empiezan con punto) directamente dentro de `{...}}`, y `cli`
  (desde 3.4) interpreta eso como un estilo especial, no una variable –
  tronaba con “Invalid cli literal”. Arreglado pasándolos primero a
  variables locales sin punto.
- Un error mío en la documentación/ejemplos: las tablas crudas
  `enem_<año>` conservan los nombres de columna originales del `.dta` de
  cada ola y **no** tienen una columna `anio` (el año es el nombre de la
  tabla, no una columna) – mi ejemplo
  `SELECT anio, PONDFIN FROM enem_2024` estaba mal.
  `PONDFIN`/`PONDERADOR` sí existen tal cual en las tablas crudas;
  `anio` solo existe en `enem_panel`. Ejemplos corregidos en
  `R/download.R` y `SETUP_RELEASE.md`.

## Cómo se construyeron los datos bundleados

`data/enem_codebook.rda` y `data/enem_panel.rda` mapean, para las
variables que sí cambian de nombre entre olas (sexo, edad, municipio,
fecha, folio, aprobación presidencial), la variable original de cada año
a un nombre armonizado. El mapeo está documentado con detalle en los
comentarios de `data-raw/build_codebook.R` — hallazgos importantes que
vale la pena tener presentes al trabajar con `enem_panel`:

- **El número de pregunta de sexo/edad se invierte a partir de 2012.**
  En 2003-2009 sexo es la pregunta “1” (`s1`/`ps1`) y edad la “2”; desde
  2012 se invirtió. `enem_load()$mujer` ya resuelve esto (usa
  `female<año>`, que el proveedor de datos ya recodificó correctamente
  en cada ola) — pero si en algún momento trabajas directo con los
  `.dta` crudos vía
  [`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md),
  NO asumas que `s1`/`S1` siempre es sexo.
- **`folio` no es un identificador único de respondiente en 8 de las 10
  olas** — solo en 2024 identifica de forma inequívoca a cada
  entrevistado. Usa **`id_ola`/`id_panel`** en su lugar: la columna
  cruda `id` (distinta de `folio`) sí es única dentro de cada una de las
  10 olas (confirmado por conteo distinto == n filas en las 10 bases);
  `id_panel` = `anio + "_" + id_ola` es la llave compuesta recomendada
  para unir `enem_panel` con otras fuentes por ola.
- **`pdte_acuerdo` (aprobación presidencial) es una escala de 4 puntos,
  no binaria**, pese al fraseo de la pregunta (“¿de acuerdo o en
  desacuerdo…?”). El nombre de variable cambia en cada ola
  (`p23`/`pacu`/`p28`/`p46`/`pacu`/`p42`/`p48`/`p15`/`P2`/`P2`) y los
  códigos de no respuesta migran (5/6 → 8/9 → 98/99); todo ya
  recodificado. La escala armonizada quedó orientada 1=Muy en desacuerdo
  … 4=Muy de acuerdo (mayor valor = mayor aprobación) — el original
  venía en orden inverso; se invirtió (v15) para dejar una convención
  consistente de “mayor valor = más del concepto” en todo el panel, tras
  cruzar con un inventario metodológico externo
  (`ENEM_candidatos_armonizacion_1997_2024.xlsx`, construido citando
  cuestionario PDF por página) que confirma las mismas 10 variables por
  año y propone esa misma inversión. Usa `pdte_aprueba` (0/1) si solo
  necesitas el colapso binario.
- **Hay un inventario metodológico más amplio**
  (`ENEM_candidatos_armonizacion_1997_2024.xlsx`, en la máquina de Dan,
  fuera de este repo) que identifica 51 conceptos candidatos a armonizar
  (demografía, partidos, elecciones, opinión, conocimiento político,
  etc.), clasificados por qué tan seguro es adoptarlos. El plan de fases
  para incorporarlos está en el doc del proyecto “rENEM package”
  (`plan-dataset-principal.md`) — ver ahí antes de agregar la siguiente
  variable de opinión.
- **`ideologia_lr`, `eval_pan`, `eval_prd`, `eval_pri` (v16, Fase 2 del
  plan)**: escalas 0-10 conservadas tal cual (0=izquierda/no le gusta
  nada, 10=derecha/le gusta mucho), sin invertir — a diferencia de
  `pdte_acuerdo`, aquí la regla del inventario es “Conservar 0-10”, no
  invertir. El nombre de variable cambia en cada ola (ver
  `data-raw/build_codebook.R`, objeto `escalas_0_10`); cualquier código
  fuera de 0-10 se recodifica a `NA` (NS/NC/“no lo conozco lo
  suficiente”/“nunca ha oído del partido”/“no aplica por versión”, varía
  por año — detalle exacto en la hoja `Codigos` del inventario).
  Detectamos al revisar los códigos que en 2012/2015 el código 96
  (“Nunca ha oído del partido”) venía mal clasificado como
  “Respuesta/categoría” en el inventario en vez de “Especial” — no
  afectó la implementación porque la regla usada es “válido solo si
  0-10”, que excluye 96 sin depender de esa clasificación. Sanity check
  con la tendencia ponderada: `eval_pri` cae de ~6.6 (2009, previo a su
  regreso al poder) a ~2.6 (2021/2024, tras su colapso); `eval_pan` cae
  de ~6.6 (2000, sexenio de Fox) a ~3.1 (2024); consistente con la
  historia política conocida.
- **`eval_pt`, `eval_pvem`, `ideologia_pan/prd/pri/pt/pvem`,
  `pid_partido` (Fase 3, subgrupo “Partidos/ideología”)**:
  `eval_pt`/`eval_pvem` son mecánicos, mismo patrón que
  `eval_pan/prd/pri` de Fase 2 (misma escala 0-10, mismo objeto
  `escalas_0_10`). Las 5 `ideologia_<partido>` (ubicación
  izquierda-derecha **de cada partido** según el entrevistado — no
  confundir con `ideologia_lr`, que es la autoubicación del propio
  entrevistado) siguen el mismo patrón 0-10, PERO **2018 almacena estas
  5 columnas con códigos 1-11 en vez de 0-10** (código 1 = respuesta
  “0”, …, código 11 = respuesta “10”; confirmado contra la hoja
  `Codigos` del inventario) — corregido con `escalas_0_10_offsets` en
  `build_codebook.R`, que resta el desplazamiento antes de validar 0-10.
  `pid_partido` es la más delicada de las 8: el **diseño de la pregunta
  cambia entre olas**, no solo el nombre de la variable. En 1997-2012
  hay un filtro binario (“¿simpatiza con algún partido? Sí/No/NS/NC”) y,
  solo si contestó “Sí”, una pregunta de “¿con cuál?” (primera mención);
  confirmamos por crosstab directo contra los `.dta` que quienes
  contestan “No” al filtro **siempre** quedan sin dato en la variable de
  partido (sistema-perdido en la mayoría de las olas, pero con un código
  centinela propio — `0` en 2003, `998` en 2009 — en vez de
  sistema-perdido en esas dos). Por eso `pid_partido` se reconstruye
  leyendo el filtro, no solo la variable de partido: es la única forma
  confiable de distinguir `"Ninguno"` (contestó “No” al filtro) de `NA`
  (no supo/no contestó el filtro mismo). En 2015-2024 no hay filtro
  separado: una sola batería (“se considera panista/priista/…/de otro
  partido, mucho o algo”) ya trae Otro/Ninguno/NS/NC como categorías
  explícitas. `"Otro"` agrupa partidos minoritarios que NO son
  comparables entre olas (composición distinta cada año) y, en
  2015-2024, cualquier partido fuera de PAN/PRI/PRD/MORENA en la
  pregunta principal (sin desagregar ahí PVEM/PT/MC, a diferencia de
  1997-2012 donde la primera mención sí puede resolver directo a esos
  partidos). Deliberadamente **no se usan** las variables `pid<año>b`
  del cuestionario (ya colapsadas por el proveedor): el propio
  inventario advierte que el significado de sus códigos cambia entre
  olas (código 3 = PRD en `pid1997b`, código 3 = MORENA en `pid2021b`).
  Sanity check: `pid_partido == "MORENA"` solo aparece desde 2018 (el
  partido no existía/no competía antes), consistente con la historia
  política conocida.
- **Fase 3, cierre (subgrupos “Elecciones/opinión pública” restante,
  “Demografía”, “Conocimiento político”, “Religión/trabajo”) — 11
  conceptos más**: `procesar_ola.R` se generalizó con dos mecanismos
  genéricos reutilizables para el resto del plan: (1) `escalas_0_10`
  ahora acepta un `rango` propio por concepto (antes fijo a 0-10) y un
  flag `invertir` por año (antes solo existía el offset), sin tocar el
  comportamiento de los conceptos ya existentes que no usan esas
  opciones nuevas; y (2) un nuevo bloque `recodes_categoricas`
  generaliza el patrón “directo” que ya usaba `pid_partido`, para
  conceptos con una variable y un mapa fijo de código→categoría por año
  (sin lógica de filtro).
  - **Vía el `escalas_0_10` generalizado**: `limpieza_electoral` (rango
    1-5, sin invertir; OJO: en 2003/2006/2018 el `.dta` no trae
    etiquetas de valor Stata para los códigos intermedios 2/3/4 – la
    ordinalidad 1..5 se asume por diseño de tarjeta, no está confirmada
    por etiqueta en esos tres años). `satisfaccion_democracia` (rango
    1-4, invertida en las 10 olas: el original siempre viene 1=Muy
    satisfecho…4=Nada satisfecho). `asistencia_religiosa` (rango 1-6,
    invertida SOLO en 1997/2000 – el resto ya viene en la dirección
    correcta; el rango por sí mismo ya descarta los códigos especiales
    de no-respuesta de cada año sin necesitar casos especiales, incluido
    el quirk de 2018 que usa 7/8 en vez de 8/9).
  - **Vía `recodes_categoricas`**: `etnia`
    (Indigena/Mestizo/Blanco/Afrodescendiente\[solo 2024\]/Otro – “Otro”
    NO comparable entre olas por composición distinta cada año, según
    advierte el propio inventario). `escolaridad`
    (Ninguna/Primaria/Secundaria/Preparatoria/Universidad_o_mas,
    colapsando incompleta+completa dentro de cada bloque en las 10 olas
    para esquivar que el código “Universidad incompleta” existe en
    1997-2009 pero desaparece del cuestionario desde 2012).
    `estado_civil` (Soltero/Casado_UnionLibre/Divorciado_Separado/Viudo
    – “Casado” y “Unión libre” son códigos separados en 1997-2009 y se
    funden aquí para poder comparar contra 2012+, donde el cuestionario
    ya los fusiona; el código numérico de cada categoría también cambia
    de orden entre las dos eras, el mapeo es por etiqueta, no por código
    compartido). `religion` (Catolica/Otra/Ninguna, reutilizando la
    variable YA recodificada por el proveedor – `religion<año>b`,
    estable en las 10 olas – en vez de reconstruir desde las ~15-28
    categorías de denominación por año, que el inventario no lista
    completas; **el nombre exacto de esa variable se infiere por
    analogía y no está confirmado contra el `.dta`, verificar antes de
    confiar en la columna**). `econ_retro` (Mejoro/Igual/Empeoro,
    colapsando “igual de bien”/“igual de mal” en los años que distinguen
    intensidad; OJO 2006 tiene ~50% de missing del sistema y 2015 ~50%
    de “no aplica por versión” en esta pregunta – usar con cautela esos
    dos años). `voto_reportado` (Si/No; la elección referida ALTERNA
    entre presidencial y legislativa cada ola, no es una serie continua
    de “votó en la última elección nacional”). `actividad_principal`
    (clasificación tipo OIT: Ocupado/Desocupado/Fuera_fuerza_laboral;
    residuales ambiguos como “Otro” se recodifican a NA en vez de
    forzarse a alguna categoría). `conocimiento_camaras` y
    `conocimiento_diputado_termino` (Correcto/Incorrecto sobre las
    cámaras del Congreso y la duración del cargo de diputado; en 2000
    ambos, y en 1997 solo `conocimiento_camaras`, la variable no tiene
    código NS/NC propio y por lo tanto mezcla respuesta incorrecta real
    con no sabe/no contestó – `conocimiento_diputado_termino` 1997 SÍ
    distingue ambos casos, no asumir la misma limitación para los dos
    conceptos ese año). `conocimiento_gobernador` (Correcto/Incorrecto,
    implementado deliberadamente SOLO en 2006/2009/2012/2015/2021/2024 –
    los únicos años con indicador pre-validado por el proveedor;
    1997/2000/2003/2018 son respuesta abierta sin catálogo de
    gobernadores-por-estado-y-fecha disponible en este paquete para
    validarlos, así que se dejaron sin implementar en vez de adivinar).
  - **Pendiente, no implementado en esta fase**: `tipo_seccion`
    (urban/rural/mixta de la sección electoral). El mapeo de códigos SÍ
    quedó resuelto (1997/2000 solo Rural/Urbana con el mismo dígito
    significando lo opuesto que 2003+; desde 2003 hay
    Rural/Mixta/Urbana), pero el **nombre real de la variable fuente no
    está confirmado** en el inventario para 7 de los 10 años (el
    inventario mismo marca el método de localización como “No localizado
    automáticamente” para este concepto en todos los años) – a
    diferencia de otros conceptos, adivinar aquí un nombre de columna
    equivocado arriesga colisionar con una variable no relacionada y
    producir datos silenciosamente incorrectos, así que se dejó
    pendiente hasta confirmar los nombres reales contra los `.dta`
    crudos. También se investigó la nota del inventario “2018 contiene
    duplicados” sobre `conocimiento_camaras`/chambers, sin poder
    corroborarla en ningún otro lado del inventario (ids únicos, sin
    variable ni filas duplicadas visibles) – queda pendiente de revisar
    directo contra el `.dta` crudo de 2018. `age_group` no necesitó
    código nuevo: ya está resuelto por `edad_grupo`/`age<año>b`.

## Ideas para siguientes funciones (no empezadas)

- `enem_compare_waves(var, years)` — tabla cruda comparando una variable
  entre olas específicas, sin ponderar (complementa
  [`enem_trend()`](https://ddjpgarcia.github.io/rENEM/reference/enem_trend.md)).
- Un
  [`print()`](https://rdrr.io/r/base/print.html)/[`summary()`](https://rdrr.io/r/base/summary.html)
  method para el objeto que regrese
  [`enem_design()`](https://ddjpgarcia.github.io/rENEM/reference/enem_design.md),
  para que se lea bien en consola en vez de como lista plana.
- Ampliar `enem_panel` con más variables sustantivas de opinión (voto,
  por ejemplo) una vez que se decida cómo armonizarlas entre olas.
- Recuperar la sección electoral como UPM en
  [`enem_svy()`](https://ddjpgarcia.github.io/rENEM/reference/enem_svy.md)
  si se logra ubicar esa variable en los `.dta` (hoy el diseño se trata
  como muestreo aleatorio simple ponderado).
