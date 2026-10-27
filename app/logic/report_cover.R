# ---------------------------------------------------------------------------
# Cover photo for the report builder: the front view of the first selected
# scan's Points2Pano panorama, shown on the title page. The image is downloaded when the
# report is built (in the build worker); when it can't be fetched the title
# page shows a placeholder instead, so a network problem never stops a build.
# ---------------------------------------------------------------------------

box::use(
  httr2,
  jpeg[readJPEG, writeJPEG],
  png[readPNG],
  tools[file_ext],
)

box::use(
  app/logic/report_map[render_plot_map],
)

#' Points2Pano cube-map tiles, as used by the viewer
#' (build_points2pano_url_sdsc() in app/logic/load_data_api.R): an sprintf()
#' template filled with site, site, plot, scan date (YYYYMMDD), scanner id,
#' cube face, zoom level, tile row and tile column.
#' @export
P2P_TILES <- paste0(
  "https://burnpro3d.sdsc.edu/points2pano/d/tiles/",
  "%s/%s_%s_%s_%s_%s/%d/%d/%d.jpg"
)

#' URL of one Points2Pano tile. Level 0 holds each cube face as a single
#' 512 px tile, so face "f" at level 0 is a quick preview of the front view.
#' @export
p2p_tile_url <- function(site, plot, date, scanner = 1, face = "f", level = 0, y = 0, x = 0,
                         tiles = P2P_TILES) {
  if (length(scanner) != 1 || is.na(scanner)) scanner <- 1
  sprintf(tiles, site, site, plot, format(as.Date(date), "%Y%m%d"), scanner, face, level, y, x)
}

# Zoom level 1 holds each cube face as 2 x 2 tiles of 512 px (1024 px a face).
# The sharper level 2 shows the point-cloud colouring as visible dots on thin
# stems; level 1 still prints at about 160 dpi across the page.
TILE <- 512L
LEVEL <- 1L
PER_FACE <- 2L
# The front cube face is a plain 90-degree perspective view, like a camera
# photo; it is cropped to a 4:3 landscape frame around the horizon.
FACE <- "f"
ASPECT <- 3 / 4

#' Download the cover image for one scan into `dir`: the front face of its
#' Points2Pano panorama, cropped to 4:3, as a JPEG. Returns the file path, or
#' NULL when any tile can't be fetched.
#' @export
fetch_cover_image <- function(site, plot, date, scanner = 1, dir = tempdir(),
                              tiles = P2P_TILES) {
  if (is.null(tiles)) return(NULL)
  if (length(scanner) != 1 || is.na(scanner)) scanner <- 1
  stamp <- format(as.Date(date), "%Y%m%d")
  side <- TILE * PER_FACE
  tryCatch({
    face <- array(0, c(side, side, 3))
    for (y in seq_len(PER_FACE) - 1L) {
      for (x in seq_len(PER_FACE) - 1L) {
        url <- p2p_tile_url(site, plot, date, scanner, FACE, LEVEL, y, x, tiles)
        resp <- httr2$req_perform(httr2$req_timeout(httr2$request(url), 20))
        tile <- readJPEG(httr2$resp_body_raw(resp))
        face[y * TILE + seq_len(TILE), x * TILE + seq_len(TILE), ] <- tile[, , 1:3]
      }
    }
    height <- round(side * ASPECT)
    top <- (side - height) %/% 2
    path <- file.path(dir, paste0("cover_", site, "_", plot, "_", stamp, ".jpg"))
    writeJPEG(face[top + seq_len(height), , ], path, quality = 0.9)
    path
  }, error = function(e) NULL)
}

#' Read a PNG or JPEG into a raster array; NULL for anything else or a file
#' that can't be read.
#' @export
read_image <- function(path) {
  if (is.null(path) || !file.exists(path)) return(NULL)
  tryCatch(
    switch(tolower(file_ext(path)),
      png = readPNG(path),
      jpg = ,
      jpeg = readJPEG(path),
      NULL
    ),
    error = function(e) NULL
  )
}

#' Height-to-width ratio of an image array (for sizing it on the page).
#' @export
image_ratio <- function(img) dim(img)[1] / dim(img)[2]

#' Fetch the cover image (if any) and put its path on the report's title page
#' block. Run in the build worker so the download never blocks the session.
#' @export
attach_cover_image <- function(blocks, cover, tiles = P2P_TILES) {
  if (is.null(cover$site)) return(blocks)
  path <- fetch_cover_image(cover$site, cover$plot, cover$date, cover$scanner, tiles = tiles)
  if (is.null(path)) return(blocks)
  i <- which(vapply(blocks, function(b) b$type == "title_page", logical(1)))
  if (length(i) == 1) blocks[[i]]$image <- path
  blocks
}

#' Fetch or draw every picture the report needs before it is written: the
#' cover photo, Points2Pano photos added from the cards and the plot locations
#' map. Run in the build worker. A picture that can't be made keeps a NULL
#' path, and the writers print a placeholder.
#' @export
prepare_images <- function(blocks, cover, dir = tempdir()) {
  blocks <- attach_cover_image(blocks, cover)
  for (i in seq_along(blocks)) {
    b <- blocks[[i]]
    if (!identical(b$type, "image") || !is.null(b$path)) next
    if (!is.null(b$photo)) {
      ph <- b$photo
      blocks[[i]]$path <- fetch_cover_image(ph$site, ph$plot, ph$date, ph$scanner, dir = dir)
    } else if (!is.null(b$map)) {
      blocks[[i]]$path <- tryCatch(
        as.character(render_plot_map(b$map, tempfile("map_", dir, ".png"))),
        error = function(e) NULL
      )
    }
  }
  blocks
}
