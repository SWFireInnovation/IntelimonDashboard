box::use(
  bslib[bs_theme, page_navbar],
  shiny[NS, moduleServer],
)

box::use(
  view/tab_directOutputs,
  view/tab_forestry,
  view/tab_fuels,
  view/tab_help,
  view/tab_histogram,
  view/tab_load_data,
  view/tab_predictive_models,
  view/tab_raster,
  view/tab_rothRmel,
  view/tab_selectionMap,
)

# Define UI for application that draws a histogram
#' @export
ui <- function(id) {
  ns <- NS(id)
  page_navbar(
    # Application title
    title = "IntELiMon Dashboard",
    selected = "Selection Map",
    collapsible = TRUE,
    theme = bs_theme(),
    if (!file.exists("../data_loc.yaml")) {
      tab_load_data$ui(ns("Load Data"))
    },
    tab_histogram$ui(ns("Histogram")),
    tab_selectionMap$ui(ns("Selection Map")),
    tab_directOutputs$ui(ns("Direct outputs")),
    tab_predictive_models$ui(ns("Predictive models")),
    tab_raster$ui(ns("Raster products")),
    tab_fuels$ui(ns("Fuels exports")),
    tab_forestry$ui(ns("Forestry exports")),
    tab_rothRmel$ui(ns("rothRmel")),
    tab_help$ui(ns("Help"))
  )
}

# Define server logic required to draw a histogram
#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    data_dir <- tab_load_data$server("Load Data")
    tab_histogram$server("Histogram", data_dir = data_dir)
    tab_selectionMap$server("Selection Map")
  })
}
