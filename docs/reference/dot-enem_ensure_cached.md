# Descargar (o localizar en caché) el archivo completo de datos de ENEM

Se asegura de que `enem_data.duckdb` – el archivo con los datos
completos de las 10 olas – esté disponible localmente, descargándolo del
Release de GitHub si hace falta. El repo puede ser privado: si la
variable de ambiente `GITHUB_PAT` está definida, se usa para autenticar
la descarga vía la API de GitHub; si el repo es público, no hace falta
token.

## Usage

``` r
.enem_ensure_cached(overwrite = FALSE)
```
