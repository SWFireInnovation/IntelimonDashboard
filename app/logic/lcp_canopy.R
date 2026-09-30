# app/logic/lcp_canopy.R
# ---------------------------------------------------------------------------
# Canopy band corrections: adjust a LANDFIRE canopy band across the AOI
# toward the value measured by TLS (or submitted by the user) at the scanned
# plots, instead of only replacing the cells under each plot.
#
# Bands corrected (LCP units): canopy cover (band 5, percent) and canopy base
# height (band 7, m x 10). Only LANDFIRE canopy cells (band value > 0) inside
# the AOI change; cells without canopy stay 0.
#
# Rules:
#   1. shift        - several scans, all inside the AOI: every cell is shifted
#                     by the mean TLS - LANDFIRE difference at the scans. For
#                     CBH the differences must also trend evenly (same sign,
#                     SD of the differences <= trend_cv * |mean difference|).
#   2. distribution - several scans otherwise (some outside the AOI, or uneven
#                     CBH differences): the LANDFIRE distribution is rescaled
#                     so its mean and +/- 1 SD land on the mean and +/- 1 SD of
#                     the scans.
#   3. single       - one scan: every cell is shifted so the LANDFIRE mean
#                     matches the scan.
# Every rule keeps a cell at or above min_fraction of its LANDFIRE value and
# at or below the band's cap (see CANOPY_CORRECTIONS).
# ---------------------------------------------------------------------------
box::use(
  data.table[as.data.table],
  sf[st_transform],
  stats[sd],
  terra,
)

#' Per-band settings for the corrections.
#'
#' `scale` converts LCP units to the display unit; `min_fraction` is the
#' smallest share of its LANDFIRE value a cell keeps; `cap` returns each
#' cell's upper limit.
#' @export
CANOPY_CORRECTIONS <- list(
  canopy_cover = list(
    label = "Canopy cover", unit = "%", scale = 1,
    even_trend_required = FALSE, min_fraction = 0.15,
    cap = function(stack) rep(100, terra$ncell(stack)), cap_label = "100%"
  ),
  canopy_base = list(
    label = "Canopy base height", unit = "m", scale = 10,
    even_trend_required = TRUE, min_fraction = 0.5,
    cap = function(stack) {
      height <- terra$values(stack[["stand_height"]], mat = FALSE)
      ifelse(!is.na(height) & height > 0, height, Inf)
    },
    cap_label = "stand height"
  )
)

#' Correct a LANDFIRE canopy band toward the values measured at the scans.
#'
#' @param stack 8-band LCP stack (before the plot values are burned in)
#' @param obs_dt one row per plot: Longitude, Latitude, value (LCP units)
#' @param band "canopy_cover" or "canopy_base"
#' @param aoi optional sf polygon; NULL uses the whole landscape
#' @param trend_cv largest SD / |mean| of the differences that still counts
#'   as an even trend (rule 1, CBH)
#' @return list(stack, info); info records the rule used and its numbers in
#'   display units (% or m)
#' @export
correct_landfire_canopy <- function(stack, obs_dt, band = c("canopy_cover", "canopy_base"),
                                    aoi = NULL, trend_cv = 0.5) {
  band <- match.arg(band)
  spec <- CANOPY_CORRECTIONS[[band]]
  obs <- as.data.table(obs_dt)[!is.na(value) & !is.na(Longitude) & !is.na(Latitude)]
  info <- list(band = band, rule = "none", n_scans = nrow(obs))
  if (nrow(obs) == 0) {
    return(list(stack = stack, info = info))
  }
  layer <- stack[[band]]
  lf <- terra$values(layer, mat = FALSE)

  pts <- terra$vect(as.data.frame(obs), geom = c("Longitude", "Latitude"), crs = "EPSG:4326")
  pts <- terra$project(pts, terra$crs(stack))
  if (is.null(aoi)) {
    in_aoi <- rep(TRUE, length(lf))
    scans_in_aoi <- rep(TRUE, nrow(obs))
  } else {
    aoi_v <- terra$project(terra$vect(st_transform(aoi, 4326)), terra$crs(stack))
    in_aoi <- terra$values(terra$rasterize(aoi_v, layer, background = 0), mat = FALSE) == 1
    scans_in_aoi <- as.vector(terra$is.related(pts, aoi_v, "intersects"))
  }
  canopy <- in_aoi & !is.na(lf) & lf > 0
  if (!any(canopy)) {
    return(list(stack = stack, info = info))
  }

  target <- obs$value
  mean_lf <- mean(lf[canopy])
  sd_lf <- sd(lf[canopy])

  # TLS - LANDFIRE at the scans that sit on LANDFIRE canopy
  lf_at_scan <- terra$extract(layer, pts, ID = FALSE)[, 1]
  diffs <- (target - lf_at_scan)[!is.na(lf_at_scan) & lf_at_scan > 0]
  even <- length(diffs) >= 2 && (all(diffs >= 0) || all(diffs <= 0)) &&
    sd(diffs) <= trend_cv * abs(mean(diffs))
  shift_ok <- length(diffs) >= 1 && (even || !spec$even_trend_required)

  if (nrow(obs) == 1) {
    info$rule <- "single"
    info$shift <- (target - mean_lf) / spec$scale
    adjusted <- lf + (target - mean_lf)
  } else if (all(scans_in_aoi) && shift_ok) {
    info$rule <- "shift"
    info$shift <- mean(diffs) / spec$scale
    adjusted <- lf + mean(diffs)
  } else {
    info$rule <- "distribution"
    stretch <- if (is.na(sd_lf) || sd_lf == 0) 0 else sd(target) / sd_lf
    adjusted <- mean(target) + (lf - mean_lf) * stretch
    info$target_mean <- mean(target) / spec$scale
    info$target_sd <- sd(target) / spec$scale
  }
  info$landfire_mean <- mean_lf / spec$scale
  info$landfire_sd <- sd_lf / spec$scale
  info$scans_in_aoi <- sum(scans_in_aoi)
  info$even_trend <- even

  floor_v <- spec$min_fraction * lf
  cap <- spec$cap(stack)
  floored <- adjusted < floor_v
  adjusted <- pmax(adjusted, floor_v)
  capped <- adjusted > cap
  adjusted <- pmin(adjusted, cap)

  lf[canopy] <- round(adjusted[canopy])
  info$cells_adjusted <- sum(canopy)
  info$cells_floored <- sum(floored & canopy)
  info$cells_capped <- sum(capped & canopy)
  stack[[band]] <- terra$setValues(layer, lf)
  list(stack = stack, info = info)
}

#' One-line description of a correction, for notifications.
#' @export
describe_canopy_correction <- function(info) {
  if (is.null(info)) {
    return("")
  }
  spec <- CANOPY_CORRECTIONS[[info$band]]
  if (identical(info$rule, "none")) {
    return(sprintf(
      "%s: LANDFIRE values kept (no scan values or no canopy in the AOI).", spec$label
    ))
  }
  u <- spec$unit
  what <- switch(info$rule,
    single = sprintf("single scan, LANDFIRE mean shifted by %+.1f %s", info$shift, u),
    shift = sprintf("%d scans, all cells shifted by %+.1f %s", info$n_scans, info$shift, u),
    distribution = sprintf(
      "%d scans, LANDFIRE mean %.1f +/- %.1f %s rescaled to %.1f +/- %.1f %s",
      info$n_scans, info$landfire_mean, info$landfire_sd, u, info$target_mean, info$target_sd, u
    )
  )
  sprintf(
    "%s: %s (%d cells; %d held at %d%% of their LANDFIRE value, %d capped at %s).",
    spec$label, what, info$cells_adjusted, info$cells_floored,
    round(spec$min_fraction * 100), info$cells_capped, spec$cap_label
  )
}
