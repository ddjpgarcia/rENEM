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
| `enem_load(years)` | Carga el panel armonizado bundleado (`mujer`, `edad_grupo`, pesos, ISCO-08, aprobación presidencial (`pdte_acuerdo`/`pdte_aprueba`), municipio/fecha/folio parciales) | **Funcional** | — |
| `enem_svy(data, weight)` | Construye [`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html) con `PONDERADOR`/`PONDFIN` sobre datos **completos** de una ola | Funcional (necesita paquete `survey` instalado) | [`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)/[`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md) para tener datos completos que pasarle |
| `enem_weighted_summary(data, var, by)` | Media/proporción ponderada sobre datos completos, con o sin desglose | Funcional (necesita `survey`) | [`enem_svy()`](https://ddjpgarcia.github.io/rENEM/reference/enem_svy.md) |
| `enem_trend(var, years)` | Serie temporal ponderada de una variable del **panel armonizado** (`mujer`, `edad_grupo`, ISCO-08, `pdte_acuerdo`/`pdte_aprueba`) | Funcional (necesita `survey`) | [`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md) |
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
  entrevistado. Revisa la columna `folio_es_id_unico` de `enem_panel`
  antes de usar folio como llave para unir con otra fuente.
- **`pdte_acuerdo` (aprobación presidencial) es una escala de 4 puntos,
  no binaria**, pese al fraseo de la pregunta (“¿de acuerdo o en
  desacuerdo…?”). El nombre de variable cambia en cada ola
  (`p23`/`pacu`/`p28`/`p46`/`pacu`/`p42`/`p48`/`p15`/`P2`/`P2`) y los
  códigos de no respuesta migran (5/6 → 8/9 → 98/99); todo ya
  recodificado. Sin value labels en los `.dta` para confirmar el texto
  exacto de las 4 categorías — dirección (1=Muy de acuerdo … 4=Muy en
  desacuerdo) inferida por consistencia con la evolución histórica
  conocida de aprobación presidencial (confirmado con la tendencia
  ponderada: Zedillo/Fox/AMLO altos, Peña Nieto cayendo a ~21% de
  aprobación en 2018). Usa `pdte_aprueba` (0/1) si solo necesitas el
  colapso binario.

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
