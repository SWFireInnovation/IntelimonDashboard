box::use(
  data.table[data.table],
  shiny[reactiveVal],
)

init_session_userdata <- function(session) {
  # --------Shared User Data-------------------
  # User selected scans for anaylysis
  session$userData$scan_selection <- reactiveVal(
    data.table(
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
  session$userData$metrics <- reactiveVal(data.table())
  # IntELiMon identified tree inventory for scans
  session$userData$tree_inv <- data.table()
  # IntELiMon identified extra models for scans
  session$userData$extra_models <- reactiveVal(data.table())
  # User defined treatment dates
  session$userData$trtmt_dates <- reactiveVal(
    data.table(
      TreatmentDate = as.Date(character())
    )
  )
  # selected fuel information
  session$userData$fuel_tool_values <- reactiveVal(NULL)
}
