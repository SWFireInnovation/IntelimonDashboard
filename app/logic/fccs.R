# app/logic/fccs.R
# ---------------------------------------------------------------------------
# FCCS bulk-density crosswalk: turn measured fuel depths into loadings.
#
# LANDFIRE's FCCS layer gives each plot a fuelbed (or disturbed-fuelbed)
# code. app/data/fccs_bulk_density.csv (built by
# data-raw/build_fccs_bulk_density.R) holds, per code, the stand-level bulk
# density (kg/m^3) of
#   litter  - LANDFIRE Consume litter loading / litter depth
#   live    - live shrub + herb loading / load-weighted shrub-herb height
# Multiplying by the depth measured at the plot gives a loading:
#   live loading = live_bd * MFBDmod (mean fuel bed depth, cm)
# Litter bulk density is kept in the crosswalk for reference, but litter is
# not scaled to a loading: the MLDmod litter depths are not reliable yet.
# Codes whose shrub/herb heights are unknown (height_source "none") return NA
# for the live loading rather than a guess.
# ---------------------------------------------------------------------------
box::use(
  data.table[as.data.table, data.table, fread],
  here[here],
  rlandfire[landfireAPIv2],
  terra,
  utils[unzip],
)

box::use(
  app/logic/lcp[build_lcp_aoi],
)

# kg/m^2 in one ton/acre
TPA_TO_KGM2 <- 907.18474 / 4046.8564224

.cache <- new.env()

#' The FCCS bulk-density crosswalk (one row per LANDFIRE FCCS code).
#' @export
fccs_crosswalk <- function(path = here("app/data/fccs_bulk_density.csv")) {
  if (is.null(.cache$crosswalk)) {
    .cache$crosswalk <- fread(path)
  }
  .cache$crosswalk
}

#' Crosswalk rows for LANDFIRE FCCS codes, in the order given.
#'
#' Unknown codes return a row of NAs, so the result lines up with `codes`.
#' @export
fccs_bulk_density <- function(codes) {
  xw <- fccs_crosswalk()
  out <- xw[match(as.integer(codes), xw$fccs)]
  out$fccs <- as.integer(codes)
  out
}

#' LANDFIRE FCCS code at each plot.
#'
#' Requests the FCCS layer for a small box around the plots and samples the
#' cell under each plot.
#' @param plots_dt plot locations (site, plot, Longitude, Latitude)
#' @param email LFPS contact email
#' @param version LANDFIRE release (LF2023 is the latest with full coverage)
#' @return data.table: site, plot, fccs
#' @export
fetch_landfire_fccs <- function(plots_dt,
                                email,
                                version = "LF2023",
                                buffer_m = 150,
                                out_dir = tempfile("landfire_fccs_"),
                                max_time = 900) {
  plots <- unique(as.data.table(plots_dt)[!is.na(Longitude) & !is.na(Latitude)],
    by = c("site", "plot")
  )
  if (nrow(plots) == 0) stop("No plot coordinates to look up.")

  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  zip_path <- file.path(out_dir, "fccs.zip")
  job <- landfireAPIv2(
    products = paste0(version, "_FCCS"), aoi = build_lcp_aoi(plots, buffer_m = buffer_m),
    email = email, projection = 5070, path = zip_path, max_time = max_time,
    method = "libcurl", verbose = FALSE
  )
  if (!identical(job$status, "Succeeded") || !file.exists(zip_path)) {
    stop("LANDFIRE request did not succeed (status: ", job$status, ").")
  }
  unzip(zip_path, exdir = out_dir)
  tif <- list.files(out_dir, pattern = "tif$", full.names = TRUE, recursive = TRUE)
  if (length(tif) != 1) stop("Expected one GeoTIFF from LANDFIRE, found ", length(tif), ".")

  sample_fccs(terra$rast(tif), plots)
}

#' FCCS code of the raster cell under each plot.
#' @return data.table: site, plot, fccs
sample_fccs <- function(fccs_raster, plots_dt) {
  plots <- as.data.table(plots_dt)
  pts <- terra$vect(as.data.frame(plots), geom = c("Longitude", "Latitude"), crs = "EPSG:4326")
  pts <- terra$project(pts, terra$crs(fccs_raster))
  # thematic layers return category labels by default; take the raw codes
  codes <- terra$extract(fccs_raster, pts, ID = FALSE, raw = TRUE)[, 1]
  data.table(site = plots$site, plot = plots$plot, fccs = as.integer(codes))
}

#' Scale the measured fuel bed depth to a live loading with the FCCS bulk density.
#'
#' @param depths_dt scans with site, plot and MFBDmod (cm), e.g. the wide
#'   extra-models table
#' @param fccs_dt site, plot, fccs (from fetch_landfire_fccs)
#' @return depths_dt joined to its FCCS code and live bulk density, plus
#'   live_load_kgm2 and live_load_tpa
#' @export
scale_fuel_loads <- function(depths_dt, fccs_dt) {
  d <- merge(as.data.table(depths_dt), as.data.table(fccs_dt), by = c("site", "plot"), all.x = TRUE)
  xw <- fccs_bulk_density(d$fccs)[, .(fuelbed_name, height_source, live_bd_kgm3)]
  d <- cbind(d, xw)

  depth_m <- if ("MFBDmod" %in% names(d)) as.numeric(d$MFBDmod) / 100 else NA_real_
  d$live_load_kgm2 <- d$live_bd_kgm3 * depth_m
  d$live_load_tpa <- d$live_load_kgm2 / TPA_TO_KGM2
  d
}
