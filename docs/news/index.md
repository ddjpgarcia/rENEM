# Changelog

## rENEM 0.1.0

Primera versión pública.

### Panel armonizado

- [`enem_load()`](https://ddjpgarcia.github.io/rENEM/reference/enem_load.md)
  entrega `enem_panel`: panel armonizado con las 10 encuestas ENEM
  (1997-2024), incluido con el paquete.
- Más de 40 variables armonizadas entre olas, agrupadas por tema: diseño
  y llaves (`anio`, `mujer`, `edad_grupo`, pesos, ocupación ISCO-08),
  geografía/fecha/folio, aprobación y evaluación política
  (`pdte_aprueba`, `ideologia_lr`, evaluación de partidos,
  `pid_partido`), elecciones y opinión pública (`limpieza_electoral`,
  `satisfaccion_democracia`, `econ_retro`, `voto_reportado`), demografía
  adicional (`etnia`, `escolaridad`, `estado_civil`, `religion`,
  `actividad_principal`, `asistencia_religiosa`) y conocimiento político
  (`conocimiento_camaras`, `conocimiento_diputado_termino`,
  `conocimiento_gobernador`).
- [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md):
  crosswalk armonizado variable original → variable armonizada por año,
  con notas de disponibilidad y límites de comparabilidad.
- Convención de orientación “mayor valor = más del concepto” aplicada de
  forma consistente en todas las escalas ordinales del panel
  (documentada donde una escala se invirtió respecto al original).

### Datos completos y diseño muestral

- [`enem_download()`](https://ddjpgarcia.github.io/rENEM/reference/enem_download.md)/[`enem_connect()`](https://ddjpgarcia.github.io/rENEM/reference/enem_connect.md):
  descarga y conexión DuckDB de solo lectura a los datos completos de
  cada ola (todas sus variables originales), distribuidos como GitHub
  Release.
- [`enem_years()`](https://ddjpgarcia.github.io/rENEM/reference/enem_years.md)/[`enem_design()`](https://ddjpgarcia.github.io/rENEM/reference/enem_design.md):
  metadata y ficha de diseño muestral de cada encuesta (oficial para
  1997-2009/2018; inferida y marcada explícitamente como tal para
  2012/2015/2021/2024).
- [`enem_vars()`](https://ddjpgarcia.github.io/rENEM/reference/enem_vars.md)/[`enem_occupation_vars()`](https://ddjpgarcia.github.io/rENEM/reference/enem_occupation_vars.md):
  búsqueda de variables por nombre/etiqueta a través de las 10 encuestas
  e identificación de columnas de ocupación ISCO-08.

### Agregados ponderados

- [`enem_svy()`](https://ddjpgarcia.github.io/rENEM/reference/enem_svy.md),
  [`enem_weighted_summary()`](https://ddjpgarcia.github.io/rENEM/reference/enem_weighted_summary.md),
  [`enem_trend()`](https://ddjpgarcia.github.io/rENEM/reference/enem_trend.md):
  ayudantes sobre el paquete `survey` para medias/proporciones
  ponderadas y series de tendencia respetando el diseño muestral.

### Documentación

- `README.md` y sitio pkgdown con guía de instalación, referencia de
  funciones y advertencias metodológicas.
- `FUNCTIONS.md` con el detalle metodológico completo variable por
  variable (códigos originales, inversión de escala, límites de
  comparabilidad entre eras del cuestionario).

### Limitaciones conocidas

- `tipo_seccion` (urbana/rural/mixta) todavía no está disponible: el
  nombre real de su variable fuente no está confirmado en 7 de las 10
  olas.
- Algunas variables no cubren las 10 encuestas por diseño (p. ej.
  `conocimiento_gobernador`, disponible en 6/10);
  [`enem_codebook()`](https://ddjpgarcia.github.io/rENEM/reference/enem_codebook.md)
  marca explícitamente estos casos.
