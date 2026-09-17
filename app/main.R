box::use(
  bslib[bs_theme, navbar_options, page_navbar],
  dt = data.table,
  shiny[NS, includeCSS, moduleServer, reactiveVal, tags],
)

box::use(
  app/logic/dst_state[init_dst_slots],
  view/tab_directOutputs,
  view/tab_forestry,
  view/tab_fuels,
  view/tab_help,
  view/tab_histogram,
  view/tab_load_data,
  view/tab_predictive_models,
  view/tab_rothRmel,
  view/tab_selectionMap,
  view/tab_set_trtmt,
)

# Define UI for application that draws a histogram
#' @export
ui <- function(id) {
  ns <- NS(id)
  page_navbar(
    # Application title
    title = "IntELiMon Dashboard",
    selected = "Selection Map",
    # bslib 0.9.0 consolidated the loose navbar arguments (collapsible, bg,
    # position, underline) into this one argument; passing `collapsible`
    # directly is deprecated.
    navbar_options = navbar_options(collapsible = TRUE),
    theme = bs_theme(),
    # Styles are attached here rather than via app/styles/main.scss:
    # page_navbar builds a complete page and Rhino's separate stylesheet link
    # does not reliably merge into it, so the header slot is the dependable
    # place. app/static/styles.css carries the Aurora Glass theme the Fuels
    # exports and rothRmel cards are built against.
    header = tags$head(includeCSS("app/static/styles.css")),
    if (!file.exists("../data_loc.yaml")) {
      tab_load_data$ui(ns("Load Data"))
    },
    tab_histogram$ui(ns("Histogram")),
    tab_selectionMap$ui(ns("Selection Map")),
    tab_set_trtmt$ui(ns("Set Treatments")),
    tab_directOutputs$ui(ns("Standard-outputs")),
    tab_predictive_models$ui(ns("Predictive-models")),
    # These three build input ids dynamically (renderUI) and address them from
    # JS in conditionalPanel, so they take space-free namespace ids rather
    # than the display-name ids used above.
    tab_fuels$ui(ns("fuels_exports")),
    tab_forestry$ui(ns("forestry_exports")),
    tab_rothRmel$ui(ns("rothrmel")),
    tab_help$ui(ns("Help"))
  )
}

# Define server logic required to draw a histogram
#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # --------Shared User Data-------------------
    # User selected scans for anaylysis
    session$userData$scan_selection <- reactiveVal(
      dt$data.table(
        id = character(),
        site = character(),
        plot = character(),
        date = as.Date(character()),
        scanner_id = integer(),
        scanner_name = character(),
        Longitude = numeric(),
        Latitude = numeric(),
        Agency = character(),
        Unit = character(),
        Remeasurement = integer()
      )
    )

    # IntELiMon metrics for selected scans
    session$userData$metrics <- reactiveVal(dt$data.table())
    # IntELiMon identified tree inventory for scans
    session$userData$tree_inv <- dt$data.table()
    # IntELiMon identified extra models for scans
    session$userData$extra_models <- reactiveVal(dt$data.table())
    # User defined treatment dates
    session$userData$trtmt_dates <- reactiveVal(
      dt$data.table(
        TreatmentDate = as.Date(character())
      )
    )

    # Fuel bed submitted from Fuels exports, and the AOI polygon drawn there.
    # Kept in app/logic/dst_state.R alongside the readers that translate this
    # store into the column naming the ported DST modules expect.
    init_dst_slots(session)

    # -------Tab Servers ------------------------
    data_dir <- tab_load_data$server("Load Data")
    tab_histogram$server("Histogram", data_dir = data_dir)
    tab_selectionMap$server("Selection Map")
    tab_set_trtmt$server("Set Treatments")
    tab_directOutputs$server("Standard-outputs")
    tab_predictive_models$server("Predictive-models")
    tab_fuels$server("fuels_exports")
    tab_forestry$server("forestry_exports")
    tab_rothRmel$server("rothrmel")
  })
}
