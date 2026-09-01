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
