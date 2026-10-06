# app/logic/fuel_bed.R
# ---------------------------------------------------------------------------
# Surface fuel loadings for the Fuels exports tab, computed per scan and
# averaged for the "Mean fuel loading" card, with the source of every value.
# The per-scan table is what gets submitted, so rothRmel can track the
# loadings through time (and the LCP / IFTDSS / FastFuels exports can later
# edit their surface fuels from it, the way canopy values are corrected now).
#
# Dead 1/10/100-hour loads come either from the time-lag intercept counts
# (Brown) or from the fuel model scaled to the measured fuel bed depth; live
# herb and woody loads always come from the scaled fuel model. A missing
# measurement falls back to the fuel model, and a missing depth to the model's
# own depth.
# ---------------------------------------------------------------------------
box::use(
  data.table[as.data.table, copy, data.table, merge.data.table, rbindlist],
  stats[setNames],
)

box::use(
  app/logic/fuel[BROWN_CLASSES, SURFACE_FUEL_MODELS, TIMELAG_FUEL_MODELS, brown_class_load],
  app/logic/fuel_models[depth_scaled_loads, fuel_model_bed],
)

CM_PER_FT <- 30.48

# Columns identifying one scan
SCAN_KEY <- c("site", "plot", "date", "scanner_id")

LOAD_KEYS <- c("d1", "d10", "d100", "herb", "woody")

# Dead load classes: bed key -> BROWN_CLASSES / TIMELAG_FUEL_MODELS key
DEAD_CLASSES <- c(d1 = "onehr", d10 = "tenhr", d100 = "hunhr")

DEPTH_COL <- SURFACE_FUEL_MODELS$mfbd$col
COUNT_COLS <- vapply(DEAD_CLASSES, function(k) TIMELAG_FUEL_MODELS[[k]]$col, character(1))

# Models whose presence makes a scan set "Modeled/User defined"
#' @export
MODELED_COLS <- unname(c(DEPTH_COL, COUNT_COLS))

as_num <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (length(x) != 1 || is.na(x)) NA_real_ else x
}

#' Default fuel data source for a set of scans.
#'
#' @param cols columns that carry data (non-missing values), out of MODELED_COLS
#' @return "modeled" when the fuel bed depth or any 1-100 hour time-lag model
#'   is available, otherwise "landfire"
#' @export
default_fuel_source <- function(cols) {
  if (any(MODELED_COLS %in% cols)) "modeled" else "landfire"
}

#' One row per scan: the scan metrics with the wide model table joined on.
#' Metrics win where both tables carry a column.
#' @export
merge_scan_models <- function(metrics_dt, models_wide_dt) {
  m <- as.data.table(metrics_dt)
  if (nrow(m) == 0 || is.null(models_wide_dt) || nrow(models_wide_dt) == 0) {
    return(m)
  }
  w <- copy(as.data.table(models_wide_dt))
  key <- intersect(SCAN_KEY, intersect(names(m), names(w)))
  dup <- setdiff(intersect(names(m), names(w)), key)
  if (length(dup) > 0) w[, (dup) := NULL]
  merge.data.table(m, w, by = key, all.x = TRUE)
}

#' Scans for a point in time.
#'
#' @param dt table with site, plot and date columns
#' @param mode "recent" (latest scan per plot), "all" (every scan) or "date"
#'   (each plot's scan nearest `date`, the earlier one on a tie)
#' @param date target date for mode "date"; without one, "recent" is used
#' @export
select_scans <- function(dt, mode = "recent", date = NULL) {
  if (is.null(dt) || nrow(dt) == 0 || identical(mode, "all")) {
    return(dt)
  }
  d <- as.numeric(as.Date(dt$date))
  target <- if (identical(mode, "date") && length(date) == 1) as.numeric(as.Date(date)) else NA
  rank <- if (is.na(target)) -d else 2 * abs(d - target) + (d > target)
  plot_id <- paste(dt$site, dt$plot, sep = "\r")
  o <- order(plot_id, rank)
  dt[sort(o[!duplicated(plot_id[o])])]
}

#' Words for a point in time, e.g. "scans nearest 2023-08-25".
#' @export
point_in_time_label <- function(mode, date = NULL) {
  if (identical(mode, "all")) {
    "mean of all scans"
  } else if (identical(mode, "date") && length(date) == 1 && !is.na(as.Date(date))) {
    paste("scans nearest", format(as.Date(date)))
  } else {
    "most recent per plot"
  }
}

#' Surface fuel bed with the source of each value.
#'
#' @param fm one-row fuel model from fuel_model_lookup(), or NULL
#' @param depth_cm measured fuel bed depth (cm); NA when missing
#' @param counts time-lag intercept counts per 40 m, named d1/d10/d100; NA
#'   when missing
#' @param prefer "count" or "model" per dead class, named d1/d10/d100
#' @return list: load_tonsac (d1, d10, d100, herb, woody), sources (labels,
#'   same names), depth_ft, depth_source, mx_dead_pct (NULL without a fuel
#'   model), mx_source, and fallback (for each dead class that could not use
#'   the preferred source, the source used instead: "count", "model" or "none")
#' @export
assemble_fuel_bed <- function(fm, depth_cm, counts, prefer) {
  depth_cm <- as_num(depth_cm)
  model <- fuel_model_bed(fm)
  burnable <- !is.null(model) && !isTRUE(model$non_burnable) && isTRUE(fm$depth_ft > 0)

  if (!is.na(depth_cm) && depth_cm > 0) {
    depth_ft <- depth_cm / CM_PER_FT
    depth_source <- "Measured depth"
  } else if (burnable) {
    depth_ft <- fm$depth_ft
    depth_source <- "Fuel model depth"
  } else {
    depth_ft <- NA_real_
    depth_source <- "Missing"
  }

  scaled <- if (burnable && !is.na(depth_ft)) depth_scaled_loads(fm, depth_ft * CM_PER_FT)
  model_label <- "Fuel model × depth"

  loads <- setNames(rep(0, 5), LOAD_KEYS)
  sources <- setNames(rep("No data", 5), LOAD_KEYS)
  fallback <- character(0)

  for (k in names(DEAD_CLASSES)) {
    brown <- brown_class_load(as_num(counts[k]), BROWN_CLASSES[[DEAD_CLASSES[[k]]]])
    want <- if (identical(unname(prefer[k]), "model")) "model" else "count"
    used <- if (!is.na(brown) && (want == "count" || is.null(scaled))) {
      "count"
    } else if (!is.null(scaled)) {
      "model"
    } else {
      "none"
    }
    if (used == "count") {
      loads[[k]] <- brown
      sources[[k]] <- "Time lag count"
    } else if (used == "model") {
      loads[[k]] <- scaled[[k]]
      sources[[k]] <- model_label
    }
    if (used != want) fallback[[k]] <- used
  }

  for (k in c("herb", "woody")) {
    if (!is.null(scaled)) {
      loads[[k]] <- scaled[[k]]
      sources[[k]] <- model_label
    } else {
      sources[[k]] <- "No fuel model"
    }
  }

  list(
    load_tonsac = loads,
    sources = sources,
    depth_ft = depth_ft,
    depth_source = depth_source,
    mx_dead_pct = if (burnable) model$mx_dead_pct,
    mx_source = if (burnable) "Fuel model" else "rothRmel sidebar",
    fallback = fallback
  )
}

#' Surface fuel loadings for every scan.
#'
#' @param scans one row per scan, from merge_scan_models()
#' @param fm_for function(row) returning the scan's fuel model (or NULL)
#' @param prefer "count" or "model" per dead class, named d1/d10/d100
#' @param edits user-edited values that replace every scan's own: depth_cm,
#'   d1, d10, d100 (counts); NULL or absent keeps the scan's value
#' @param landfire TRUE for each scan's standard fuel model loads and depth,
#'   ignoring the measurements
#' @return data.table, one row per scan: the scan key, fbfm, loads d1..woody
#'   (tons/acre), depth_ft, mx_dead_pct, sav_d1/sav_herb/sav_woody (NA for the
#'   standard SAV set), src_* / depth_source / mx_source labels, and
#'   fallback_d1/d10/d100 (the source used when the preferred one was missing)
#' @export
scan_fuel_loads <- function(scans, fm_for, prefer, edits = list(), landfire = FALSE) {
  if (is.null(scans) || nrow(scans) == 0) {
    return(data.table())
  }
  key <- intersect(SCAN_KEY, names(scans))
  scan_value <- function(row, col) if (col %in% names(row)) row[[col]] else NA

  rows <- lapply(seq_len(nrow(scans)), function(i) {
    row <- as.list(scans[i])
    fm <- fm_for(row)
    if (landfire) {
      bed <- assemble_fuel_bed(fm, NA, c(), c(d1 = "model", d10 = "model", d100 = "model"))
      if (!is.null(fm)) bed$sources[] <- "Standard load"
      sav <- fuel_model_bed(fm)$sav
    } else {
      depth <- if (is.null(edits$depth_cm)) scan_value(row, DEPTH_COL) else edits$depth_cm
      counts <- vapply(names(DEAD_CLASSES), function(k) {
        as_num(if (is.null(edits[[k]])) scan_value(row, COUNT_COLS[[k]]) else edits[[k]])
      }, numeric(1))
      bed <- assemble_fuel_bed(fm, depth, counts, prefer)
      sav <- NULL
    }
    c(
      row[key],
      list(fbfm = if (is.null(fm)) NA_character_ else fm$code),
      as.list(bed$load_tonsac),
      list(
        depth_ft = bed$depth_ft,
        mx_dead_pct = if (is.null(bed$mx_dead_pct)) NA_real_ else bed$mx_dead_pct,
        sav_d1 = if (is.null(sav)) NA_real_ else sav[["d1"]],
        sav_herb = if (is.null(sav)) NA_real_ else sav[["herb"]],
        sav_woody = if (is.null(sav)) NA_real_ else sav[["woody"]]
      ),
      setNames(as.list(bed$sources), paste0("src_", LOAD_KEYS)),
      list(depth_source = bed$depth_source, mx_source = bed$mx_source),
      setNames(
        as.list(unname(bed$fallback[names(DEAD_CLASSES)])),
        paste0("fallback_", names(DEAD_CLASSES))
      )
    )
  })
  rbindlist(rows, use.names = TRUE, fill = TRUE)
}

#' Mean fuel loading across scans, with a summary of where the values came from.
#'
#' @param loads scan_fuel_loads() table
#' @return list: n (scans), load_tonsac, sources, depth_ft, depth_source,
#'   mx_dead_pct, mx_source, and fallback (per dead class, the number of scans
#'   that used each fallback source)
#' @export
mean_fuel_loading <- function(loads) {
  n <- if (is.null(loads)) 0L else nrow(loads)
  avg <- function(x) {
    x <- x[!is.na(x)]
    if (length(x) == 0) NA_real_ else mean(x)
  }
  # one label when every scan agrees, otherwise each label with its count
  summarise <- function(x) {
    if (n == 0) {
      return("No data")
    }
    tt <- table(x)
    if (length(tt) == 1) {
      names(tt)
    } else {
      paste(sprintf("%s (%d)", names(tt), as.integer(tt)), collapse = ", ")
    }
  }
  col <- function(name) if (n == 0) NA else loads[[name]]

  list(
    n = n,
    load_tonsac = vapply(LOAD_KEYS, function(k) avg(col(k)), numeric(1)),
    sources = vapply(LOAD_KEYS, function(k) summarise(col(paste0("src_", k))), character(1)),
    depth_ft = avg(col("depth_ft")),
    depth_source = summarise(col("depth_source")),
    mx_dead_pct = avg(col("mx_dead_pct")),
    mx_source = summarise(col("mx_source")),
    fallback = lapply(setNames(nm = names(DEAD_CLASSES)), function(k) {
      x <- col(paste0("fallback_", k))
      table(x[!is.na(x)])
    })
  )
}

#' The submitted fuel bed for one scan: that scan's row of `bed$scans` when it
#' has one, otherwise the submitted means.
#'
#' @param bed submitted fuel bed (session$userData$fuel_tool_values()), or NULL
#' @param row the scan, as a named list holding its key columns
#' @return list with load_tonsac, depth_ft, mx_dead_pct (NULL -> use the
#'   caller's) and sav (NULL -> standard set); NULL when nothing was submitted
#' @export
bed_for_scan <- function(bed, row) {
  scans <- bed$scans
  if (is.null(bed) || is.null(scans) || nrow(scans) == 0) {
    return(bed)
  }
  key <- intersect(SCAN_KEY, intersect(names(scans), names(row)))
  hit <- rep(TRUE, nrow(scans))
  for (k in key) hit <- hit & (scans[[k]] == row[[k]]) %in% TRUE
  i <- which(hit)[1]
  if (length(key) == 0 || is.na(i)) {
    return(bed)
  }

  s <- scans[i]
  sav <- c(d1 = s$sav_d1, d10 = 109, d100 = 30, herb = s$sav_herb, woody = s$sav_woody)
  list(
    load_tonsac = vapply(LOAD_KEYS, function(k) s[[k]], numeric(1)),
    depth_ft = s$depth_ft,
    mx_dead_pct = if (is.na(s$mx_dead_pct)) NULL else s$mx_dead_pct,
    sav = if (anyNA(sav)) NULL else sav
  )
}
