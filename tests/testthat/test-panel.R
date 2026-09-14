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

  # pdte_aprueba es el colapso binario de pdte_acuerdo (mayor valor = mas
  # aprobacion: 3-4 = aprueba, 1-2 = desaprueba)
  ok <- !is.na(panel$pdte_acuerdo)
  expect_equal(panel$pdte_aprueba[ok], as.integer(panel$pdte_acuerdo[ok] %in% c(3, 4)))
  expect_true(all(is.na(panel$pdte_aprueba[!ok])))

  cb <- enem_codebook()
  expect_true(all(cb$disponible[cb$concepto %in% c("aprobacion_pdte", "aprobacion_pdte_binaria")]))
})

test_that("id_ola es unico dentro de cada ola y id_panel es unico en todo el panel", {
  panel <- enem_load()
  expect_true(all(c("id_ola", "id_panel") %in% names(panel)))
  por_anio_unico <- tapply(panel$id_ola, panel$anio, function(x) length(unique(x)) == length(x))
  expect_true(all(unlist(por_anio_unico)))
  expect_equal(length(unique(panel$id_panel)), nrow(panel))
})

test_that("ideologia_lr/eval_pan/eval_prd/eval_pri estan en escala 0-10 en las 10 olas", {
  panel <- enem_load()
  cols <- c("ideologia_lr", "eval_pan", "eval_prd", "eval_pri")
  expect_true(all(cols %in% names(panel)))

  for (col in cols) {
    expect_true(all(panel[[col]] %in% c(0:10, NA)), info = col)
    expect_equal(length(unique(panel$anio[!is.na(panel[[col]])])), 10, info = col)
  }

  cb <- enem_codebook()
  expect_true(all(cb$disponible[cb$concepto %in% c("ideologia_lr", "eval_pan", "eval_prd", "eval_pri")]))
})

test_that("Fase 3: eval_pt/eval_pvem/ideologia_pan-prd-pri-pt-pvem estan en escala 0-10 en las 10 olas", {
  panel <- enem_load()
  cols <- c("eval_pt", "eval_pvem", "ideologia_pan", "ideologia_prd", "ideologia_pri", "ideologia_pt", "ideologia_pvem")
  expect_true(all(cols %in% names(panel)))

  for (col in cols) {
    expect_true(all(panel[[col]] %in% c(0:10, NA)), info = col)
    expect_equal(length(unique(panel$anio[!is.na(panel[[col]])])), 10, info = col)
  }

  cb <- enem_codebook()
  expect_true(all(cb$disponible[cb$concepto %in% c("eval_pt", "eval_pvem", "ideologia_pan", "ideologia_prd", "ideologia_pri", "ideologia_pt", "ideologia_pvem")]))
})

test_that("Fase 3: 2018 no concentra valores en los extremos de ideologia_<partido> (chequeo del offset +1)", {
  # Si el offset de 2018 no se hubiera aplicado, los codigos 1-11 crudos se
  # habrian leido tal cual como si fueran la escala 0-10 ya corregida, lo que
  # comprime artificialmente la distribucion hacia valores altos (o produce
  # NAs donde antes habia 10s legitimos). Chequeo simple: en 2018 debe haber
  # observaciones tanto en el extremo izquierdo (0) como en el derecho (10)
  # de cada ideologia_<partido>, igual que en el resto de las olas.
  panel <- enem_load(years = 2018)
  cols <- c("ideologia_pan", "ideologia_prd", "ideologia_pri", "ideologia_pt", "ideologia_pvem")
  for (col in cols) {
    expect_true(any(panel[[col]] == 0, na.rm = TRUE), info = paste(col, "- extremo 0"))
    expect_true(any(panel[[col]] == 10, na.rm = TRUE), info = paste(col, "- extremo 10"))
  }
})

test_that("Fase 3: pid_partido tiene las categorias esperadas y disponibilidad en las 10 olas", {
  panel <- enem_load()
  expect_true("pid_partido" %in% names(panel))

  categorias_esperadas <- c("PAN", "PRI", "PRD", "PVEM", "PT", "MC", "MORENA", "Otro", "Ninguno")
  expect_true(all(stats::na.omit(panel$pid_partido) %in% categorias_esperadas))
  expect_equal(length(unique(panel$anio[!is.na(panel$pid_partido)])), 10)

  cb <- enem_codebook()
  expect_true(all(cb$disponible[cb$concepto == "pid"]))
})

test_that("Fase 3: MORENA en pid_partido solo aparece desde que existe el partido (2015 en adelante)", {
  # MORENA se fundo en 2011 y participo por primera vez como partido en 2015
  # (el mapa "directo" de 2015 en build_codebook.R ya incluye a MORENA como
  # opcion de respuesta); en el diseno de pregunta de 1997-2012 ("con cual
  # partido simpatiza") tampoco pudo haber sido mencionado por no existir
  # todavia. Sanity check historico basico, mismo espiritu que los ya usados
  # para pdte_acuerdo/eval_pri en Fase 1-2.
  # (Corregido: la asercion original decia ">= 2018", inconsistente con este
  # mismo comentario y con el mapa de 2015 -- confirmado contra los datos
  # reales, que si traen MORENA desde 2015.)
  panel <- enem_load()
  anios_con_morena <- unique(panel$anio[!is.na(panel$pid_partido) & panel$pid_partido == "MORENA"])
  expect_true(all(anios_con_morena >= 2015))
})

test_that("Fase 3 (cierre): limpieza_electoral/satisfaccion_democracia/asistencia_religiosa en su rango propio, en las 10 olas", {
  panel <- enem_load()
  cols_rangos <- list(
    limpieza_electoral = 1:5,
    satisfaccion_democracia = 1:4,
    asistencia_religiosa = 1:6
  )
  for (col in names(cols_rangos)) {
    expect_true(col %in% names(panel), info = col)
    expect_true(all(panel[[col]] %in% c(cols_rangos[[col]], NA)), info = col)
    expect_equal(length(unique(panel$anio[!is.na(panel[[col]])])), 10, info = col)
  }

  cb <- enem_codebook()
  expect_true(all(cb$disponible[cb$concepto %in% names(cols_rangos)]))
})

test_that("Fase 3 (cierre): etnia/escolaridad/estado_civil/religion/econ_retro/voto_reportado/actividad_principal/conocimiento_camaras/conocimiento_diputado_termino son categoricas y estan en las 10 olas", {
  panel <- enem_load()
  categorias_esperadas <- list(
    etnia = c("Indigena", "Mestizo", "Blanco", "Afrodescendiente", "Otro"),
    escolaridad = c("Ninguna", "Primaria", "Secundaria", "Preparatoria", "Universidad_o_mas"),
    estado_civil = c("Soltero", "Casado_UnionLibre", "Divorciado_Separado", "Viudo"),
    religion = c("Catolica", "Otra", "Ninguna"),
    econ_retro = c("Mejoro", "Igual", "Empeoro"),
    voto_reportado = c("Si", "No"),
    actividad_principal = c("Ocupado", "Desocupado", "Fuera_fuerza_laboral"),
    conocimiento_camaras = c("Correcto", "Incorrecto"),
    conocimiento_diputado_termino = c("Correcto", "Incorrecto")
  )
  for (col in names(categorias_esperadas)) {
    expect_true(col %in% names(panel), info = col)
    expect_true(all(stats::na.omit(panel[[col]]) %in% categorias_esperadas[[col]]), info = col)
    expect_equal(length(unique(panel$anio[!is.na(panel[[col]])])), 10, info = col)
  }

  cb <- enem_codebook()
  expect_true(all(cb$disponible[cb$concepto %in% names(categorias_esperadas)]))
})

test_that("Fase 3 (cierre): conocimiento_gobernador solo esta disponible en 6 de las 10 olas, por diseno", {
  panel <- enem_load()
  expect_true("conocimiento_gobernador" %in% names(panel))
  anios_disponibles <- sort(unique(panel$anio[!is.na(panel$conocimiento_gobernador)]))
  expect_equal(anios_disponibles, c(2006, 2009, 2012, 2015, 2021, 2024))

  cb <- enem_codebook()
  fila_gob <- cb[cb$concepto == "conocimiento_gobernador", ]
  expect_equal(sort(fila_gob$anio[fila_gob$disponible]), c(2006, 2009, 2012, 2015, 2021, 2024))
  expect_true(all(!fila_gob$disponible[fila_gob$anio %in% c(1997, 2000, 2003, 2018)]))
})

test_that("Fase 3 (cierre): estado_civil funde Casado/Union libre de forma consistente entre las dos eras del cuestionario", {
  # 1997-2009: 'Casado' y 'Union libre' son codigos separados en el
  # original; 2012+: el cuestionario ya los funde en un solo codigo. Ambos
  # deben mapear a la misma categoria armonizada "Casado_UnionLibre", y esa
  # categoria debe existir en las 10 olas (no solo en una de las dos eras).
  panel <- enem_load()
  anios_con_casado <- unique(panel$anio[!is.na(panel$estado_civil) & panel$estado_civil == "Casado_UnionLibre"])
  expect_equal(length(anios_con_casado), 10)
})
