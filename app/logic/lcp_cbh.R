# app/logic/lcp_cbh.R
# ---------------------------------------------------------------------------
# Canopy base height (LCP band 7) correction: adjust the LANDFIRE CBH across
# the AOI toward the CBH measured by TLS (or submitted by the user) at the
# scanned plots, instead of only replacing the cells under each plot.
#
# Values are in LCP units (m x 10). Only LANDFIRE canopy cells (CBH > 0)
# inside the AOI change; cells without canopy stay 0.
#
# Rules:
#   1. shift        - several scans, all inside the AOI, whose TLS - LANDFIRE
#                     differences trend evenly (same sign, SD of the
#                     differences <= trend_cv * |mean difference|): every cell
#                     is shifted by the mean difference.
#   2. distribution - several scans otherwise (some outside the AOI, or
#                     uneven differences): the LANDFIRE CBH distribution is
#                     rescaled so its mean and +/- 1 SD land on the mean and
#                     +/- 1 SD of the scans' CBH.
#   3. single       - one scan: every cell is shifted so the LANDFIRE mean
#                     matches the scan's CBH.
# Every rule: a cell is never reduced below min_fraction (half) of its
# LANDFIRE value, and never raised above its stand height (band 6).
# ---------------------------------------------------------------------------
box::use(
  data.table[as.data.table],
  sf[st_transform],
  stats[sd],
  terra,
)

#' Correct the LANDFIRE canopy base height band toward the measured CBH.
#'
#' @param stack 8-band LCP stack (before the plot values are burned in)
#' @param obs_dt one row per plot: Longitude, Latitude, cbh_m (meters)
#' @param aoi optional sf polygon; NULL uses the whole landscape
#' @param trend_cv largest SD / |mean| of the differences that still counts
#'   as an even trend (rule 1)
#' @param min_fraction smallest fraction of its LANDFIRE value a cell keeps
#' @return list(stack, info); info records the rule used and its numbers
#' @export
correct_landfire_cbh <- function(stack, obs_dt, aoi = NULL, trend_cv = 0.5, min_fraction = 0.5) {
  obs <- as.data.table(obs_dt)[!is.na(cbh_m) & !is.na(Longitude) & !is.na(Latitude)]
  info <- list(rule = "none", n_scans = nrow(obs))
  if (nrow(obs) == 0) {
    return(list(stack = stack, info = info))
  }
  cbh <- stack[["canopy_base"]]
  lf <- terra$values(cbh, mat = FALSE)

  pts <- terra$vect(as.data.frame(obs), geom = c("Longitude", "Latitude"), crs = "EPSG:4326")
  pts <- terra$project(pts, terra$crs(stack))
  if (is.null(aoi)) {
    in_aoi <- rep(TRUE, length(lf))
    scans_in_aoi <- rep(TRUE, nrow(obs))
  } else {
    aoi_v <- terra$project(terra$vect(st_transform(aoi, 4326)), terra$crs(stack))
    in_aoi <- terra$values(terra$rasterize(aoi_v, cbh, background = 0), mat = FALSE) == 1
    scans_in_aoi <- as.vector(terra$is.related(pts, aoi_v, "intersects"))
  }
  canopy <- in_aoi & !is.na(lf) & lf > 0
  if (!any(canopy)) {
    return(list(stack = stack, info = info))
  }

  target <- obs$cbh_m * 10
  mean_lf <- mean(lf[canopy])
  sd_lf <- sd(lf[canopy])

  # TLS - LANDFIRE at the scans that sit on LANDFIRE canopy
  lf_at_scan <- terra$extract(cbh, pts, ID = FALSE)[, 1]
  diffs <- (target - lf_at_scan)[!is.na(lf_at_scan) & lf_at_scan > 0]
  even <- length(diffs) >= 2 && (all(diffs >= 0) || all(diffs <= 0)) &&
    sd(diffs) <= trend_cv * abs(mean(diffs))

  if (nrow(obs) == 1) {
    info$rule <- "single"
    info$shift_m <- (target - mean_lf) / 10
    adjusted <- lf + (target - mean_lf)
  } else if (all(scans_in_aoi) && even) {
    info$rule <- "shift"
    info$shift_m <- mean(diffs) / 10
    adjusted <- lf + mean(diffs)
  } else {
    info$rule <- "distribution"
    scale <- if (is.na(sd_lf) || sd_lf == 0) 0 else sd(target) / sd_lf
    adjusted <- mean(target) + (lf - mean_lf) * scale
    info$target_mean_m <- mean(target) / 10
    info$target_sd_m <- sd(target) / 10
  }
  info$landfire_mean_m <- mean_lf / 10
  info$landfire_sd_m <- sd_lf / 10
  info$scans_in_aoi <- sum(scans_in_aoi)
  info$even_trend <- even

  floor_v <- min_fraction * lf
  height <- terra$values(stack[["stand_height"]], mat = FALSE)
  capped <- !is.na(height) & height > 0 & adjusted > height
  floored <- adjusted < floor_v
  adjusted <- pmax(adjusted, floor_v)
  adjusted <- ifelse(capped, pmin(adjusted, height), adjusted)

  lf[canopy] <- round(adjusted[canopy])
  info$cells_adjusted <- sum(canopy)
  info$cells_floored <- sum(floored & canopy)
  info$cells_capped <- sum(capped & canopy)
  stack[["canopy_base"]] <- terra$setValues(cbh, lf)
  list(stack = stack, info = info)
}

#' One-line description of a correction, for notifications.
#' @export
describe_cbh_correction <- function(info) {
  if (is.null(info) || identical(info$rule, "none")) {
    return("Canopy base height: LANDFIRE values kept (no scan CBH or no canopy in the AOI).")
  }
  what <- switch(info$rule,
    single = sprintf("single scan, LANDFIRE mean shifted by %+.1f m", info$shift_m),
    shift = sprintf("%d scans trend evenly, all cells shifted by %+.1f m", info$n_scans, info$shift_m),
    distribution = sprintf(
      "%d scans, LANDFIRE mean %.1f +/- %.1f m rescaled to %.1f +/- %.1f m",
      info$n_scans, info$landfire_mean_m, info$landfire_sd_m, info$target_mean_m, info$target_sd_m
    )
  )
  sprintf(
    "Canopy base height: %s (%d cells; %d held at half their LANDFIRE value, %d capped at stand height).",
    what, info$cells_adjusted, info$cells_floored, info$cells_capped
  )
}
