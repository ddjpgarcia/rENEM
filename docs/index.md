# rENEM

`rENEM` facilita el acceso, limpieza y análisis de datos del **Estudio
Nacional Electoral de México (ENEM)**: 10 encuestas post-electorales
aplicadas a nivel nacional cada 3 años junto con las elecciones
federales para Cámara de Diputados (1997, 2000, 2003, 2006, 2009, 2012,
2015, 2018, 2021, 2024). La ola 2018 fue un panel con 4 mediciones (pre
y post electoral); el resto son de corte transversal, aplicadas después
de cada elección.

Historia del estudio: hasta 2018 el diseño y levantamiento fueron
liderados por el CIDE (Centro de Investigación y Docencia Económicas),
con Ipsos como responsable de campo en la ola panel de 2018. La ola 2024
la realizó un consorcio internacional (El Colegio de México, University
of Massachusetts, University of Connecticut).

## Instalación

``` r

# remotes::install_github("ddjpgarcia/rENEM")  # cuando el repo esté publicado
devtools::load_all()  # durante desarrollo
```

## Estado del proyecto

Este paquete está en desarrollo activo. Lo que ya funciona:

- [`enem_years()`](https://ddjpgarcia.github.io/rENEM/reference/enem_years.md)
  — metadata de las 10 olas (n, si el diseño es oficial o inferido).
- `enem_design(year)` — ficha de diseño muestral de una ola.
- `enem_vars(pattern)` — buscar variables por nombre/etiqueta a través
  de las 10 olas.
- `enem_codebook(year)` — crosswalk armonizado: qué variable original
  corresponde a cada variable armonizada, por año, con notas de qué no
  está disponible.
- `enem_load(years)` — carga `enem_panel`, el panel armonizado (sexo,
  edad agrupada, pesos, ocupación ISCO-08, y municipio/fecha/folio donde
  existen).
- `enem_trend(var, years)` / `enem_svy(data)` /
  `enem_weighted_summary(data, var)` — agregados ponderados (necesitan
  el paquete `survey` instalado).
- `enem_occupation_vars(data)` — identifica las columnas de ocupación
  ISCO-08 (también ya vienen con nombre consistente entre olas).

Lo que todavía falta (ver `FUNCTIONS.md`):

- Ampliar el panel armonizado con variables sustantivas de opinión
  (voto, aprobación) — hoy solo trae demografía + ocupación +
  geografía/fecha/folio parciales.
- Páginas de ayuda `.Rd` (correr
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html))
  y sitio de referencia pkgdown publicado.

## Referencia de funciones

### Diseño muestral

**[`enem_years()`](https://ddjpgarcia.github.io/rENEM/reference/enem_years.md)**
— metadata de las 10 olas: tamaño de muestra y si el diseño es oficial o
inferido.

``` r

enem_years()
```

**`enem_design(year)`** — ficha de diseño muestral completa de una ola.

``` r

enem_design(2009)   # ficha oficial
enem_design(2012)   # diseño inferido, sin ficha metodológica original
```

### Variables y codebook

**`enem_vars(pattern, years = NULL)`** — busca variables por nombre o
etiqueta a través de las 10 olas.

``` r

enem_vars("pond")
enem_vars("voto|partido", years = c(2018, 2021, 2024))
```

**`enem_codebook(year = NULL)`** — crosswalk armonizado: qué variable
original corresponde a cada variable armonizada, por año, con notas de
qué no está disponible.

``` r

enem_codebook()
enem_codebook(2012)
```

**`enem_occupation_vars(data)`** — identifica las columnas de ocupación
ISCO-08 en un `data.frame`, ya consistentes entre olas.

``` r

enem_occupation_vars(datos_2015)
```

### Panel armonizado

**`enem_load(years = NULL)`** — carga `enem_panel`, el panel armonizado
bundleado con el paquete (sexo, edad agrupada, pesos, ocupación,
geografía/fecha/folio parciales).

``` r

enem_load()
enem_load(years = c(1997, 2024))
```

### Datos completos

**`enem_download(year = NULL, format = "duckdb")`** — descarga (y cachea
localmente) el archivo completo de datos; opcionalmente exporta a
`.dta`/`.csv`.

``` r

enem_download()                       # ruta al .duckdb completo, cacheado
enem_download(2024, format = "csv")
```

**`enem_connect(years = NULL)`** — abre una conexión DuckDB de solo
lectura a los datos completos (10 tablas `enem_<año>` + `enem_panel` +
metadata).

``` r

con <- enem_connect()
DBI::dbListTables(con)
DBI::dbGetQuery(con, "SELECT folio, PONDFIN, PONDERADOR FROM enem_2024 LIMIT 5")
DBI::dbDisconnect(con, shutdown = TRUE)
```

### Agregados ponderados

Requieren el paquete `survey` instalado.

**`enem_svy(data, weight = "PONDFIN")`** — construye un
[`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html)
sobre datos completos de una ola.

``` r

d <- enem_svy(datos_2024)
survey::svymean(~EDAD, d, na.rm = TRUE)
```

**`enem_weighted_summary(data, var, by = NULL, weight = "PONDFIN")`** —
media/proporción ponderada, con o sin desglose.

``` r

enem_weighted_summary(datos_2024, "EDAD", by = "EDO")
```

**`enem_trend(var, years = NULL)`** — serie temporal ponderada de una
variable del panel armonizado.

``` r

enem_trend("mujer")   # deberia rondar 50-55% en todas las olas
```

## Diseño muestral: oficial vs. inferido

Para 1997, 2000, 2003, 2006, 2009 y 2018 existe ficha metodológica/nota
técnica oficial. Para **2012, 2015, 2021 y 2024 no hay ficha** — el
diseño en
[`enem_design()`](https://ddjpgarcia.github.io/rENEM/reference/enem_design.md)
para esos años se reconstruyó a partir del cuestionario y de las
variables de peso/geografía presentes en los datos, y está marcado
explícitamente como `"INFERIDO"` en el campo `fuente`. No lo cites como
si fuera un dato oficial de metodología.

Nota adicional: para 2021 y 2024, el protocolo de selección de
respondente que sí está documentado para 2009/2012/2015/2018 (listar a
los miembros del hogar 18+ y elegir al de cumpleaños más reciente) no se
confirmó en el cuestionario — no asumas que el modo de aplicación es
idéntico al de años anteriores sin verificarlo.

## Codebook armonizado: dos trampas a tener presentes

- **El número de pregunta de sexo/edad se invierte a partir de 2012.**
  En 2003-2009 sexo es la pregunta “1” y edad la “2”; desde 2012 se
  invirtió. `enem_load()$mujer` ya usa la variable pre-recodificada
  (`female<año>`) que resuelve esto — pero si trabajas directo con los
  `.dta` crudos vía
  [`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md),
  no asumas que `s1`/`S1` siempre es sexo.
- **`folio` no identifica de forma única a cada respondiente** en 8 de
  las 10 olas (se repite entre filas) — solo en 2024 sí es un ID único.
  Revisa `folio_es_id_unico` en `enem_panel` antes de usarlo como llave.

Ver `data-raw/build_codebook.R` para el mapeo completo, año por año, y
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
para consultarlo desde R.

## Estructura del repositorio

    rENEM/
    ├── R/                # código del paquete
    ├── data/               # enem_panel.rda, enem_codebook.rda (panel y crosswalk armonizados)
    ├── data-raw/          # scripts que construyen data/ a partir de los .dta originales
    ├── inst/extdata/       # inventario de variables y ficha de diseño (csv), fuente de enem_vars()/enem_design()
    ├── tests/testthat/     # pruebas unitarias
    └── .github/workflows/  # CI (R CMD check)

Los 10 `.dta` originales, los cuestionarios y las notas metodológicas
**no viven en este repo** (son ~63 MB y algunos años no tienen licencia
clara de redistribución) — se procesan localmente vía `data-raw/` y solo
el panel armonizado pequeño (aún por construir) se distribuirá con el
paquete.

## Licencia

MIT © Daniel García
