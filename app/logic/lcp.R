# app/logic/lcp.R
# ---------------------------------------------------------------------------
# FlamMap/FARSITE landscape (.LCP) builder.
#
# Pipeline:
#   1. AOI      - buffered bounding box (WGS84) around the selected plots
#   2. LANDFIRE - request the 8 LCP layers from the LANDFIRE Product Service
#                 (LFPS) and read them back as a single 8-band stack
#   3. canopy   - correct the LANDFIRE canopy cover (band 5), stand height
#                 (band 6) and canopy base height (band 7) across the AOI
#                 toward the scans' values (rules in app/logic/lcp_canopy.R)
#   4. lidar    - burn the plot-level lidar canopy metrics into bands 5-7
#                 (canopy cover, stand height, canopy base height) in a disc
#                 around each plot. Bands 1-4 (elevation, slope, aspect, fuel
#                 model) and 8 (canopy bulk density) stay LANDFIRE derived.
#   5. crown    - keep CBH at most 90% of stand height inside the AOI and on
#                 the plots, scaling LANDFIRE CBH down where stand height was
#                 lowered
#   6. surface  - when modeled surface fuel loadings were submitted, swap the
#                 burnable fuel models (band 4) in the AOI for custom twins
#                 scaled class by class to them (app/logic/lcp_surface.R)
#   7. write    - write the binary .LCP and its .prj (app/logic/lcp_format.R)
#   8. bundle   - zip the .lcp with its .prj (and the custom fuel model .fmd)
#                 so the projection and fuel models travel with it
#   9. IFTDSS   - optionally write the same landscape as the GeoTIFF IFTDSS
#                 accepts as a custom landscape (write_iftdss_tif): the 8 LCP
#                 bands plus LANDFIRE FCCS fuelbeds and map zones as bands
#                 9-10, the layout IFTDSS uses since version 3.12. It keeps
#                 LANDFIRE's standard fuel models: IFTDSS doesn't read .fmd
#                 custom fuel models.
#
# Units: LANDFIRE already stores every layer in the LCP convention, so the
# LANDFIRE bands pass through unchanged. The lidar metrics are converted:
#   canopyCover  0-1   -> percent
#   MaxTH, CBH   m     -> m x 10
# LFPS requires a contact email; in the app it comes from the global email
# prompt (app/view/email_prompt.R).
# ---------------------------------------------------------------------------
box::use(
  data.table[as.data.table, setorder],
  rlandfire[landfireAPIv2],
  sf[st_bbox, st_transform],
  terra,
  utils[unzip],
  zip[zip],
)

box::use(
  app/logic/lcp_canopy[CANOPY_CORRECTIONS, check_crown_length, correct_landfire_canopy],
  app/logic/lcp_format[write_esri_prj, write_lcp_binary],
  app/logic/lcp_surface[normalize_surface_fuels, write_fmd],
)

#' LCP band spec, in the order the LCP format stores them.
#'
#' `product` is the LFPS layer name (`{version}` is filled in by lcp_products()).
#' `metric` is the lidar column burned into that band; NA keeps LANDFIRE.
#' `to_lcp` converts the lidar metric into the band's LCP unit.
#' `range` is the plausible range of the LCP values, used to check band order.
#' `water` is the value written where LANDFIRE has no data (open ocean): the
#' same values LANDFIRE uses for inland water, i.e. flat, fuel model 98 (NB8).
#' @export
LCP_BANDS <- list(
  list(
    name = "elevation", product = "LF2020_Elev", metric = NA_character_,
    to_lcp = identity, range = c(-100, 6200), water = 0
  ),
  list(
    name = "slope", product = "LF2020_SlpD", metric = NA_character_,
    to_lcp = identity, range = c(0, 90), water = 0
  ),
  list(
    name = "aspect", product = "LF2020_Asp", metric = NA_character_,
    to_lcp = identity, range = c(-1, 360), water = -1
  ),
  list(
    name = "fuel", product = "{version}_FBFM40", metric = NA_character_,
    to_lcp = identity, range = c(91, 204), water = 98
  ),
  list(
    name = "canopy_cover", product = "{version}_CC", metric = "canopyCover",
    to_lcp = function(x) pmin(pmax(round(x * 100), 0), 100), range = c(0, 100),
    water = 0
  ),
  list(
    name = "stand_height", product = "{version}_CH", metric = "MaxTH",
    to_lcp = function(x) round(x * 10), range = c(0, 1500), water = 0
  ),
  list(
    name = "canopy_base", product = "{version}_CBH", metric = "CBH",
    to_lcp = function(x) round(x * 10), range = c(0, 1000), water = 0
  ),
  list(
    name = "canopy_bulk", product = "{version}_CBD", metric = NA_character_,
    to_lcp = identity, range = c(0, 100), water = 0
  )
)

band_names <- function() vapply(LCP_BANDS, `[[`, character(1), "name")

#' LANDFIRE layers IFTDSS (version 3.12 on) stores after the 8 LCP bands.
#'
#' They are categorical and pass through uncorrected. LANDFIRE publishes FCCS
#' fuelbeds for LF2023 and LF2025 but not LF2024; LF2023 sits closest to the
#' LF2024 fuel layers.
#' @export
IFTDSS_EXTRA_BANDS <- list(
  list(name = "fccs", product = "LF2023_FCCS"),
  list(name = "map_zone", product = "map_zones")
)

#' LFPS layer names for the LCP bands, in LCP order.
#'
#' Topography is only published as LF2020; `version` selects the fuel and
#' canopy release (LF2024 is the latest with full CONUS coverage).
#' @export
lcp_products <- function(version = "LF2024") {
  products <- vapply(LCP_BANDS, `[[`, character(1), "product")
  sub("{version}", version, products, fixed = TRUE)
}

#' Buffered AOI around the plots, as c(xmin, ymin, xmax, ymax) in WGS84.
#'
#' @param plots_dt table with Longitude and Latitude columns
#' @param buffer_m buffer around the plots in meters
#' @export
build_lcp_aoi <- function(plots_dt, buffer_m = 2000) {
  pts <- terra$vect(
    as.data.frame(plots_dt),
    geom = c("Longitude", "Latitude"), crs = "EPSG:4326"
  )
  pts_albers <- terra$project(pts, "EPSG:5070")
  aoi <- terra$project(terra$buffer(pts_albers, width = buffer_m), "EPSG:4326")
  e <- terra$ext(aoi)
  unname(c(e$xmin, e$ymin, e$xmax, e$ymax))
}

#' Check that each band's values fall in its plausible LCP range.
#'
#' LFPS returns one multiband GeoTIFF; this guards the assumption that its
#' bands come back in the requested (LCP) order.
#' @return named logical vector, TRUE where the band is in range
#' @export
check_band_ranges <- function(stack) {
  rng <- terra$minmax(stack, compute = TRUE)
  ok <- vapply(seq_along(LCP_BANDS), function(i) {
    lim <- LCP_BANDS[[i]]$range
    rng[1, i] >= lim[1] && rng[2, i] <= lim[2]
  }, logical(1))
  names(ok) <- band_names()
  ok
}

#' Read the LFPS GeoTIFF as a named stack: the 8 LCP bands, then `extra_bands`.
#'
#' @param tif the multiband GeoTIFF LFPS returns
#' @param extra_bands entries of IFTDSS_EXTRA_BANDS requested after the LCP layers
#' @export
read_landfire_stack <- function(tif, extra_bands = list()) {
  stack <- terra$rast(tif)
  expected <- length(LCP_BANDS) + length(extra_bands)
  if (terra$nlyr(stack) != expected) {
    stop("LANDFIRE returned ", terra$nlyr(stack), " bands; expected ", expected, ".")
  }
  names(stack) <- c(band_names(), vapply(extra_bands, `[[`, character(1), "name"))

  in_range <- check_band_ranges(stack[[seq_along(LCP_BANDS)]])
  if (!all(in_range)) {
    stop(
      "LANDFIRE bands out of their expected range (wrong order?): ",
      paste(names(in_range)[!in_range], collapse = ", ")
    )
  }
  stack
}

#' Download the 8 LCP layers (and any extra layers) from LFPS as a named stack.
#'
#' @param aoi c(xmin, ymin, xmax, ymax) in WGS84
#' @param email LFPS contact email
#' @param version LANDFIRE release for the fuel and canopy layers
#' @param extra_bands entries of IFTDSS_EXTRA_BANDS to request after the LCP layers
#' @param out_dir directory the LFPS zip is downloaded and unpacked into
#' @param max_time seconds to wait for the LFPS job before giving up
#' @export
fetch_landfire_stack <- function(aoi,
                                 email,
                                 version = "LF2024",
                                 extra_bands = list(),
                                 out_dir = tempfile("landfire_"),
                                 max_time = 900) {
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  zip_path <- file.path(out_dir, "landfire.zip")

  products <- c(lcp_products(version), vapply(extra_bands, `[[`, character(1), "product"))
  job <- landfireAPIv2(
    products = products, aoi = aoi, email = email,
    projection = 5070, path = zip_path, max_time = max_time,
    method = "libcurl", verbose = FALSE
  )
  if (!identical(job$status, "Succeeded") || !file.exists(zip_path)) {
    stop("LANDFIRE request did not succeed (status: ", job$status, ").")
  }

  unzip(zip_path, exdir = out_dir)
  tif <- list.files(out_dir, pattern = "\\.tif$", full.names = TRUE, recursive = TRUE)
  if (length(tif) != 1) {
    stop("Expected one GeoTIFF from LANDFIRE, found ", length(tif), ".")
  }
  read_landfire_stack(tif, extra_bands)
}

#' Latest scan per plot with its coordinates and lidar canopy metrics.
#'
#' @param metrics_dt scan metrics (site, plot, date + metric columns)
#' @param plots_dt plot locations (site, plot, Longitude, Latitude)
latest_plot_metrics <- function(metrics_dt, plots_dt) {
  metric_cols <- Filter(Negate(is.na), vapply(LCP_BANDS, `[[`, character(1), "metric"))
  m <- as.data.table(metrics_dt)[, c("site", "plot", "date", metric_cols), with = FALSE]
  setorder(m, site, plot, -date)
  m <- m[!duplicated(m, by = c("site", "plot"))]

  locs <- unique(as.data.table(plots_dt)[, .(site, plot, Longitude, Latitude)], by = c("site", "plot"))
  m <- merge(m, locs, by = c("site", "plot"))
  m[!is.na(Longitude) & !is.na(Latitude)]
}

#' Burn the lidar canopy metrics into bands 5-7 around each plot.
#'
#' Every cell whose center lies within `plot_radius_m` of a plot takes that
#' plot's value; a plot missing a metric keeps LANDFIRE for that band.
#' @param stack 8-band LCP stack from fetch_landfire_stack()
#' @param plot_radius_m radius of the disc burned around each plot
#' @export
burn_lidar_canopy <- function(stack, metrics_dt, plots_dt, plot_radius_m = 30) {
  m <- latest_plot_metrics(metrics_dt, plots_dt)
  if (nrow(m) == 0) {
    return(stack)
  }

  pts <- terra$vect(as.data.frame(m), geom = c("Longitude", "Latitude"), crs = "EPSG:4326")
  discs <- terra$buffer(terra$project(pts, terra$crs(stack)), width = plot_radius_m)

  for (b in Filter(function(b) !is.na(b$metric), LCP_BANDS)) {
    discs$burn_value <- b$to_lcp(as.numeric(m[[b$metric]]))
    has_value <- !is.na(discs$burn_value)
    if (!any(has_value)) next

    burned <- terra$rasterize(discs[has_value], stack[[b$name]], field = "burn_value")
    stack[[b$name]] <- terra$cover(burned, stack[[b$name]])
  }
  stack
}

#' Write the 8-band stack to a binary FlamMap .LCP.
#'
#' The file is written in R (app/logic/lcp_format.R) rather than with GDAL's
#' LCP driver, which crashes on negative values before GDAL 3.6.4. Units:
#' elevation m, slope degrees, aspect azimuth degrees, cover %, heights
#' m x 10, CBD kg/m^3 x 100. Cells LANDFIRE leaves empty (open ocean) are
#' written as water (see LCP_BANDS). A .prj is written alongside.
#' @param stack 8-band stack in LCP band order, projected in meters
#' @param lcp_path output .lcp file
#' @param custom_fuels TRUE when band 4 holds custom fuel model numbers
#' @export
write_lcp <- function(stack, lcp_path, custom_fuels = FALSE) {
  if (terra$nlyr(stack) != length(LCP_BANDS)) {
    stop("An LCP needs ", length(LCP_BANDS), " bands; got ", terra$nlyr(stack), ".")
  }

  # LCP header latitude (whole degrees) of the landscape center
  wgs84 <- terra$project(terra$ext(stack), from = terra$crs(stack), to = "EPSG:4326")
  latitude <- round((wgs84$ymin + wgs84$ymax) / 2)

  values <- round(terra$values(stack))
  for (i in seq_along(LCP_BANDS)) {
    values[is.na(values[, i]), i] <- LCP_BANDS[[i]]$water
  }
  values <- pmin(pmax(values, -32768), 32767)

  write_lcp_binary(
    lcp_path, values,
    ncol = terra$ncol(stack), nrow = terra$nrow(stack),
    extent = as.vector(terra$ext(stack)), resolution = terra$res(stack),
    latitude = latitude, custom_fuels = custom_fuels
  )
  write_esri_prj(terra$crs(stack), sub("\\.lcp$", ".prj", lcp_path))
  lcp_path
}

# IFTDSS custom landscape limits that are tighter than the LCP's (see
# https://iftdss.firenet.gov/firenetHelp/help/pageHelp/content/20-landscapes/lcpuploadrequirements.htm)
IFTDSS_MAX_HEIGHT <- 1200 # stand height, m x 10
IFTDSS_MAX_CBD <- 50 # kg/m^3 x 100
IFTDSS_MAX_NODATA <- 0.5 # share of NoData cells IFTDSS accepts
IFTDSS_NODATA <- -9999

#' Write the stack as the GeoTIFF IFTDSS accepts as a custom landscape.
#'
#' The 8 LCP bands (same order and units as the LCP), followed by FCCS
#' fuelbeds and map zones as bands 9-10 when the stack carries them
#' (IFTDSS_EXTRA_BANDS), as 32-bit integers with -9999 for cells LANDFIRE
#' leaves empty. 32 bits because LANDFIRE codes a disturbed FCCS fuelbed as
#' fuelbed * 10000 + disturbance (e.g. 5310122), past the 16-bit limit.
#' Values are held to IFTDSS's limits: stand height at most 120 m, CBH at
#' most the stand height in every cell, CBD at most 0.50 kg/m^3.
#' @param stack 8-band stack in LCP band order, or 10 bands with
#'   IFTDSS_EXTRA_BANDS after them, projected in meters
#' @param tif_path output .tif; IFTDSS rejects names with other "." in them
#' @return tif_path, with the cells changed per band in attr(, "clamped") and
#'   the share of NoData cells in attr(, "nodata_share")
#' @export
write_iftdss_tif <- function(stack, tif_path) {
  layer_names <- c(band_names(), vapply(IFTDSS_EXTRA_BANDS, `[[`, character(1), "name"))
  n_bands <- terra$nlyr(stack)
  if (!n_bands %in% c(length(LCP_BANDS), length(layer_names))) {
    stop(
      "IFTDSS needs ", length(LCP_BANDS), " or ", length(layer_names), " bands; got ",
      n_bands, "."
    )
  }
  if (abs(diff(terra$res(stack))) > 1e-6) stop("IFTDSS needs square cells.")

  values <- round(terra$values(stack))
  colnames(values) <- layer_names[seq_len(n_bands)]
  h <- values[, "stand_height"]
  over_h <- !is.na(h) & h > IFTDSS_MAX_HEIGHT
  h[over_h] <- IFTDSS_MAX_HEIGHT
  cbh <- values[, "canopy_base"]
  over_cbh <- !is.na(cbh) & !is.na(h) & cbh > h
  cbh[over_cbh] <- h[over_cbh]
  cbd <- values[, "canopy_bulk"]
  over_cbd <- !is.na(cbd) & cbd > IFTDSS_MAX_CBD
  cbd[over_cbd] <- IFTDSS_MAX_CBD
  values[, "stand_height"] <- h
  values[, "canopy_base"] <- cbh
  values[, "canopy_bulk"] <- cbd

  if (any(abs(values) > .Machine$integer.max, na.rm = TRUE)) {
    stop("A landscape value does not fit in a 32-bit integer.")
  }
  out <- terra$setValues(stack, values)
  names(out) <- colnames(values)
  dir.create(dirname(tif_path), recursive = TRUE, showWarnings = FALSE)
  terra$writeRaster(
    out, tif_path,
    datatype = "INT4S", NAflag = IFTDSS_NODATA, overwrite = TRUE, gdal = "COMPRESS=DEFLATE"
  )
  attr(tif_path, "clamped") <- c(
    stand_height = sum(over_h), canopy_base = sum(over_cbh), canopy_bulk = sum(over_cbd)
  )
  # NoData share over the LCP bands; FCCS has gaps of its own (e.g. water)
  attr(tif_path, "nodata_share") <- mean(rowSums(is.na(values[, band_names()])) > 0)
  attr(tif_path, "bands") <- n_bands
  tif_path
}

#' One-line description of the IFTDSS GeoTIFF, for notifications.
#' @export
describe_iftdss_tif <- function(tif) {
  if (is.null(tif)) {
    return("")
  }
  clamped <- attr(tif, "clamped")
  msg <- sprintf(
    paste(
      "GeoTIFF: %d cells' stand height capped at 120 m, %d cells' CBH capped at",
      "stand height, %d cells' CBD capped at 0.50 kg/m^3."
    ),
    clamped[["stand_height"]], clamped[["canopy_base"]], clamped[["canopy_bulk"]]
  )
  if (attr(tif, "bands") == length(LCP_BANDS)) {
    msg <- paste(
      msg, "LANDFIRE could not supply FCCS fuelbeds and map zones, so the file has the",
      "8 LCP bands only."
    )
  }
  share <- attr(tif, "nodata_share")
  if (share > IFTDSS_MAX_NODATA) {
    msg <- sprintf(
      "%s %.0f%% of the cells have no LANDFIRE data; IFTDSS rejects more than %.0f%%.",
      msg, share * 100, IFTDSS_MAX_NODATA * 100
    )
  }
  msg
}

#' Build a FlamMap .LCP for the plots in `metrics_dt`.
#'
#' @param metrics_dt scan metrics (site, plot, date, canopyCover, MaxTH, CBH)
#' @param plots_dt plot locations (site, plot, Longitude, Latitude)
#' @param email LFPS contact email
#' @param zip_path output .zip holding `{name}.lcp` and `{name}.prj`
#' @param name base file name used inside the zip
#' @param aoi optional sf polygon drawn by the user; the landscape is widened
#'   to cover it and the canopy corrections are limited to it
#' @param cbh_m optional user-submitted CBH (m); the scans' CBH values are
#'   shifted so their mean matches it
#' @param cover_pct optional user-submitted canopy cover (%); the scans' cover
#'   values are shifted so their mean matches it
#' @param height_m optional user-submitted stand height (m); the scans' MaxTH
#'   values are shifted so their mean matches it
#' @param tif_path optional output .tif; when given, the same landscape is also
#'   written as an IFTDSS GeoTIFF (see write_iftdss_tif())
#' @param progress function(message) called at each step
#' @return zip_path, with the IFTDSS GeoTIFF path in attr(, "iftdss_tif"), the canopy correction details (see
#'   app/logic/lcp_canopy.R) in attr(, "canopy_corrections"), a list with
#'   one entry per corrected band, and the crown check counts in
#'   attr(, "crown_check")
#' @export
build_flammap_lcp <- function(metrics_dt,
                              plots_dt,
                              email,
                              zip_path = tempfile(fileext = ".zip"),
                              name = "intelimon",
                              aoi = NULL,
                              cbh_m = NULL,
                              cover_pct = NULL,
                              height_m = NULL,
                              buffer_m = 2000,
                              plot_radius_m = 30,
                              version = "LF2024",
                              tif_path = NULL,
                              surface_scans = NULL,
                              surface_system = "FBFM40",
                              surface_label = NULL,
                              progress = message) {
  progress("Building AOI from selected plots...")
  plots <- latest_plot_metrics(metrics_dt, plots_dt)
  if (nrow(plots) == 0) stop("No plot coordinates match the metrics table.")
  extent <- build_lcp_aoi(plots, buffer_m = buffer_m)
  if (!is.null(aoi)) {
    drawn <- st_bbox(st_transform(aoi, 4326))
    extent <- c(
      min(extent[1], drawn[["xmin"]]), min(extent[2], drawn[["ymin"]]),
      max(extent[3], drawn[["xmax"]]), max(extent[4], drawn[["ymax"]])
    )
  }

  # a user-submitted value moves the scans' mean onto it, keeping their spread
  user_mean <- function(x, target) {
    if (is.null(target) || is.na(target) || all(is.na(x))) x else x + (target - mean(x, na.rm = TRUE))
  }
  plots$CBH <- user_mean(plots$CBH, cbh_m)
  cover_target <- if (is.null(cover_pct)) NULL else cover_pct / 100 # scans store cover as 0-1
  plots$canopyCover <- user_mean(plots$canopyCover, cover_target)
  plots$MaxTH <- user_mean(plots$MaxTH, height_m)

  progress("Requesting LANDFIRE layers...")
  # the IFTDSS GeoTIFF also carries FCCS fuelbeds and map zones; if LANDFIRE
  # can't supply them, build the landscape without them rather than fail
  extra <- if (is.null(tif_path)) list() else IFTDSS_EXTRA_BANDS
  stack <- tryCatch(
    fetch_landfire_stack(extent, email = email, version = version, extra_bands = extra),
    error = function(e) {
      if (length(extra) == 0) stop(e)
      progress("Retrying LANDFIRE without the FCCS and map zone layers...")
      fetch_landfire_stack(extent, email = email, version = version)
    }
  )
  landfire <- stack[[c("stand_height", "canopy_base")]]

  # LCP order puts stand height before CBH, so CBH is capped at the corrected height
  progress("Correcting LANDFIRE canopy cover, stand height and base height (bands 5-7)...")
  corrections <- list()
  for (b in Filter(function(b) b$name %in% names(CANOPY_CORRECTIONS), LCP_BANDS)) {
    obs <- plots[, .(Longitude, Latitude)]
    obs$value <- b$to_lcp(as.numeric(plots[[b$metric]]))
    corrected <- correct_landfire_canopy(stack, obs, band = b$name, aoi = aoi)
    stack <- corrected$stack
    corrections[[b$name]] <- corrected$info
  }

  progress("Burning lidar canopy metrics into bands 5-7...")
  stack <- burn_lidar_canopy(stack, plots, plots, plot_radius_m = plot_radius_m)

  progress("Checking canopy base height against stand height...")
  crown <- check_crown_length(
    stack, landfire,
    aoi = aoi, rescale = identical(corrections$canopy_base$rule, "none")
  )
  stack <- crown$stack

  # the custom fuel models go into the LCP only; the IFTDSS GeoTIFF below
  # keeps the standard models in `stack`
  surface <- NULL
  if (!is.null(surface_scans) && nrow(surface_scans) > 0) {
    progress("Scaling surface fuel models (band 4) to the submitted loadings...")
    surface <- normalize_surface_fuels(
      stack, surface_scans,
      aoi = aoi, system = surface_system, label = surface_label
    )
  }
  lcp_stack <- if (is.null(surface)) stack else surface$stack

  progress("Writing .LCP...")
  lcp_path <- write_lcp(
    lcp_stack[[seq_along(LCP_BANDS)]], tempfile(fileext = ".lcp"),
    custom_fuels = !is.null(surface)
  )
  on.exit(unlink(sub("\\.lcp$", ".*", lcp_path)), add = TRUE)
  fmd_path <- if (!is.null(surface)) write_fmd(surface$models, tempfile(fileext = ".fmd"))
  out <- bundle_lcp(lcp_path, zip_path, name = name, fmd_path = fmd_path)
  if (!is.null(tif_path)) {
    progress("Writing IFTDSS GeoTIFF...")
    attr(out, "iftdss_tif") <- write_iftdss_tif(stack, tif_path)
  }
  attr(out, "surface_fuels") <- surface$info
  attr(out, "canopy_corrections") <- corrections
  attr(out, "crown_check") <- crown$info
  out
}

#' Zip the LCP bundle and the GeoTIFF together, for "Save both".
#'
#' @param lcp_zip .zip from bundle_lcp()
#' @param tif_path GeoTIFF from write_iftdss_tif()
#' @param zip_path output .zip holding the LCP bundle's files and the .tif
#' @return zip_path
#' @export
bundle_fuel_rasters <- function(lcp_zip, tif_path, zip_path) {
  staging <- tempfile("fuel_rasters_")
  dir.create(staging)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  unzip(lcp_zip, exdir = staging)
  file.copy(tif_path, staging)

  if (file.exists(zip_path)) file.remove(zip_path)
  zip(zip_path, list.files(staging), root = staging)
  zip_path
}

#' Zip an .lcp with the .prj written alongside it, and its custom fuel models.
#'
#' The files are renamed to `name` inside the zip so they stay paired.
#' @param lcp_path .lcp written by write_lcp()
#' @param zip_path output .zip
#' @param name base file name used inside the zip
#' @param fmd_path optional custom fuel model file (write_fmd())
#' @return zip_path
#' @export
bundle_lcp <- function(lcp_path, zip_path, name = "intelimon", fmd_path = NULL) {
  prj_path <- sub("\\.lcp$", ".prj", lcp_path)
  if (!file.exists(prj_path)) stop("No .prj found next to ", lcp_path, ".")

  staging <- tempfile("lcp_bundle_")
  dir.create(staging)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  sources <- c(lcp = lcp_path, prj = prj_path, fmd = fmd_path)
  files <- paste0(name, ".", names(sources))
  file.copy(sources, file.path(staging, files))

  if (file.exists(zip_path)) file.remove(zip_path)
  zip(zip_path, files, root = staging)
  zip_path
}
