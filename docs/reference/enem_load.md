# Cargar el panel armonizado de ENEM

Carga `enem_panel`, el panel armonizado pequeño que se distribuye con el
paquete: variables comunes a las 10 olas (`mujer`, `edad_grupo`, peso de
diseño y final, ocupación ISCO-08, aprobación presidencial, y
geografía/fecha/folio cuando existen – ver
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
para qué está disponible en cada año y con qué advertencias). Para los
datos completos de una ola (todas sus variables originales), usa
[`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)
/
[`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md).

## Usage

``` r
enem_load(years = NULL)
```

## Arguments

- years:

  Entero o vector de enteros opcional. Si se especifica, regresa solo
  esas olas del panel.

## Value

Un `data.frame` largo, con una fila por entrevistado y una columna
`anio`.

## Advertencias importantes

`mujer` y `edad_grupo` vienen de variables ya recodificadas en los
`.dta` originales (`female<año>`, `age<año>b`); sus etiquetas de valor
confirman la convención estándar (`mujer`: 0=hombre/1=mujer;
`edad_grupo`: 1-4, de menor a mayor). `municipio_original` y
`fecha_original` NO están armonizados entre años (mismos códigos no son
comparables entre olas) y pueden ser `NA` (no existen en 2000 y en
1997/2000/2003/2006/2012 respectivamente). `folio_original` NO es un
identificador único de respondiente salvo en 2024 – ver la columna
`folio_es_id_unico`; para una llave única en las 10 olas usa
`id_ola`/`id_panel` en su lugar (`id_panel` no es longitudinal entre
olas, solo garantiza unicidad dentro de cada una). `pdte_acuerdo`
(aprobación presidencial) es una escala de 4 puntos orientada para que
mayor valor = mayor aprobación (1=Muy en desacuerdo ... 4=Muy de
acuerdo) – ver `notas` en
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
para el detalle de por qué se invirtió respecto al código original; usa
`pdte_aprueba` para el colapso binario (1=aprueba, 0=desaprueba).
`ideologia_lr`, `eval_pan`, `eval_prd` y `eval_pri` son escalas 0-10
conservadas tal cual (sin invertir); cualquier código de no respuesta o
"no conoce lo suficiente" ya está recodificado a `NA` – ver `notas` en
[`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
para el detalle exacto por año.

## Examples

``` r
if (FALSE) { # \dontrun{
enem_load()
enem_load(years = c(1997, 2024))
} # }
```
