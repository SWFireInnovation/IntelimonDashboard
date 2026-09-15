box::use(
  shiny
)

standard_plt_ctrls <- function(ns) {
  shiny$tagList(
    shiny$selectInput(ns("ui_select_plot_type"),
                      "Plot type",
                      choices = list(
                        "Time series" = "timeseries",
                        "Time series individual plot" = "individual",
                        "Box and Whisker" = "boxplot",
                        "Bar" = "bar"
                      ),
                      selected = "timeseries", width = "100%"
    ),
    shiny$selectInput(ns("ui_select_data_type"),
                      "Data type",
                      choices = list("Values" = "raw", "Percent change" = "percent"),
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
    shiny$radioButtons(ns("ui_btn_show_errorbars"),
                       "Error bars",
                       choices = list("On" = "on", "Off" = "off"),
                       selected = "on",
                       inline = TRUE,
                       width = "100%"
    )
  )
}