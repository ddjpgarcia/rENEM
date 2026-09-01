# Package index

## Diseño muestral

Metadata de las 10 olas y su ficha de diseño (oficial o inferida cuando
no existe ficha metodológica original).

- [`enem_years()`](https://ddjpgarcia.github.io/rENEM/reference/enem_years.md)
  : Años disponibles en la serie ENEM
- [`enem_design()`](https://ddjpgarcia.github.io/rENEM/reference/enem_design.md)
  : Ficha de diseño muestral de una ola

## Variables y codebook

Búsqueda de variables a través de las 10 olas y el crosswalk armonizado
entre nombres originales y nombres armonizados.

- [`enem_vars()`](https://ddjpgarcia.github.io/rENEM/reference/enem_vars.md)
  : Buscar variables a través de todas las olas
- [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
  [`enem_codebook`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
  : Codebook armonizado de la serie ENEM
- [`enem_occupation_vars()`](https://ddjpgarcia.github.io/rENEM/reference/enem_occupation_vars.md)
  : Variables de ocupación ISCO-08 disponibles en ENEM

## Panel armonizado

El subconjunto de variables comunes a las 10 olas, ya armonizado y
distribuido con el paquete.

- [`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md)
  : Cargar el panel armonizado de ENEM
- [`enem_panel`](https://ddjpgarcia.github.io/rENEM/reference/enem_panel.md)
  : Panel armonizado de ENEM (1997-2024)

## Datos completos

Descarga y conexión a los datos completos de cada ola (todas sus
variables originales), hospedados como GitHub Release.

- [`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)
  : Descargar datos completos de ENEM (todas las olas o algunas)
- [`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md)
  : Abrir una conexión DuckDB a los datos completos de ENEM

## Agregados ponderados

Ayudantes sobre `survey` para calcular medias/proporciones ponderadas
respetando el diseño muestral de ENEM.

- [`enem_svy()`](https://ddjpgarcia.github.io/rENEM/reference/enem_svy.md)
  : Construir un diseño muestral ponderado para datos de ENEM
- [`enem_weighted_summary()`](https://ddjpgarcia.github.io/rENEM/reference/enem_weighted_summary.md)
  : Agregado ponderado de una variable de ENEM
- [`enem_trend()`](https://ddjpgarcia.github.io/rENEM/reference/enem_trend.md)
  : Serie temporal comparada de una variable armonizada
