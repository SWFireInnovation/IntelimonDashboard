# app/logic/lcp_surface.R
# ---------------------------------------------------------------------------
# Surface fuel normalization for the LCP: shift the LANDFIRE fuel models in
# the AOI toward the surface fuel loadings submitted from the Fuels exports
# tab, the way app/logic/lcp_canopy.R shifts the canopy bands.
#
# An LCP's fuel band holds only fuel model numbers, so each standard Scott &
# Burgan model in the AOI gets a custom twin (numbers 14-89) whose loads and
# depth are the standard model's scaled class by class, written to a FlamMap
# custom fuel model file (.fmd) that ships with the LCP. The twin keeps the
# standard model's SAV ratios, moisture of extinction, heat content and
# dynamic/static type.
#
# Ratios, per class (1-hr, 10-hr, 100-hr, live herb, live woody) and depth:
#   - submitted / standard loading, summed over the scans of the chosen point
#     in time, for each base fuel model the scans sit on
#   - pooled over every scan for base models no scan sits on (and for every
#     model when the scans were classified with Anderson 13, whose codes
#     can't match the LCP's Scott & Burgan cells)
#   - held between 20% and 200% of the standard model (SURFACE_RATIO_LIMITS)
#   - 1 (standard kept) where the standard models carry none of that class
# Only burnable cells inside the AOI change; the whole landscape without one.
# ---------------------------------------------------------------------------
box::use(
  data.table[data.table, rbindlist],
  stats[setNames],
  terra,
)

box::use(
  app/logic/fuel_models[SCOTT_BURGAN_40, fuel_model_bed, fuel_model_lookup],
  app/logic/lcp_canopy[aoi_cells],
)

#' Smallest and largest share of a standard fuel model's loading or depth a
#' custom model may have.
#' @export
SURFACE_RATIO_LIMITS <- c(min = 0.2, max = 2)

#' Fuel model numbers FlamMap leaves free for custom models.
#' @export
CUSTOM_FUEL_CODES <- 14:89

HEAT_CONTENT <- 8000 # BTU/lb, dead and live, as in the standard models
LOAD_KEYS <- c("d1", "d10", "d100", "herb", "woody")
RATIO_KEYS <- c(LOAD_KEYS, "depth")
RATIO_LABELS <- c(
  d1 = "1-hr", d10 = "10-hr", d100 = "100-hr", herb = "live herb", woody = "live woody",
  depth = "depth"
)

clamp_ratio <- function(r) {
  pmin(pmax(r, SURFACE_RATIO_LIMITS[["min"]]), SURFACE_RATIO_LIMITS[["max"]])
}

# submitted / standard per class, summed over the scans that have both
group_ratio <- function(measured, standard) {
  vapply(RATIO_KEYS, function(k) {
    ok <- !is.na(measured[[k]]) & !is.na(standard[[k]])
    std <- sum(standard[[k]][ok])
    if (!isTRUE(std > 0)) NA_real_ else clamp_ratio(sum(measured[[k]][ok]) / std)
  }, numeric(1))
}

#' Per-class ratios of submitted to standard loadings.
#'
#' @param scans per-scan loadings (app/logic/fuel_bed.R scan_fuel_loads())
#'   for the chosen point in time
#' @param system classification of the scans' fbfm codes, "FBFM40" or "FBFM13"
#' @return list: by_model (data.table: fbfm, n, one ratio per RATIO_KEYS),
#'   pooled (named ratios), n (scans used) and system; NULL when no scan sits
#'   on a burnable fuel model
#' @export
surface_fuel_ratios <- function(scans, system = "FBFM40") {
  if (is.null(scans) || nrow(scans) == 0) {
    return(NULL)
  }
  standard <- lapply(scans$fbfm, function(code) {
    bed <- fuel_model_bed(fuel_model_lookup(code, system))
    if (is.null(bed) || isTRUE(bed$non_burnable)) NULL else c(bed$load_tonsac, depth = bed$depth_ft)
  })
  keep <- !vapply(standard, is.null, logical(1))
  if (!any(keep)) {
    return(NULL)
  }

  measured <- as.data.frame(scans)[keep, c(LOAD_KEYS, "depth_ft")]
  names(measured) <- RATIO_KEYS
  standard <- as.data.frame(do.call(rbind, standard[keep]))
  codes <- scans$fbfm[keep]
  by_model <- lapply(unique(codes), function(code) {
    i <- codes == code
    c(list(fbfm = code, n = sum(i)), as.list(group_ratio(measured[i, ], standard[i, ])))
  })
  list(
    by_model = rbindlist(by_model),
    pooled = group_ratio(measured, standard),
    n = sum(keep),
    system = system
  )
}

#' Custom twins of the standard Scott & Burgan models found in the AOI.
#'
#' @param base_numbers LANDFIRE FBFM40 numbers to twin (burnable models)
#' @param ratios surface_fuel_ratios() result
#' @return data.table, one row per base model: base_number, base_code,
#'   custom_number, ratio_source ("plots" or "pooled"), the custom loads
#'   (tons/acre), depth_ft, mx_dead_pct, SAV ratios, dynamic, and the ratios
#'   applied (r_*)
#' @export
custom_fuel_models <- function(base_numbers, ratios) {
  base <- sort(unique(base_numbers))
  if (length(base) > length(CUSTOM_FUEL_CODES)) {
    stop("Only ", length(CUSTOM_FUEL_CODES), " custom fuel models fit; the AOI has ", length(base), ".")
  }
  by_model <- as.data.frame(ratios$by_model)

  rbindlist(lapply(seq_along(base), function(i) {
    fm <- fuel_model_lookup(base[i], "FBFM40")
    bed <- fuel_model_bed(fm)
    hit <- if (identical(ratios$system, "FBFM40")) match(fm$code, by_model$fbfm) else NA
    r <- if (is.na(hit)) ratios$pooled else unlist(by_model[hit, RATIO_KEYS])
    r[is.na(r)] <- 1
    loads <- bed$load_tonsac * r[LOAD_KEYS]
    ratio_cols <- setNames(as.list(r[RATIO_KEYS]), paste0("r_", RATIO_KEYS))
    do.call(data.table, c(list(
      base_number = fm$number, base_code = fm$code, custom_number = CUSTOM_FUEL_CODES[i],
      ratio_source = if (is.na(hit)) "pooled" else "plots",
      d1 = loads[["d1"]], d10 = loads[["d10"]], d100 = loads[["d100"]],
      herb = loads[["herb"]], woody = loads[["woody"]],
      depth_ft = bed$depth_ft * r[["depth"]], mx_dead_pct = bed$mx_dead_pct,
      sav_d1 = bed$sav[["d1"]], sav_herb = bed$sav[["herb"]], sav_woody = bed$sav[["woody"]],
      dynamic = isTRUE(fm$dynamic)
    ), ratio_cols))
  }))
}

#' Write custom fuel models as a FlamMap/FARSITE custom fuel model file.
#'
#' English units, one model per line: number, 1-hr, 10-hr, 100-hr, live
#' herb and live woody loads (tons/acre), DYNAMIC/STATIC, 1-hr, live herb
#' and live woody SAV (ft^2/ft^3), fuel bed depth (ft), dead moisture of
#' extinction (%), dead and live heat content (BTU/lb), name.
#' @param models custom_fuel_models() result
#' @param path output .fmd
#' @return path
#' @export
write_fmd <- function(models, path) {
  lines <- sprintf(
    "%d %.4f %.4f %.4f %.4f %.4f %s %d %d %d %.4f %d %d %d %s",
    as.integer(models$custom_number), models$d1, models$d10, models$d100,
    models$herb, models$woody, ifelse(models$dynamic, "DYNAMIC", "STATIC"),
    as.integer(round(models$sav_d1)), as.integer(round(models$sav_herb)),
    as.integer(round(models$sav_woody)), models$depth_ft,
    as.integer(round(models$mx_dead_pct)), HEAT_CONTENT, HEAT_CONTENT,
    paste0("IntELiMon_", models$base_code)
  )
  writeLines(c("ENGLISH", lines), path)
  path
}

#' Swap the burnable fuel models in the AOI for custom twins scaled to the
#' submitted surface fuel loadings.
#'
#' @param stack 8-band LCP stack
#' @param scans per-scan loadings for the chosen point in time
#' @param aoi optional sf polygon; NULL changes the whole landscape
#' @param system classification of the scans' fbfm codes
#' @param label the point in time, for the description
#' @return list(stack, models, info), or NULL when there is nothing to change
#' @export
normalize_surface_fuels <- function(stack, scans, aoi = NULL, system = "FBFM40",
                                    label = NULL) {
  ratios <- surface_fuel_ratios(scans, system)
  if (is.null(ratios)) {
    return(NULL)
  }
  fuel <- stack[["fuel"]]
  v <- terra$values(fuel, mat = FALSE)
  burnable <- SCOTT_BURGAN_40$number[SCOTT_BURGAN_40$group != "Non-burnable"]
  target <- aoi_cells(fuel, aoi) & !is.na(v) & v %in% burnable
  if (!any(target)) {
    return(NULL)
  }

  models <- custom_fuel_models(v[target], ratios)
  v[target] <- models$custom_number[match(v[target], models$base_number)]
  stack[["fuel"]] <- terra$setValues(fuel, v)
  list(
    stack = stack,
    models = models,
    info = list(
      models = models, n_cells = sum(target), n_scans = ratios$n, label = label,
      aoi = !is.null(aoi)
    )
  )
}

#' One-paragraph description of the surface normalization for the download
#' dialog.
#' @export
describe_surface_normalization <- function(info) {
  if (is.null(info)) {
    return(paste(
      "Surface fuels: LANDFIRE's standard fuel models kept (no modeled loadings",
      "submitted from the Mean fuel loading card)."
    ))
  }
  m <- info$models
  per_model <- vapply(seq_len(nrow(m)), function(i) {
    r <- unlist(as.data.frame(m)[i, paste0("r_", RATIO_KEYS)])
    names(r) <- RATIO_KEYS
    moved <- abs(r - 1) > 0.005
    sprintf(
      "%s → %d (%s%s)", m$base_code[i], m$custom_number[i], m$ratio_source[i],
      if (any(moved)) {
        paste0(": ", paste(sprintf("%s ×%.2f", RATIO_LABELS[RATIO_KEYS[moved]], r[moved]),
                           collapse = ", "))
      } else {
        ", unchanged"
      }
    )
  }, character(1))
  sprintf(
    paste(
      "Surface fuels: %d burnable cells %s use %d custom fuel models scaled class by class",
      "to the submitted loadings (%d scans%s; ratios held to %d-%d%% of the standard model).",
      "Load the .fmd with the .lcp in FlamMap. %s."
    ),
    info$n_cells, if (isTRUE(info$aoi)) "in the AOI" else "in the landscape", nrow(m),
    info$n_scans, if (is.null(info$label)) "" else paste(",", info$label),
    round(100 * SURFACE_RATIO_LIMITS[["min"]]), round(100 * SURFACE_RATIO_LIMITS[["max"]]),
    paste(per_model, collapse = "; ")
  )
}
