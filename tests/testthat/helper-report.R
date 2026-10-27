box::use(
  ggplot2[aes, geom_line, ggplot, labs],
  here[here],
)

box::use(
  app/logic/report,
)

# Shared fixture for the report writer tests: a small report with a figure,
# a statistics table, a rothRmel figure and both Data tables.
sample_report_blocks <- function() {
  p <- ggplot(data.frame(x = 1:5, y = c(3, 4, 2, 5, 6)), aes(x, y)) +
    geom_line() +
    labs(title = "Crown-initiation intensity I\u2080 (kW/m)")
  stats <- data.frame(
    `Time step` = c("2024-01-01", "2024-06-01"), n = c("4", "4"),
    Mean = c("2.00", "2.20"), SD = c("0.40", "\u2014"), check.names = FALSE
  )
  items <- list(
    report$report_item("figure", "Midstory volume", "Standard outputs",
      list(`Plot type` = "Box and Whisker"),
      plot = p
    ),
    report$report_item("table", "Midstory volume", "Standard outputs",
      table = stats, note = "Note."
    ),
    report$report_item("figure", "Crown-initiation intensity I\u2080 (kW/m)", "rothRmel", plot = p),
    report$report_item("image", "Stem map", "Forestry exports", group = "Forestry",
                       image = here("app", "static", "images", "intelimon_logo.png")),
    report$report_item("image", "Missing photo", "Points2Pano", group = "Points2Pano photos")
  )
  analysis <- list(
    summary = "Midstory volume summarizes 4 scans.", cautions = "One time step holds 1 scan.",
    implication = "A decrease points to reduced ladder fuels."
  )
  items[[1]]$analysis <- analysis
  items <- c(
    list(report$section_item("context"), report$section_item("design")),
    list(report$note_item("Results", "Notes on the results.")), items
  )
  context <- list(
    scan = list(
      text = "This report draws on 2 scans at 1 plot.",
      plots = data.frame(Site = "A", Plot = "1", Scans = 2L),
      steps = data.frame(`Time step` = 1:2, Scans = c(1L, 1L), check.names = FALSE)
    ),
    checks = c("Only 1 plot is loaded.", "1 of 1 plot has a single scan.")
  )
  report$report_blocks(
    items, list(title = "Test report", author = "Tester", summary = "Summary text."),
    context = context,
    cover = list(caption = "Cover Photo: USFS, A, plot 1, 2024-01-01, Points2Pano image")
  )
}
