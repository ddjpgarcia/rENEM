# Cómo publicar `enem_data.duckdb` como Release de GitHub

No puedo crear el Release ni subir el archivo yo mismo (no tengo credenciales para actuar en tu cuenta de GitHub) -- estos son los pasos para que lo hagas tú, una sola vez.

## 1. Sube el archivo `.duckdb` a un Release

1. Ve a `https://github.com/ddjpgarcia/rENEM/releases/new` (tu repo ya puede estar en privado, no pasa nada).
2. En **Tag**, escribe exactamente `data-v1` (así lo busca `enem_download()` por default -- si usas otro tag, ajústalo luego con `options(rENEM.data_tag = "tu-tag")`).
3. Título del release: algo como "Datos completos ENEM 1997-2024 (v1)".
4. Arrastra el archivo `enem_data.duckdb` que te mandé a la zona de "Attach binaries".
5. Marca la casilla "Set as a pre-release" si quieres, no es necesario. Publica el release.

## 2. Si el repo es privado: crea un token de acceso (`GITHUB_PAT`)

Mientras el repo esté en privado, descargar el asset del Release requiere autenticación:

1. Ve a `https://github.com/settings/tokens` → **Generate new token** (classic funciona bien) o un *fine-grained token* con permiso de **Contents: Read-only** sobre el repo `rENEM`.
2. Copia el token (solo se muestra una vez).
3. En tu computadora, agrégalo como variable de ambiente para que R lo lea automáticamente. La forma que persiste entre sesiones es un archivo `.Renviron` en tu carpeta de usuario:

```r
usethis::edit_r_environ()  # abre (o crea) el archivo
```

Y agrega esta línea (con tu token real):

```
GITHUB_PAT=ghp_tu_token_aqui
```

Guarda, cierra Positron y vuelve a abrirlo (o corre `readRenviron("~/.Renviron")`) para que la variable quede disponible en la sesión.

**Cuando hagas el repo público más adelante**, ya no vas a necesitar el token para esto (aunque no pasa nada si lo dejas configurado, `enem_download()` lo sigue usando sin problema).

## 3. Probar

```r
devtools::load_all()
ruta <- enem_download()  # deberia descargar ~22 MB la primera vez, y ya quedar en cache
con <- enem_connect()
DBI::dbListTables(con)
DBI::dbGetQuery(con, "SELECT folio, PONDFIN, PONDERADOR FROM enem_2024 LIMIT 5")  # tabla cruda: nombres originales del .dta, sin columna de año
DBI::dbGetQuery(con, "SELECT anio, peso_final FROM enem_panel WHERE anio = 2024 LIMIT 5")  # tabla armonizada: sí trae anio
DBI::dbDisconnect(con, shutdown = TRUE)
```

**Confirmado en vivo** (2026-09-12): tanto `devtools::load_all()` sobre la carpeta local como una instalación real vía `remotes::install_github("ddjpgarcia/rENEM")` (repo público, sin `GITHUB_PAT`) completan este flujo sin errores, con las 15 tablas y los valores esperados.

## Problema común en Windows: "namespace 'rlang' X.X.X is being loaded, but >= Y.Y.Y is required"

Si al instalar o actualizar paquetes ves un error así (a veces durante `remotes::install_github()`, cuando actualiza dependencias de paso), es el mismo problema de fondo casi siempre: una versión vieja de `rlang` (o de cualquier otro paquete) sigue cargada en memoria de una sesión anterior, y Windows no deja sobrescribir su `.dll` mientras está en uso -- verás mensajes como "cannot remove prior installation" o "Permission denied" en la ruta de la librería.

Qué hacer:

- Si el error aparece a mitad de instalar una dependencia (como `httr2` en el log de arriba) pero la instalación de `rENEM` termina bien de todas formas: no pasa nada, R normalmente restaura la versión anterior de ese paquete y sigue -- confírmalo probando `enem_download()`/`enem_connect()` igual, lo más probable es que funcionen.
- Si quieres la versión más reciente de verdad: **reinicia R por completo** (o cierra y abre Positron) antes de instalar, y como primer comando de la sesión (antes de `library()` o cualquier otra cosa) corre `install.packages("<paquete>", type = "binary")`.
- Si sigue sin dejarte incluso recién reiniciado, puede ser que tu carpeta de librería de R requiera permisos de administrador -- instala en una carpeta personal con `.libPaths(Sys.getenv("R_LIBS_USER"))` antes de instalar (ver detalles en `usethis::edit_r_environ()` → variable `R_LIBS_USER`).

Si algo más falla que no sea esto, pega aquí el mensaje de error completo y lo revisamos.
