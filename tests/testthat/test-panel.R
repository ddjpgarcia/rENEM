test_that("enem_codebook() regresa el crosswalk completo y filtra por año", {
  cb <- enem_codebook()
  expect_true(all(c("anio", "concepto", "var_original", "var_armonizada", "disponible", "notas") %in% names(cb)))
  expect_equal(length(unique(cb$anio)), 10)

  cb_2012 <- enem_codebook(2012)
  expect_true(all(cb_2012$anio == 2012))
})

test_that("enem_codebook() marca correctamente lo que no esta disponible", {
  cb <- enem_codebook()
  # 2000 no tiene variable de geografia
  fila <- cb[cb$anio == 2000 & cb$concepto == "municipio", ]
  expect_false(fila$disponible)
  # 2018 no tiene folio
  fila <- cb[cb$anio == 2018 & cb$concepto == "folio", ]
  expect_false(fila$disponible)
})

test_that("enem_load() regresa las 10 olas con las columnas esperadas", {
  panel <- enem_load()
  expect_equal(length(unique(panel$anio)), 10)
  expect_true(all(c("mujer", "edad_grupo", "peso_final", "peso_diseno", "folio_es_id_unico") %in% names(panel)))
  expect_false(anyNA(panel$peso_final))
})

test_that("enem_load() filtra por año", {
  panel <- enem_load(years = 2024)
  expect_true(all(panel$anio == 2024))
  expect_equal(nrow(panel), 2700)
})

test_that("folio_es_id_unico solo es TRUE en 2024", {
  panel <- enem_load()
  por_anio <- tapply(panel$folio_es_id_unico, panel$anio, unique)
  expect_true(por_anio[["2024"]])
  expect_false(any(unlist(por_anio[names(por_anio) != "2024"])))
})

test_that("pdte_acuerdo/pdte_aprueba estan disponibles en las 10 olas y son consistentes entre si", {
  panel <- enem_load()
  expect_true(all(c("pdte_acuerdo", "pdte_aprueba") %in% names(panel)))
  expect_equal(length(unique(panel$anio[!is.na(panel$pdte_acuerdo)])), 10)

  # pdte_acuerdo solo toma valores 1-4 (o NA); los codigos de no respuesta
  # ya deben venir recodificados
  expect_true(all(panel$pdte_acuerdo %in% c(1:4, NA)))

  # pdte_aprueba es el colapso binario de pdte_acuerdo
  ok <- !is.na(panel$pdte_acuerdo)
  expect_equal(panel$pdte_aprueba[ok], as.integer(panel$pdte_acuerdo[ok] %in% c(1, 2)))
  expect_true(all(is.na(panel$pdte_aprueba[!ok])))

  cb <- enem_codebook()
  expect_true(all(cb$disponible[cb$concepto %in% c("aprobacion_pdte", "aprobacion_pdte_binaria")]))
})
