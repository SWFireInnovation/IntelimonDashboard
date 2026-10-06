# app/logic/lcp_format.R
# ---------------------------------------------------------------------------
# Binary FARSITE/FlamMap landscape (.LCP) writer, in plain R.
#
# GDAL's LCP driver crashes ("double free or corruption") on any negative
# value before GDAL 3.6.4 (OSGeo/gdal#7561), and LCPs always contain some:
# LANDFIRE marks flat cells with aspect -1. Writing the file here keeps the
# export independent of the GDAL version on the machine.
#
# Layout (little-endian), following GDAL's frmts/raw/lcpdataset.cpp:
#      0  int32   crown fuels flag (21 = present) / ground fuels flag (20 = none)
#      8  int32   latitude (whole degrees)
#     12  double  max x, min x, max y, min y
#     44  per band (x8): int32 min, int32 max, int32 number of distinct
#                  values (-1 if 100 or more), int32[100] a leading 0 then
#                  the sorted distinct values (-9999 excluded)
#   3340  zeros (space for bands 9-10, ground fuels)
#   4164  int32 columns, int32 rows, double max x, min x, max y, min y,
#         int32 linear unit (0 = meters), double x res, double y res
#   4224  int16[10] unit codes (elevation m, slope deg, aspect azimuth deg,
#         fuel model option: 0 = standard models only, 1 = custom models with
#         no conversion file; cover %, heights m x 10, CBD kg/m^3 x 100)
#   4244  char[256] x 10 source file names (left empty)
#   6804  char[512] description
#   7316  int16 cells, row by row from the north edge, all bands per cell
#
# GDAL >= 3.6.4 writes the distinct-value lists offset by +32768; this writer
# stores the values themselves, as the format intends.
# ---------------------------------------------------------------------------
box::use(
  sf[st_crs, st_point, st_sf, st_sfc, st_write],
)

LCP_HEADER_BYTES <- 7316
LCP_MAX_CLASSES <- 100
LCP_NODATA <- -9999L

# unit / option codes for the 10 band slots (see header comment)
LCP_UNIT_CODES <- c(0L, 0L, 2L, 0L, 1L, 3L, 3L, 3L, 1L, 0L)

#' Header block for one band: min, max, distinct-value count and list.
band_classes <- function(values) {
  found <- sort(unique(values[values != LCP_NODATA]))
  classes <- integer(LCP_MAX_CLASSES)
  if (length(found) >= LCP_MAX_CLASSES) {
    n_found <- -1L
  } else {
    n_found <- length(found)
    classes[seq_along(found) + 1] <- found
  }
  c(min(values), max(values), n_found, classes)
}

#' Write an 8-band landscape to a binary .LCP.
#'
#' @param values integer matrix, one row per cell (row-major from the north-
#'   west corner, as terra orders cells) and one column per LCP band
#' @param ncol,nrow grid size
#' @param extent c(xmin, xmax, ymin, ymax) in the projection's units (meters)
#' @param resolution c(x, y) cell size
#' @param latitude whole-degree latitude of the landscape
#' @param description free text stored in the header
#' @param custom_fuels TRUE when the fuel band holds custom fuel model numbers
#'   (defined in an accompanying .fmd file)
#' @return path
#' @export
write_lcp_binary <- function(path, values, ncol, nrow, extent, resolution, latitude,
                             description = "LCP file created by IntELiMon.",
                             custom_fuels = FALSE) {
  if (ncol(values) != 8) stop("An LCP needs 8 bands; got ", ncol(values), ".")
  if (nrow(values) != ncol * nrow) stop("values has ", nrow(values), " cells; expected ", ncol * nrow, ".")
  if (anyNA(values)) stop("LCP values cannot contain NA; fill them first.")
  if (any(values < -32768 | values > 32767)) stop("LCP values must fit in 16-bit integers.")
  storage.mode(values) <- "integer"

  con <- file(path, "wb")
  on.exit(close(con))
  int32 <- function(x) writeBin(as.integer(x), con, size = 4, endian = "little")
  dbl <- function(x) writeBin(as.double(x), con, size = 8, endian = "little")
  pad_to <- function(offset) {
    at <- seek(con, where = NA, rw = "write")
    if (at > offset) stop("LCP header overran byte ", offset, " (at ", at, ").")
    writeBin(raw(offset - at), con)
  }
  bounds <- c(extent[[2]], extent[[1]], extent[[4]], extent[[3]]) # max x, min x, max y, min y

  int32(c(21L, 20L, latitude))
  dbl(bounds)
  for (i in seq_len(8)) int32(band_classes(values[, i]))
  pad_to(4164)
  int32(c(ncol, nrow))
  dbl(bounds)
  int32(0L) # linear unit: meters
  dbl(abs(resolution))
  unit_codes <- LCP_UNIT_CODES
  if (custom_fuels) unit_codes[4] <- 1L
  writeBin(unit_codes, con, size = 2, endian = "little")
  pad_to(6804)
  writeBin(charToRaw(substr(description, 1, 511)), con)
  pad_to(LCP_HEADER_BYTES)

  # all bands of a cell together, cells row by row
  writeBin(as.vector(t(values)), con, size = 2, endian = "little")
  path
}

#' Write the ESRI-style .prj that FlamMap reads next to an .LCP.
#'
#' GDAL's shapefile writer produces the same ESRI WKT1 text the LCP driver
#' used, without going through the LCP driver.
#' @param crs any CRS sf understands (e.g. WKT from terra::crs())
#' @export
write_esri_prj <- function(crs, prj_path) {
  shp <- tempfile(fileext = ".shp")
  on.exit(unlink(sub("\\.shp$", ".*", shp)), add = TRUE)
  st_write(st_sf(geometry = st_sfc(st_point(c(0, 0)), crs = st_crs(crs))), shp, quiet = TRUE)
  file.copy(sub("\\.shp$", ".prj", shp), prj_path, overwrite = TRUE)
  prj_path
}
