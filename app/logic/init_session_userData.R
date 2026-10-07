box::use(
  data.table[data.table],
  shiny[reactiveVal],
)

box::use(
  app/logic/manage_data[build_scan_loc_dt],
)

#' Initialize a set of userData that is attached to each session. This data can be accessed by any part of
#' the shiny project. All variables can be accessed by session$userData$<name>. A number of the values are
#' shiny$reactiveVal()'s, so they can be updated and the updates will propagate throughout all shiny modules.
#'
#' @export
init_session_userdata <- function(session) {
  # --------Shared User Data-------------------
  session$userData$all_scans <- reactiveVal(
    build_scan_loc_dt()
  )
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

#' This is initialises additional user data that only exists for the desktop-app. The web-app will never need
#' or utilize this data, and will never call this function.
#' @export
init_desktop_user_data <- function(session) {
  session$userData$data_paths <- reactiveVal(data.table())
}
