# ---------------------------------------------------------------------------
# The session's report: an ordered list of items (app/logic/report.R) in
# session$userData$report_items, filled by the "+ Report data" buttons on
# cards and arranged on the Report builder tab. Also makes the small previews
# the Report builder shows beside each item.
# ---------------------------------------------------------------------------

box::use(
  grDevices[dev.off, png],
  graphics[par, plot.new, plot.window, rasterImage],
  jsonlite[base64_enc],
  shiny[isolate, showNotification],
)

box::use(
  app/logic/report[add_data_item],
  app/logic/report_cover[image_ratio, read_image],
)

#' Add an item to the session's report (after the figures and tables already
#' there, see `add_data_item()`) and confirm it with a notification.
#' @export
add_to_report <- function(session, item) {
  items <- add_data_item(isolate(session$userData$report_items()), item)
  session$userData$report_items(items)
  kind <- switch(item$kind, figure = "Figure", image = "Figure", "Table")
  showNotification(
    sprintf("%s added to the report (%d item%s): %s", kind, length(items),
            if (length(items) == 1) "" else "s", item$title),
    type = "message", duration = 4
  )
  invisible(items)
}

THUMB_W <- 240
THUMB_H <- 150

# A drawing function rendered to a small PNG, as a data URI for an <img>.
png_uri <- function(draw, width = THUMB_W, height = THUMB_H) {
  file <- tempfile(fileext = ".png")
  png(file, width = width, height = height, res = 48, type = "cairo")
  ok <- tryCatch({
    draw()
    TRUE
  }, error = function(e) FALSE)
  dev.off()
  on.exit(unlink(file))
  if (!ok) return(NULL)
  paste0("data:image/png;base64,", base64_enc(readBin(file, "raw", file.size(file))))
}

#' Preview of a ggplot for the Report builder.
#' @export
plot_thumbnail <- function(plot) png_uri(function() print(plot))

#' Preview of a picture file (PNG or JPEG) for the Report builder.
#' @export
file_thumbnail <- function(path) {
  img <- read_image(path)
  if (is.null(img)) return(NULL)
  height <- round(THUMB_W * image_ratio(img))
  png_uri(function() {
    par(mar = c(0, 0, 0, 0))
    plot.new()
    plot.window(c(0, 1), c(0, 1), xaxs = "i", yaxs = "i")
    rasterImage(img, 0, 0, 1, 1)
  }, height = min(height, 2 * THUMB_H))
}
