# Procesa UNA ola cruda de ENEM: arma su parte del panel armonizado, su
# parte del crosswalk (documentación), y registra incidencias (columnas
# que faltaron esa ola). Se llama desde data-raw/build_codebook.R, una vez
# por año, con el `spec` de mapa_columnas correspondiente.

procesar_ola <- function(anio, ruta, spec, isco_cols, escalas_0_10 = list(),
                          escalas_0_10_offsets = list(), pid_specs = list(),
                          escalas_0_10_rango = list(), escalas_0_10_invertir = list(),
                          recodes_categoricas = list()) {
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

  # --- Fase 2/3: conceptos "escala acotada conservada tal cual (o invertida)"
  # (ideologia, evaluacion de partidos, y desde Fase 3 tambien limpieza
  # electoral, satisfaccion con la democracia, asistencia religiosa) --
  # valido si rango[1] <= val <= rango[2] (tras restar el offset del anio,
  # ver abajo), cualquier otro codigo (NS, NC, "no lo conozco lo
  # suficiente", "nunca ha oido del partido", "no aplica por version", etc,
  # segun el anio) se recodifica a NA.
  #
  # `escalas_0_10_rango`: por concepto, un vector c(min, max) con el rango
  # valido de la escala armonizada. Si el concepto no aparece aqui, se usa
  # 0:10 (comportamiento historico, sin cambios para ideologia_lr/eval_*/
  # ideologia_<partido>).
  #
  # `escalas_0_10_invertir`: por concepto, un vector nombrado por anio
  # (TRUE/FALSE) que indica si ese anio debe invertirse (rango[1]+rango[2]-val)
  # para dejar la escala en la convencion "mayor valor = mas del concepto".
  # Si el concepto/anio no aparece aqui, no se invierte (comportamiento
  # historico). Necesario porque asistencia_religiosa solo requiere invertir
  # 1997/2000 (el resto de anios ya viene en la orientacion correcta) y
  # satisfaccion_democracia requiere invertir los 10 anios.
  #
  # `escalas_0_10_offsets`: por concepto, un vector nombrado por anio con el
  # desplazamiento a restar ANTES de validar el rango. Necesario porque 2018
  # almacena la ubicacion izquierda-derecha de cada partido (ideologia_pan/
  # prd/pri/pt/pvem) con codigos 1-11 en vez de 0-10 (codigo 1 = respuesta
  # "0", ..., codigo 11 = respuesta "10"; 12/13/14 son especiales) --
  # confirmado contra ENEM_candidatos_armonizacion_1997_2024.xlsx hoja
  # Codigos. Los conceptos/anios sin offset explicito usan 0 (sin cambio).
  crosswalk_escalas <- list()
  anio_chr <- as.character(anio)
  for (colname in names(escalas_0_10)) {
    var_anio <- escalas_0_10[[colname]][[anio_chr]]
    offset <- 0L
    off_spec <- escalas_0_10_offsets[[colname]]
    if (!is.null(off_spec)) {
      off_val <- unname(off_spec[anio_chr])
      if (!is.na(off_val)) offset <- as.integer(off_val)
    }
    rango <- escalas_0_10_rango[[colname]]
    if (is.null(rango)) rango <- c(0L, 10L)
    invertir <- FALSE
    inv_spec <- escalas_0_10_invertir[[colname]]
    if (!is.null(inv_spec)) {
      inv_val <- unname(inv_spec[anio_chr])
      if (!is.na(inv_val)) invertir <- isTRUE(as.logical(inv_val))
    }
    if (!is.na(var_anio) && var_anio %in% names(crudo)) {
      val <- as.integer(crudo[[ var_anio ]]) - offset
      val[!(val %in% rango[1]:rango[2])] <- NA_integer_
      if (invertir) {
        val <- ifelse(is.na(val), NA_integer_, as.integer(rango[1] + rango[2] - val))
      }
      armonizado[[colname]] <- val
      nota_offset <- if (offset != 0) {
        sprintf(" Codigo almacenado en este anio desplazado +%d respecto a la escala sustantiva (confirmado contra hoja Codigos); se resta antes de validar.", offset)
      } else {
        ""
      }
      nota_invertir <- if (invertir) {
        " Escala invertida en este anio (valor_armonizado = rango_min + rango_max - valor_original) para dejar la convencion 'mayor valor = mas del concepto'."
      } else {
        ""
      }
      nota_rango <- if (!identical(rango, c(0L, 10L))) {
        sprintf(" Rango valido %d-%d (fuera de eso -> NA).", rango[1], rango[2])
      } else {
        ""
      }
      crosswalk_escalas[[colname]] <- data.frame(
        anio = anio, concepto = colname, var_original = var_anio, var_armonizada = colname,
        disponible = TRUE,
        notas = paste0("Escala conservada tal cual (salvo inversion indicada); cualquier codigo fuera del rango valido recodificado a NA (NS/NC/'no lo conozco lo suficiente'/'nunca ha oido del partido'/etc, varia por anio -- ver ENEM_candidatos_armonizacion_1997_2024.xlsx hoja Codigos).", nota_rango, nota_offset, nota_invertir),
        stringsAsFactors = FALSE
      )
    } else {
      armonizado[[colname]] <- NA_integer_
      incidencias <- rbind(incidencias, data.frame(anio = anio, variable = colname, problema = "No disponible en este anio"))
      crosswalk_escalas[[colname]] <- data.frame(
        anio = anio, concepto = colname, var_original = NA_character_, var_armonizada = colname,
        disponible = FALSE, notas = "No disponible en este anio", stringsAsFactors = FALSE
      )
    }
  }

  # --- Fase 3: pid_partido (identificacion partidista) --------------------
  # Ver notas extensas en data-raw/build_codebook.R (definicion de
  # pid_specs) sobre por que esta variable se reconstruye distinto en
  # 1997-2012 ("filtro" + partido de primera mencion) vs 2015-2024
  # ("directo", bateria unica que ya incluye Otro/Ninguno/NS/NC).
  spec_pid <- pid_specs[[anio_chr]]
  pid_disponible <- FALSE
  var_original_pid <- NA_character_
  nota_pid <- "No disponible en este anio"

  if (is.null(spec_pid)) {
    armonizado$pid_partido <- NA_character_
    incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "pid_partido", problema = "No disponible en este anio"))
  } else if (identical(spec_pid$tipo, "filtro")) {
    var_original_pid <- paste0(spec_pid$filtro, " (filtro) + ", spec_pid$folup, " (partido, 1a mencion)")
    if (spec_pid$filtro %in% names(crudo) && spec_pid$folup %in% names(crudo)) {
      filtro_val <- as.integer(crudo[[ spec_pid$filtro ]])
      folup_val <- as.integer(crudo[[ spec_pid$folup ]])
      pid_val <- rep(NA_character_, n)
      pid_val[!is.na(filtro_val) & filtro_val == spec_pid$no] <- "Ninguno"
      es_si <- !is.na(filtro_val) & filtro_val == spec_pid$si
      folup_chr <- as.character(folup_val)
      sin_mapa <- es_si & !is.na(folup_val) & !(folup_chr %in% names(spec_pid$mapa))
      if (any(sin_mapa)) {
        incidencias <- rbind(incidencias, data.frame(
          anio = anio, variable = "pid_partido",
          problema = sprintf("%d valores de '%s' (con filtro='Si') fuera del mapa de codigos esperado (%s)",
                              sum(sin_mapa), spec_pid$folup,
                              paste(sort(unique(folup_val[sin_mapa])), collapse = ", "))
        ))
      }
      pid_val[es_si] <- unname(spec_pid$mapa[folup_chr[es_si]])
      armonizado$pid_partido <- pid_val
      pid_disponible <- TRUE
      nota_pid <- "Reconstruido desde el filtro binario ('simpatiza con algun partido: si/no/ns/nc') + el partido de primera mencion (solo si el filtro fue 'si'). 'Ninguno' = contesto 'No' al filtro (confirmado por crosstab contra el filtro, no por el codigo de la variable de partido -- este varia por anio: sistema-perdido en la mayoria, pero codigo centinela propio en 2003/2009). NA = NS/NC en el filtro, o 'Ns'/'Nc'/'no lo conozco lo suficiente' en la pregunta de partido. 'Otro' agrupa partidos minoritarios NO comparables entre anios (distinta composicion cada ola). No se uso la variable pid<anio>b del cuestionario (version ya colapsada; el propio inventario advierte que el significado de sus codigos cambia entre anios, ver ENEM_candidatos_armonizacion_1997_2024.xlsx)."
    } else {
      armonizado$pid_partido <- NA_character_
      incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "pid_partido", problema = "No disponible en este anio"))
    }
  } else { # spec_pid$tipo == "directo"
    var_original_pid <- spec_pid$var
    if (spec_pid$var %in% names(crudo)) {
      val <- as.integer(crudo[[ spec_pid$var ]])
      val_chr <- as.character(val)
      sin_mapa <- !is.na(val) & !(val_chr %in% names(spec_pid$mapa))
      if (any(sin_mapa)) {
        incidencias <- rbind(incidencias, data.frame(
          anio = anio, variable = "pid_partido",
          problema = sprintf("%d valores de '%s' fuera del mapa de codigos esperado (%s)",
                              sum(sin_mapa), spec_pid$var,
                              paste(sort(unique(val[sin_mapa])), collapse = ", "))
        ))
      }
      armonizado$pid_partido <- unname(spec_pid$mapa[val_chr])
      pid_disponible <- TRUE
      nota_pid <- "Bateria directa ('se considera panista/priista/perredista/.../de otro partido, mucho o algo'); Otro/Ninguno/NS/NC ya vienen como categorias explicitas de la propia variable, no hay filtro separado que leer. 'Otro' agrupa partidos fuera de PAN/PRI/PRD/MORENA sin desagregar (el cuestionario los detalla en una pregunta de seguimiento -- P5_1 en 2018, 3.1 en 2021 -- que no se usa aqui). No se uso la variable pid<anio>b del cuestionario (ver ENEM_candidatos_armonizacion_1997_2024.xlsx)."
    } else {
      armonizado$pid_partido <- NA_character_
      incidencias <- rbind(incidencias, data.frame(anio = anio, variable = "pid_partido", problema = "No disponible en este anio"))
    }
  }

  # --- Fase 3: recodificaciones categoricas por mapa fijo por anio --------
  # Mecanismo generico (generaliza el patron "directo" de pid_partido) para
  # conceptos donde cada anio tiene UNA variable origen y un mapa de codigo
  # crudo -> categoria/valor armonizado ya fijo (sin necesidad de logica de
  # filtro como pid_partido en 1997-2012). Usado para etnia, escolaridad,
  # estado_civil, religion, tipo_seccion, econ_retro, voto_reportado,
  # actividad_principal, conocimiento_camaras, conocimiento_diputado_termino,
  # conocimiento_gobernador. Ver notas por concepto en
  # data-raw/build_codebook.R (objeto recodes_categoricas) y en R/data.R.
  crosswalk_categoricas <- list()
  for (colname in names(recodes_categoricas)) {
    spec_cat <- recodes_categoricas[[colname]][[anio_chr]]
    if (is.null(spec_cat)) {
      armonizado[[colname]] <- NA_character_
      incidencias <- rbind(incidencias, data.frame(anio = anio, variable = colname, problema = "No disponible en este anio"))
      crosswalk_categoricas[[colname]] <- data.frame(
        anio = anio, concepto = colname, var_original = NA_character_, var_armonizada = colname,
        disponible = FALSE, notas = "No disponible en este anio", stringsAsFactors = FALSE
      )
      next
    }
    if (spec_cat$var %in% names(crudo)) {
      val <- as.integer(crudo[[ spec_cat$var ]])
      val_chr <- as.character(val)
      sin_mapa <- !is.na(val) & !(val_chr %in% names(spec_cat$mapa))
      if (any(sin_mapa)) {
        incidencias <- rbind(incidencias, data.frame(
          anio = anio, variable = colname,
          problema = sprintf("%d valores de '%s' fuera del mapa de codigos esperado (%s)",
                              sum(sin_mapa), spec_cat$var,
                              paste(sort(unique(val[sin_mapa])), collapse = ", "))
        ))
      }
      armonizado[[colname]] <- unname(spec_cat$mapa[val_chr])
      nota_cat <- if (!is.null(spec_cat$notas)) spec_cat$notas else "Recodificado por mapa fijo de codigos para este anio (ver ENEM_candidatos_armonizacion_1997_2024.xlsx)."
      crosswalk_categoricas[[colname]] <- data.frame(
        anio = anio, concepto = colname, var_original = spec_cat$var, var_armonizada = colname,
        disponible = TRUE, notas = nota_cat, stringsAsFactors = FALSE
      )
    } else {
      armonizado[[colname]] <- NA_character_
      incidencias <- rbind(incidencias, data.frame(anio = anio, variable = colname, problema = "No disponible en este anio"))
      crosswalk_categoricas[[colname]] <- data.frame(
        anio = anio, concepto = colname, var_original = NA_character_, var_armonizada = colname,
        disponible = FALSE, notas = "No disponible en este anio", stringsAsFactors = FALSE
      )
    }
  }

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
         "id_ola: identificador unico DENTRO de cada ola (confirmado contra las 10 bases). NO es identificador longitudinal entre olas -- ENEM es transversal salvo el panel 2018. id_panel = anio + '_' + id_ola, llave compuesta unica en todo enem_panel, util para unir con otras fuentes por ola."),
    fila("pid", var_original_pid, "pid_partido", pid_disponible, nota_pid)
  )
  if (length(crosswalk_escalas) > 0) {
    crosswalk <- rbind(crosswalk, do.call(rbind, crosswalk_escalas))
  }
  if (length(crosswalk_categoricas) > 0) {
    crosswalk <- rbind(crosswalk, do.call(rbind, crosswalk_categoricas))
  }

  list(armonizado = armonizado, crosswalk = crosswalk, incidencias = incidencias)
}
