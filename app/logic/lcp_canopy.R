# app/logic/lcp_canopy.R
# ---------------------------------------------------------------------------
# Canopy band corrections: adjust a LANDFIRE canopy band across the AOI
# toward the value measured by TLS (or submitted by the user) at the scanned
# plots, instead of only replacing the cells under each plot.
#
# Bands corrected (LCP units): canopy cover (band 5, percent), stand height
# (band 6, m x 10) and canopy base height (band 7, m x 10). Only LANDFIRE
# canopy cells (band value > 0) inside the AOI change; cells without canopy
# stay 0. Stand height is corrected before CBH so CBH is capped at the
# corrected stand height.
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
#
# Crown check (check_crown_length), run last on every cell inside the AOI,
# whether or not a correction moved its value, and on the burned-in plots
# outside it. Cells outside the AOI otherwise keep LANDFIRE's values.
#   1. rescale - stand height lowered and CBH still LANDFIRE's: CBH is scaled
#                by new / LANDFIRE height, keeping LANDFIRE's crown ratio.
#                CBH is left alone where stand height rose.
#   2. cap     - CBH at most (1 - MIN_CROWN_RATIO) of stand height, so the
#                crown is at least 10% of the tree.
#   3. clear   - no stand height, no CBH.
# ---------------------------------------------------------------------------
box::use(
  data.table[as.data.table],
  sf[st_transform],
  stats[sd],
  terra,
)

#' Smallest crown length, as a share of stand height, a cell may have.
#' @export
MIN_CROWN_RATIO <- 0.1

# Largest CBH a cell may have: (1 - MIN_CROWN_RATIO) of its stand height, in
# whole LCP units so rounding never pushes CBH back over it.
cbh_limit <- function(height) floor((1 - MIN_CROWN_RATIO) * height)

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
  stand_height = list(
    label = "Stand height", unit = "m", scale = 10,
    even_trend_required = FALSE, min_fraction = 0.5,
    cap = function(stack) rep(1500, terra$ncell(stack)), cap_label = "150 m"
  ),
  canopy_base = list(
    label = "Canopy base height", unit = "m", scale = 10,
    even_trend_required = TRUE, min_fraction = 0.5,
    cap = function(stack) {
      height <- terra$values(stack[["stand_height"]], mat = FALSE)
      ifelse(!is.na(height) & height > 0, cbh_limit(height), Inf)
    },
    cap_label = "90% of stand height"
  )
)

# The AOI polygon in the raster's CRS.
aoi_vect <- function(aoi, layer) {
  terra$project(terra$vect(st_transform(aoi, 4326)), terra$crs(layer))
}

# TRUE for each cell of `layer` inside the AOI; every cell when aoi is NULL.
aoi_cells <- function(layer, aoi) {
  if (is.null(aoi)) {
    return(rep(TRUE, terra$ncell(layer)))
  }
  inside <- terra$rasterize(aoi_vect(aoi, layer), layer, background = 0)
  terra$values(inside, mat = FALSE) == 1
}

#' Correct a LANDFIRE canopy band toward the values measured at the scans.
#'
#' @param stack 8-band LCP stack (before the plot values are burned in)
#' @param obs_dt one row per plot: Longitude, Latitude, value (LCP units)
#' @param band "canopy_cover", "stand_height" or "canopy_base"
#' @param aoi optional sf polygon; NULL uses the whole landscape
#' @param trend_cv largest SD / |mean| of the differences that still counts
#'   as an even trend (rule 1, CBH)
#' @return list(stack, info); info records the rule used and its numbers in
#'   display units (% or m)
#' @export
correct_landfire_canopy <- function(stack, obs_dt, band = names(CANOPY_CORRECTIONS),
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
  in_aoi <- aoi_cells(layer, aoi)
  scans_in_aoi <- if (is.null(aoi)) {
    rep(TRUE, nrow(obs))
  } else {
    as.vector(terra$is.related(pts, aoi_vect(aoi, layer), "intersects"))
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

#' Keep CBH below stand height inside the AOI and on the burned-in plots.
#'
#' @param stack 8-band LCP stack after the corrections and the lidar burn
#' @param landfire the LANDFIRE stack before any change
#' @param aoi optional sf polygon; NULL checks the whole landscape
#' @param rescale TRUE scales LANDFIRE CBH down with a lowered stand height
#'   (use when CBH itself was not corrected)
#' @return list(stack, info); info counts the cells rescaled, capped and cleared
#' @export
check_crown_length <- function(stack, landfire, aoi = NULL, rescale = TRUE) {
  h_lf <- terra$values(landfire[["stand_height"]], mat = FALSE)
  cbh_lf <- terra$values(landfire[["canopy_base"]], mat = FALSE)
  h <- terra$values(stack[["stand_height"]], mat = FALSE)
  cbh <- terra$values(stack[["canopy_base"]], mat = FALSE)

  # changed cells outside the AOI are the burned-in plots
  changed <- (h != h_lf) | (cbh != cbh_lf)
  checked <- (aoi_cells(stack, aoi) | (!is.na(changed) & changed)) & !is.na(h) & !is.na(cbh)

  rescaled <- rescale & checked & cbh == cbh_lf & h < h_lf & h_lf > 0 & cbh > 0
  cbh[rescaled] <- round(cbh[rescaled] * h[rescaled] / h_lf[rescaled])

  cleared <- checked & h <= 0 & cbh > 0
  cbh[cleared] <- 0

  limit <- cbh_limit(h)
  capped <- checked & h > 0 & cbh > limit
  cbh[capped] <- limit[capped]

  stack[["canopy_base"]] <- terra$setValues(stack[["canopy_base"]], cbh)
  info <- list(
    cells_rescaled = sum(rescaled), cells_capped = sum(capped), cells_cleared = sum(cleared)
  )
  list(stack = stack, info = info)
}

#' One-line description of the crown check, for notifications.
#' @export
describe_crown_check <- function(info) {
  if (is.null(info)) {
    return("")
  }
  sprintf(
    paste(
      "Crown check: %d cells had CBH scaled with a lowered stand height, %d capped at",
      "%d%% of stand height, %d cleared where there is no stand height."
    ),
    info$cells_rescaled, info$cells_capped, round((1 - MIN_CROWN_RATIO) * 100),
    info$cells_cleared
  )
}
