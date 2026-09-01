test_that("enem_years() regresa las 10 olas", {
  y <- enem_years()
  expect_equal(nrow(y), 10)
  expect_equal(sort(y$anio), c(1997, 2000, 2003, 2006, 2009, 2012, 2015, 2018, 2021, 2024))
})

test_that("enem_design() distingue oficial vs inferido", {
  d_oficial <- enem_design(2009)
  expect_equal(d_oficial$fuente, "Ficha oficial (CSES)")

  d_inferido <- enem_design(2012)
  expect_match(d_inferido$fuente, "INFERIDO")
})

test_that("enem_design() falla con un año que no existe", {
  expect_error(enem_design(1994), "No hay ficha de diseno")
})

test_that("enem_vars() encuentra el ponderador en las 10 olas", {
  res <- enem_vars("PONDERADOR")
  expect_equal(length(unique(res$anio)), 10)
})
