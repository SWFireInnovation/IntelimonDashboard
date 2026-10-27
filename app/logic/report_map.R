# ---------------------------------------------------------------------------
# Plot locations map for the report builder: the selected plots drawn over
# Esri World Imagery (the app's satellite basemap), zoomed to their extent.
# Rendered to a PNG when the report is built (in the build worker). The zoom
# is capped and the extent has a minimum size, so a single plot still shows
# its surroundings instead of zooming past the deepest imagery. Without a
# network the points are drawn on a plain background.
# ---------------------------------------------------------------------------

box::use(
  grDevices[dev.off, png],
  graphics[par, plot.new, plot.window, points, rasterImage, rect, text],
  httr2,
  jpeg[readJPEG],
)

#' Esri World Imagery tiles: sprintf() template filled with zoom, row, column.
#' @export
ESRI_TILES <- paste0(
  "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/",
  "%d/%d/%d"
)

TILE_PX <- 256
MAX_ZOOM <- 17
# smallest extent shown, in degrees of latitude (about 600 m)
MIN_SPAN <- 0.0055
MAP_W <- 1500
MAP_H <- 1000
# narrowest window, so a map placed at full page width stays sharp enough
MIN_W <- 900

# Web Mercator: degrees to global pixel coordinates at zoom z.
lon_px <- function(lon, z) (lon + 180) / 360 * TILE_PX * 2^z
lat_px <- function(lat, z) {
  r <- lat * pi / 180
  (1 - log(tan(r) + 1 / cos(r)) / pi) / 2 * TILE_PX * 2^z
}

#' The map window for a set of points: the deepest zoom (up to MAX_ZOOM) at
#' which the padded extent, at least MIN_SPAN across, fits MAP_W x MAP_H, and
#' the window cropped to that extent at a 3:2 aspect (at least MIN_W wide), so
#' the plots fill the map rather than sitting in the middle of a wider view.
#' @export
map_window <- function(lon, lat, width = MAP_W, height = MAP_H) {
  half <- max(diff(range(lat)), diff(range(lon)) * cos(mean(lat) * pi / 180), MIN_SPAN) * 0.6
  clat <- mean(range(lat))
  clon <- mean(range(lon))
  dlon <- half / cos(clat * pi / 180)
  for (z in MAX_ZOOM:1) {
    x <- lon_px(c(clon - dlon, clon + dlon), z)
    y <- lat_px(c(clat + half, clat - half), z)
    if (diff(x) <= width && diff(y) <= height) break
  }
  w <- max(diff(x), diff(y) * width / height, MIN_W)
  h <- w * height / width
  w <- round(w)
  h <- round(h)
  list(z = z, x0 = lon_px(clon, z) - w / 2, y0 = lat_px(clat, z) - h / 2, width = w, height = h)
}

# Stitch the imagery for a window; NULL when any tile can't be fetched.
basemap <- function(win, tiles) {
  if (is.null(tiles)) return(NULL)
  tx <- floor(win$x0 / TILE_PX):floor((win$x0 + win$width - 1) / TILE_PX)
  ty <- floor(win$y0 / TILE_PX):floor((win$y0 + win$height - 1) / TILE_PX)
  tryCatch({
    img <- array(0, c(length(ty) * TILE_PX, length(tx) * TILE_PX, 3))
    for (i in seq_along(ty)) {
      for (j in seq_along(tx)) {
        url <- sprintf(tiles, win$z, ty[i], tx[j])
        resp <- httr2$req_perform(httr2$req_timeout(httr2$request(url), 20))
        tile <- readJPEG(httr2$resp_body_raw(resp))
        img[(i - 1) * TILE_PX + seq_len(TILE_PX), (j - 1) * TILE_PX + seq_len(TILE_PX), ] <-
          tile[, , 1:3]
      }
    }
    # crop the stitched tiles to the window
    r0 <- round(win$y0 - ty[1] * TILE_PX)
    c0 <- round(win$x0 - tx[1] * TILE_PX)
    img[r0 + seq_len(win$height), c0 + seq_len(win$width), , drop = FALSE]
  }, error = function(e) NULL)
}

#' Draw the plots over the imagery and write a PNG.
#' @param points data.frame with site, plot, lon, lat.
#' @param path PNG file to write.
#' @return `path`, invisibly, with attribute "basemap" TRUE when imagery was drawn.
#' @export
render_plot_map <- function(points, path, tiles = ESRI_TILES) {
  points <- points[is.finite(points$lon) & is.finite(points$lat), , drop = FALSE]
  win <- map_window(points$lon, points$lat)
  img <- basemap(win, tiles)
  px <- lon_px(points$lon, win$z) - win$x0
  py <- win$height - (lat_px(points$lat, win$z) - win$y0)
  one_site <- length(unique(points$site)) == 1
  labels <- if (one_site) points$plot else paste(points$site, points$plot)

  png(path, width = win$width, height = win$height, res = 150)
  on.exit(dev.off())
  par(mar = c(0, 0, 0, 0), xaxs = "i", yaxs = "i")
  plot.new()
  plot.window(c(0, win$width), c(0, win$height))
  if (is.null(img)) {
    rect(0, 0, win$width, win$height, col = "#e9eef2", border = NA)
  } else {
    rasterImage(img, 0, 0, win$width, win$height)
  }
  points(px, py, pch = 21, bg = "#f59f00", col = "white", cex = 2.4, lwd = 2)
  # labels with a dark halo so they read on any imagery
  for (d in list(c(-1, 0), c(1, 0), c(0, -1), c(0, 1))) {
    text(px + d[1] * 2 + 22, py + d[2] * 2, labels, adj = c(0, 0.5), col = "#000000aa",
         cex = 0.9)
  }
  text(px + 22, py, labels, adj = c(0, 0.5), col = "white", cex = 0.9, font = 2)
  credit <- if (is.null(img)) "Basemap unavailable" else "Imagery: Esri World Imagery"
  text(win$width - 8, 8, credit, adj = c(1, 0), col = if (is.null(img)) "#495057" else "white",
       cex = 0.6)
  invisible(structure(path, basemap = !is.null(img)))
}
