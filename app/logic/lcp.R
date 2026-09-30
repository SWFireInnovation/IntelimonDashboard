# app/logic/lcp.R
# ---------------------------------------------------------------------------
# FlamMap/FARSITE landscape (.LCP) builder.
#
# Pipeline:
#   1. AOI      - buffered bounding box (WGS84) around the selected plots
#   2. LANDFIRE - request the 8 LCP layers from the LANDFIRE Product Service
#                 (LFPS) and read them back as a single 8-band stack
#   3. lidar    - burn the plot-level lidar canopy metrics into bands 5-7
#                 (canopy cover, stand height, canopy base height) in a disc
#                 around each plot. Bands 1-4 (elevation, slope, aspect, fuel
#                 model) and 8 (canopy bulk density) stay LANDFIRE derived.
#   4. write    - write the binary .LCP and its .prj (app/logic/lcp_format.R)
#   5. bundle   - zip the .lcp with its .prj so the projection travels with it
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
  terra,
  utils[unzip],
  zip[zip],
)

box::use(
  app/logic/lcp_format[write_esri_prj, write_lcp_binary],
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

#' Download the 8 LCP layers from LFPS and read them as a named stack.
#'
#' @param aoi c(xmin, ymin, xmax, ymax) in WGS84
#' @param email LFPS contact email
#' @param version LANDFIRE release for the fuel and canopy layers
#' @param out_dir directory the LFPS zip is downloaded and unpacked into
#' @param max_time seconds to wait for the LFPS job before giving up
#' @export
fetch_landfire_stack <- function(aoi,
                                 email,
                                 version = "LF2024",
                                 out_dir = tempfile("landfire_"),
                                 max_time = 900) {
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  zip_path <- file.path(out_dir, "landfire.zip")

  job <- landfireAPIv2(
    products = lcp_products(version), aoi = aoi, email = email,
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

  stack <- terra$rast(tif)
  if (terra$nlyr(stack) != length(LCP_BANDS)) {
    stop("LANDFIRE returned ", terra$nlyr(stack), " bands; expected ", length(LCP_BANDS), ".")
  }
  names(stack) <- band_names()

  in_range <- check_band_ranges(stack)
  if (!all(in_range)) {
    stop(
      "LANDFIRE bands out of their expected range (wrong order?): ",
      paste(names(in_range)[!in_range], collapse = ", ")
    )
  }
  stack
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
#' @export
write_lcp <- function(stack, lcp_path) {
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
    latitude = latitude
  )
  write_esri_prj(terra$crs(stack), sub("\\.lcp$", ".prj", lcp_path))
  lcp_path
}

#' Build a FlamMap .LCP for the plots in `metrics_dt`.
#'
#' @param metrics_dt scan metrics (site, plot, date, canopyCover, MaxTH, CBH)
#' @param plots_dt plot locations (site, plot, Longitude, Latitude)
#' @param email LFPS contact email
#' @param zip_path output .zip holding `{name}.lcp` and `{name}.prj`
#' @param name base file name used inside the zip
#' @param progress function(message) called at each step
#' @return zip_path
#' @export
build_flammap_lcp <- function(metrics_dt,
                              plots_dt,
                              email,
                              zip_path = tempfile(fileext = ".zip"),
                              name = "intelimon",
                              buffer_m = 2000,
                              plot_radius_m = 30,
                              version = "LF2024",
                              progress = message) {
  progress("Building AOI from selected plots...")
  plots <- latest_plot_metrics(metrics_dt, plots_dt)
  if (nrow(plots) == 0) stop("No plot coordinates match the metrics table.")
  aoi <- build_lcp_aoi(plots, buffer_m = buffer_m)

  progress("Requesting LANDFIRE layers...")
  stack <- fetch_landfire_stack(aoi, email = email, version = version)

  progress("Burning lidar canopy metrics into bands 5-7...")
  stack <- burn_lidar_canopy(stack, metrics_dt, plots_dt, plot_radius_m = plot_radius_m)

  progress("Writing .LCP...")
  lcp_path <- write_lcp(stack, tempfile(fileext = ".lcp"))
  on.exit(unlink(sub("\\.lcp$", ".*", lcp_path)), add = TRUE)
  bundle_lcp(lcp_path, zip_path, name = name)
}

#' Zip an .lcp with the .prj GDAL writes alongside it.
#'
#' Both files are renamed to `name` inside the zip so they stay paired.
#' @param lcp_path .lcp written by write_lcp()
#' @param zip_path output .zip
#' @param name base file name used inside the zip
#' @return zip_path
#' @export
bundle_lcp <- function(lcp_path, zip_path, name = "intelimon") {
  prj_path <- sub("\\.lcp$", ".prj", lcp_path)
  if (!file.exists(prj_path)) stop("No .prj found next to ", lcp_path, ".")

  staging <- tempfile("lcp_bundle_")
  dir.create(staging)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  files <- paste0(name, c(".lcp", ".prj"))
  file.copy(c(lcp_path, prj_path), file.path(staging, files))

  if (file.exists(zip_path)) file.remove(zip_path)
  zip(zip_path, files, root = staging)
  zip_path
}
