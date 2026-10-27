box::use(
  shiny,
)

# Choices for the plot controls, label = value. Exported so the report builder
# can record a card's settings by their on-screen labels.
#' @export
PLOT_TYPES <- list(
  "Time series" = "timeseries",
  "Time series individual plot" = "individual",
  "Box and Whisker" = "boxplot",
  "Bar" = "bar"
)

#' @export
DATA_TYPES <- list("Values" = "raw", "Percent change" = "percent")

#' @export
ERROR_BARS <- list("SD" = "sd", "SE" = "se", "Off" = "off")

#' On-screen label for a control value, e.g. choice_label(PLOT_TYPES, "bar").
#' @export
choice_label <- function(choices, value) {
  hit <- names(choices)[unlist(choices) == value]
  if (length(hit) == 0) value else hit[[1]]
}

#' @export
standard_plt_ctrls <- function(ns) {
  shiny$tagList(
    shiny$selectInput(ns("ui_select_plot_type"),
      "Plot type",
      choices = PLOT_TYPES,
      selected = "timeseries", width = "100%"
    ),
    shiny$selectInput(ns("ui_select_data_type"),
      "Data type",
      choices = DATA_TYPES,
      selected = "raw",
      width = "100%"
    ),
    shiny$radioButtons(ns("ui_btn_show_treatments"),
      "Treatment date lines",
      choices = list("On" = "on", "Off" = "off"),
      selected = "on",
      inline = TRUE,
      width = "100%"
    ),
    # SD: spread of the plots in a time step; SE (SD / sqrt(n)): precision of its mean
    shiny$radioButtons(ns("ui_btn_show_errorbars"),
      "Error bars",
      choices = ERROR_BARS,
      selected = "sd",
      inline = TRUE,
      width = "100%"
    )
  )
}
