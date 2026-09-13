# Procesa UNA ola cruda de ENEM: arma su parte del panel armonizado, su
# parte del crosswalk (documentación), y registra incidencias (columnas
# que faltaron esa ola). Se llama desde data-raw/build_codebook.R, una vez
# por año, con el `spec` de mapa_columnas correspondiente.

procesar_ola <- function(anio, ruta, spec, isco_cols) {
  crudo <- haven::read_dta(ruta)
  n <- nrow(crudo)

  stopifnot(all(c("PONDERADOR", "PONDFIN") %in% names(crudo)))
  stopifnot(spec$sexo %in% names(crudo))
  stopifnot(spec$edad_grupo %in% names(crudo))

  incidencias <- data.frame(anio = integer(0), variable = character(0), problema = character(0))

  armonizado <- data.frame(
    anio = anio,
    peso_diseno = as.numeric(crudo[[ "PONDERADOR" ]]),
    peso_final = as.numeric(crudo[[ "PONDFIN" ]]),
    mujer = as.integer(crudo[[ spec$sexo ]]),
    edad_grupo = as.integer(crudo[[ spec$edad_grupo ]])
  )

  # --- municipio (pass-through, NO armonizado entre olas) ----------------
  if (!is.na(spec$municipio) && spec$municipio %in% names(crudo)) {
    armonizado$municipio_original <- as.character(crudo[[ spec$municipio ]])
  } else {
    armonizado$municipio_original <- NA_character_
    incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "municipio", problema = "No disponible en este anio"))
  }

  # --- fecha (pass-through) ----------------------------------------------
  if (!is.na(spec$fecha) && spec$fecha %in% names(crudo)) {
    armonizado$fecha_original <- as.character(crudo[[ spec$fecha ]])
  } else {
    armonizado$fecha_original <- NA_character_
    motivo <- if (anio == 2006) "Columna 'fecha' existe pero esta 100% vacia en el .dta original" else "No se encontro variable de fecha en este anio"
    incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "fecha", problema = motivo))
  }

  # --- folio (pass-through + flag de unicidad) ----------------------------
  if (!is.na(spec$folio) && spec$folio %in% names(crudo)) {
    folio_vals <- crudo[[ spec$folio ]]
    armonizado$folio_original <- folio_vals
    armonizado$folio_es_id_unico <- length(unique(stats::na.omit(folio_vals))) == n
  } else {
    armonizado$folio_original <- NA
    armonizado$folio_es_id_unico <- FALSE
    incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "folio", problema = "No disponible en este anio"))
  }

  # --- aprobacion presidencial (pdte_acuerdo / pdte_aprueba) --------------
  # OJO: el original viene en orden 1=Muy de acuerdo...4=Muy en desacuerdo.
  # Se invierte aqui (5 - val) para que la columna armonizada quede en la
  # convencion "mayor valor = mas del concepto" (mayor valor = mas aprobacion),
  # consistente con el resto del panel. Confirmado contra
  # ENEM_candidatos_armonizacion_1997_2024.xlsx.
  if (!is.na(spec$aprobacion) && spec$aprobacion %in% names(crudo)) {
    val <- as.integer(crudo[[ spec$aprobacion ]])
    val[val %in% spec$aprobacion_na] <- NA_integer_
    raro <- !is.na(val) & !(val %in% 1:4)
    if (any(raro)) {
      incidencias <- rbind(incidencias, data.frame(
        anio = anio, variable = "aprobacion",
        problema = sprintf("%d valores fuera de 1:4 y de los codigos de no-respuesta esperados (%s)",
                            sum(raro), paste(sort(unique(val[raro])), collapse = ", "))
      ))
      val[raro] <- NA_integer_
    }
    val_armonizado <- ifelse(is.na(val), NA_integer_, as.integer(5L - val))
    armonizado$pdte_acuerdo <- val_armonizado
    armonizado$pdte_aprueba <- ifelse(is.na(val_armonizado), NA_integer_, ifelse(val_armonizado %in% c(3, 4), 1L, 0L))
  } else {
    armonizado$pdte_acuerdo <- NA_integer_
    armonizado$pdte_aprueba <- NA_integer_
    incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "aprobacion", problema = "No disponible en este anio"))
  }

  # --- id_ola / id_panel (llave unica DENTRO de cada ola) -----------------
  if ("id" %in% names(crudo)) {
    id_vals <- crudo[["id"]]
    if (length(unique(stats::na.omit(id_vals))) != n) {
      incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "id", problema = "La columna 'id' no resulto unica en esta ola (se esperaba unicidad)"))
    }
    armonizado$id_ola <- as.character(id_vals)
  } else {
    armonizado$id_ola <- NA_character_
    incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "id", problema = "No se encontro columna 'id' en este anio"))
  }
  armonizado$id_panel <- paste(armonizado$anio, armonizado$id_ola, sep = "_")

  # --- ocupacion ISCO-08 (ya armonizada por nombre) -----------------------
  for (col in isco_cols) {
    if (col %in% names(crudo)) {
      armonizado[[col]] <- crudo[[col]]
    } else {
      armonizado[[col]] <- NA
      incidencias <- rbind(incidencias, data.frame(anio = anio, variable = col, problema = "No disponible en este anio"))
    }
  }

  # --- crosswalk (documentacion) ------------------------------------------
  fila <- function(concepto, var_original, var_armonizada, disponible, notas) {
    data.frame(anio = anio, concepto = concepto, var_original = var_original,
               var_armonizada = var_armonizada, disponible = disponible, notas = notas,
               stringsAsFactors = FALSE)
  }
  crosswalk <- rbind(
    fila("sexo", spec$sexo, "mujer", TRUE,
         "0=hombre/1=mujer. Confirmado contra las etiquetas de valor de female<anio> leidas directamente del Stata (ver ENEM_candidatos_armonizacion_1997_2024.xlsx)."),
    fila("edad_grupo", spec$edad_grupo, "edad_grupo", TRUE,
         "Codigos 1-4 consistentes entre anios; sin value labels en el .dta para confirmar los cortes exactos de cada grupo"),
    fila("municipio", if (is.na(spec$municipio)) NA_character_ else spec$municipio, "municipio_original",
         !is.na(spec$municipio),
         if (is.na(spec$municipio)) "No se encontro variable de geografia en este anio" else "Codigo/nombre TAL CUAL viene en el .dta -- NO esta armonizado a un catalogo comun (p.ej. INEGI) entre anios"),
    fila("fecha", if (is.na(spec$fecha)) NA_character_ else spec$fecha, "fecha_original",
         !is.na(spec$fecha),
         if (anio == 2006) "Columna 'fecha' existe pero esta 100% vacia en el .dta original" else if (is.na(spec$fecha)) "No se encontro variable de fecha en este anio" else ""),
    fila("folio", if (is.na(spec$folio)) NA_character_ else spec$folio, "folio_original",
         !is.na(spec$folio),
         if (is.na(spec$folio)) "No existe variable de folio en este anio" else if (armonizado$folio_es_id_unico[1]) "SI es identificador unico por respondiente" else "NO es identificador unico por respondiente (se repite entre filas) -- parece ser folio de lote/entrevistador, no de persona"),
    fila("aprobacion_pdte", if (is.na(spec$aprobacion)) NA_character_ else spec$aprobacion, "pdte_acuerdo",
         !is.na(spec$aprobacion),
         sprintf("Escala de 4 puntos, orientada para que mayor valor = mayor aprobacion (1=Muy en desacuerdo, 2=Algo en desacuerdo, 3=Algo de acuerdo, 4=Muy de acuerdo). El original viene en orden inverso (1=Muy de acuerdo); se invirtio para dejar una convencion consistente de 'mayor valor = mas del concepto' en todo el panel, confirmado contra ENEM_candidatos_armonizacion_1997_2024.xlsx. Codigos de no respuesta (%s) recodificados a NA.",
                 paste(spec$aprobacion_na, collapse = "/"))),
    fila("aprobacion_pdte_binaria", if (is.na(spec$aprobacion)) NA_character_ else spec$aprobacion, "pdte_aprueba",
         !is.na(spec$aprobacion),
         "Colapso de pdte_acuerdo: 1=aprueba (pdte_acuerdo 3-4), 0=desaprueba (pdte_acuerdo 1-2), NA si no hubo respuesta."),
    fila("id_ola", "id", "id_ola / id_panel", TRUE,
         "id_ola: identificador unico DENTRO de cada ola (confirmado contra las 10 bases). NO es identificador longitudinal entre olas -- ENEM es transversal salvo el panel 2018. id_panel = anio + '_' + id_ola, llave compuesta unica en todo enem_panel, util para unir con otras fuentes por ola.")
  )

  list(armonizado = armonizado, crosswalk = crosswalk, incidencias = incidencias)
}
