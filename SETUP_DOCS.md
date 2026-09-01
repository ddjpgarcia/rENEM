# Cómo generar las páginas de ayuda y el sitio de referencia

Ya dejé listos los comentarios roxygen de cada función (en `R/*.R`), el índice
de referencia (`_pkgdown.yml`) y una sección de referencia en el `README.md`.
Lo que falta son dos comandos que generan archivos derivados -- no los pude
correr yo porque necesitan `roxygen2` y `pkgdown` instalados, y en mi entorno
de verificación CRAN está bloqueado. Estos son los pasos, en Positron.

## 1. Generar las páginas de ayuda (`man/*.Rd`)

```r
install.packages(c("roxygen2", "pkgdown"), type = "binary")  # si no los tienes
devtools::document()
```

Esto lee los comentarios `#'` de cada función en `R/` y genera un archivo
`.Rd` por función en `man/` (así funciona `?enem_download` en la consola).
También regenera `NAMESPACE` -- no debería cambiar nada ahí porque ya está
sincronizado a mano con los `@export` actuales, pero si `devtools::document()`
lo modifica, es la versión correcta (la generada automáticamente siempre gana
sobre la escrita a mano).

Prueba que funcionó:

```r
devtools::load_all()
?enem_download
?enem_years
```

## 2. Construir el sitio de referencia (pkgdown)

```r
pkgdown::build_site()
```

Esto usa `_pkgdown.yml` (ya está en el repo, con las funciones agrupadas en
Diseño muestral / Variables y codebook / Panel armonizado / Datos completos /
Agregados ponderados) y genera una carpeta `docs/` con el sitio HTML
completo -- portada, referencia de funciones, etc.

## 3. Publicarlo con GitHub Pages

1. Confirma que `docs/` **no** está en `.gitignore` (ya lo quité) y súbela al
   repo:
   ```
   git add man/ NAMESPACE docs/ _pkgdown.yml R/ README.md
   git commit -m "Documentación: paginas de ayuda + sitio pkgdown"
   git push
   ```
2. En GitHub, ve a `Settings → Pages` del repo.
3. En **Source**, elige `Deploy from a branch`.
4. En **Branch**, elige `main` y la carpeta `/docs`. Guarda.
5. En un par de minutos el sitio queda publicado en
   `https://ddjpgarcia.github.io/rENEM/` (ya es la URL que puse en
   `_pkgdown.yml` y en `DESCRIPTION`).

Nota: si el repo sigue en privado, GitHub Pages funciona igual, pero el sitio
público solo es visible para quien tenga acceso al repo (o no será accesible
del todo, según tu plan de GitHub) -- si quieres que la documentación sea
pública desde ya aunque los datos sigan privados, dímelo y lo ajustamos (son
cosas independientes: el Release de datos privado no depende de que Pages
esté público).

## 4. Cada vez que cambies una función

Repite el paso 1 (`devtools::document()`) y el paso 2
(`pkgdown::build_site()`) antes de subir a GitHub, para que `man/`, `NAMESPACE`
y `docs/` no queden desactualizados respecto al código.
