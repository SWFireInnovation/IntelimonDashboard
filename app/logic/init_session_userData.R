box::use(
  data.table[data.table],
  shiny[reactiveVal, showNotification],
)

box::use(
  app/logic/load_data_api[API_UNREACHABLE_MSG, is_api_unreachable],
  app/logic/manage_data[build_scan_loc_dt],
  app/logic/report[default_report_items],
)
# The scans in an empty session, with the columns build_scan_loc_dt() returns.
empty_scan_table <- function() {
  data.table(
    site = character(), plot = character(), date = as.Date(character()),
    scanner_id = integer(), scanner_name = character(), Longitude = numeric(),
    Latitude = numeric(), Agency = character()
  )
}

# build_scan_loc_dt(), or an empty table and a message that stays on screen
# when the IntELiMon server can't be reached or returns something unusable.
load_all_scans <- function(session) {
  tryCatch(
    build_scan_loc_dt(),
    error = function(e) {
      msg <- if (is_api_unreachable(e)) {
        API_UNREACHABLE_MSG
      } else {
        paste("The plot list could not be loaded from the IntELiMon server:", conditionMessage(e))
      }
      showNotification(
        paste(msg, "No plots are shown on the Selection Map; reload the page to try again."),
        type = "error", duration = NULL, session = session
      )
      empty_scan_table()
    }
  )
}

#' Initialize a set of userData that is attached to each session. This data can be accessed by any part of
#' the shiny project. All variables can be accessed by session$userData$<name>. A number of the values are
#' shiny$reactiveVal()'s, so they can be updated and the updates will propagate throughout all shiny modules.
#'
#' @export
init_session_userdata <- function(session) {
  # --------Shared User Data-------------------
  # Every scan available for selection, from the IntELiMon API. If the server
  # can't be reached, the session still starts (with no plots on the map)
  # and says so, rather than hanging or ending.
  session$userData$all_scans <- reactiveVal(
    load_all_scans(session)
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
      Remeasurement = integer(),
      ScanGroup = integer()
    )
  )

  # IntELiMon metrics for selected scans
  session$userData$metrics <- reactiveVal(data.table())
  # IntELiMon identified tree inventory for scans
  session$userData$tree_inv <- data.table()
  # IntELiMon identified extra models for scans
  session$userData$extra_models <- reactiveVal(data.table())
  # User defined treatment dates and what was done on each (Set Treatments)
  session$userData$trtmt_dates <- reactiveVal(
    data.table(
      TreatmentDate = as.Date(character()),
      TreatmentType = character()
    )
  )
  # selected fuel information
  session$userData$fuel_tool_values <- reactiveVal(NULL)
  # contact email for external services, set via app/view/email_prompt
  session$userData$user_email <- reactiveVal(NULL)
  # report contents, arranged on the Report builder tab: the standard sections
  # and notes, plus the figures and tables added from cards
  session$userData$report_items <- reactiveVal(default_report_items())
}

#' This is initialises additional user data that only exists for the desktop-app. The web-app will never need
#' or utilize this data, and will never call this function.
#' @export
init_desktop_user_data <- function(session) {
  session$userData$data_paths <- reactiveVal(data.table())
}
