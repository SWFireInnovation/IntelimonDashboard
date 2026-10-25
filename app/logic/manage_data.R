box::use(
  dt = data.table,
  stats[ave, setNames],
)

box::use(
  app/logic/constants[COLNAME2LABEL],
  api = app/logic/load_data_api,
  app/logic/manage_timesteps[scan_groups],
  app/logic/map_fnc,
)

#' Build a data table of IntELiMon scan locations.
#'
#' This function:
#' 1. queries all scan from the api
#' 2. queries all plot locations from api
#' 3. converts coordinates to the standard web reference system and formatting
#' 4. appends agency name for each scan by querying a list of agencies, then a list of scans for each agency,
#'    and merging the table.
#'
#' Final data.table has the columns: site, plot, date, scanner_id, scanner_name, Longitude, Latitude, Agency
#' @export
build_scan_loc_dt <- function() {
  # get list of every scan (uniqueID = site, plot, date)
  # unused columns are (Status, updated_at, and error_message)
  scan_loc_dt <- api$get_all_scans()

  # Replace uneeded columns with desired data name and type
  dt$setnames(
    scan_loc_dt,
    c("site_site", "status", "updated_at", "error_message"),
    c("site", "Longitude", "Latitude", "Agency")
  )
  # empty columns and then assign the correct datatype
  scan_loc_dt[, c("Longitude", "Latitude", "Agency") := NULL]
  scan_loc_dt[, ":="(
    Longitude = NA_real_,
    Latitude = NA_real_,
    Agency = NA_character_,
    date = as.Date(as.character(date), "%Y%m%d")
  )]

  # add location data (lat/long)
  loc_dt <- map_fnc$convert_api_loc2leaflet(api$get_all_plot_loc())
  # unify site column naming
  dt$setnames(loc_dt, c("site_name"), c("site"))
  # assign data by site and plot
  scan_loc_dt[loc_dt,
    `:=`(Longitude = i.Longitude, Latitude = i.Latitude),
    on = .(site, plot)
  ]

  # Add an agency column
  # get a list of all agencies
  agencies_list <- api$get_agencies()$value
  # get a list of all sites for each agency (columns: site, agency)
  agency_site_dt <- api$get_sites_from_agency(agencies_list)
  scan_loc_dt[agency_site_dt,
    `:=`(Agency = i.Agency),
    on = .(site)
  ]

  scan_loc_dt
}

#' Remeasurement number of each scan: the visit to its plot, counted in date
#' order from 0. A plot's first scan is 0, its next scan 1 and so on, however
#' close together the scans are; scans of a plot on the same date share a number.
#'
#' @param scans - data.table with site, plot and date.
#' @return integer vector, one per scan.
#' @export
remeasurement_numbers <- function(scans) {
  if (nrow(scans) == 0) return(integer())
  d <- as.numeric(as.Date(scans$date))
  as.integer(ave(d, scans$site, scans$plot, FUN = function(x) match(x, sort(unique(x))) - 1))
}

#' Number the scan selection: Remeasurement (visits to each plot, from 0) and
#' Scan grouping (time steps from the three rules, see scan_groups()).
#' Replaces any numbers entered by hand. Run when data are fetched.
#'
#' @param session - a shiny session object.
#' @export
set_scan_numbers <- function(session) {
  selected <- dt$copy(session$userData$scan_selection())
  if (nrow(selected) == 0) return()

  groups <- scan_groups(selected, session$userData$trtmt_dates()$TreatmentDate)
  # nolint start: unused_declared_object_linter.
  selected[, Remeasurement := remeasurement_numbers(selected)]
  selected[, ScanGroup := groups]
  # nolint end
  session$userData$scan_selection(selected)
}

#' Regroup the scan selection after the treatment dates change. Only the Scan
#' grouping depends on treatment dates; Remeasurement numbers are kept.
#'
#' @param session - a shiny session object.
#' @export
set_scan_groups <- function(session) {
  # by updating in place, the reactiveVal doesn't notice it's been updated, so a copy is necessary
  selected <- dt$copy(session$userData$scan_selection())
  if (nrow(selected) == 0) return()

  groups <- scan_groups(selected, session$userData$trtmt_dates()$TreatmentDate)
  selected[, ScanGroup := groups] # nolint: unused_declared_object_linter.
  session$userData$scan_selection(selected)
}

#' Columns that identify one scan in the selection and in every downloaded table.
#' @export
SCAN_KEY <- c("site", "plot", "date", "scanner_id")

#' The scans already downloaded (the scan key of the metrics), one row each.
#' @param metrics - session$userData$metrics(), possibly NULL or empty.
#' @export
downloaded_keys <- function(metrics) {
  if (is.null(metrics) || nrow(metrics) == 0 || !all(SCAN_KEY %in% names(metrics))) {
    return(dt$data.table(site = character(), plot = character(), date = as.Date(character()),
                         scanner_id = integer()))
  }
  unique(dt$as.data.table(metrics)[, SCAN_KEY, with = FALSE])
}

#' Keep downloaded scans in a new selection.
#'
#' Downloaded scans stay selected until they are removed on purpose (Clear All
#' Downloads, or Remove selected scans on Set Treatments), so the selection -
#' which carries each scan's unit, remeasurement and scan grouping - always
#' covers the downloaded data. Any downloaded scan of `old_sel` missing from
#' `new_sel` is put back.
#'
#' @param new_sel - data.table, the selection about to be set.
#' @param old_sel - data.table, the current selection.
#' @param metrics - session$userData$metrics().
#' @return list(selection, kept): the selection to set, and the scans put back
#'   (a data.table with the columns of `old_sel`).
#' @export
keep_downloaded <- function(new_sel, old_sel, metrics) {
  dl <- downloaded_keys(metrics)
  if (nrow(dl) == 0 || is.null(old_sel) || nrow(old_sel) == 0) {
    return(list(selection = new_sel, kept = old_sel[0]))
  }
  kept <- old_sel[dl, on = SCAN_KEY, nomatch = 0]
  if (nrow(new_sel) > 0) kept <- kept[!new_sel, on = SCAN_KEY]
  if (nrow(kept) == 0) return(list(selection = new_sel, kept = kept))
  list(selection = rbind(new_sel, kept, use.names = TRUE, fill = TRUE), kept = kept)
}

#' Rows of `tbl` whose scan is not in `keys`. Tables without the scan key are
#' returned unchanged.
#' @export
drop_scans <- function(tbl, keys) {
  if (is.null(tbl) || nrow(tbl) == 0 || nrow(keys) == 0 || !all(SCAN_KEY %in% names(tbl))) {
    return(tbl)
  }
  dt$as.data.table(tbl)[!keys, on = SCAN_KEY]
}

#' Remove scans and their downloaded data from the session: the metrics, tree
#' inventory and model outputs, and the scans themselves from the selection.
#'
#' @param session - a shiny session object.
#' @param keys - data.table with the SCAN_KEY columns of the scans to remove.
#' @return the number of scans removed from the selection.
#' @export
remove_scans <- function(session, keys) {
  keys <- unique(dt$as.data.table(keys)[, SCAN_KEY, with = FALSE])
  selection <- session$userData$scan_selection()
  n <- nrow(selection) - nrow(drop_scans(selection, keys))

  # tree_inv is not reactive: update it before metrics(), whose change makes
  # the tabs re-read it
  session$userData$tree_inv <- drop_scans(session$userData$tree_inv, keys)
  session$userData$extra_models(drop_scans(session$userData$extra_models(), keys))
  session$userData$metrics(drop_scans(session$userData$metrics(), keys))
  session$userData$scan_selection(drop_scans(selection, keys))
  n
}

#' Get a list of new scans that have not been downloaded yet.
#'
#' This function compares the list of downloaded metrics to the list of selected scans and returns any scans
#' that have been selected, but have not yet been downloaded. This information is pulled from
#' session$userData.
#'
#' @param session - a shiny session object
#' @return data.table of new scans for download.
#' @export
get_scans4dwnld <- function(session) {
  selection <- session$userData$scan_selection()
  dwnlded <- session$userData$metrics()

  if (is.null(dwnlded) || nrow(dwnlded) == 0) {
    return(selection)
  }

  selection[!dwnlded, on = .(site, plot, date, scanner_id)]
}

#' Returns a list of stylized column names for display from a list of actual column names.
#'
#' For a list of column names, this function extracts a list of stylized column names for display and returns
#' them as as list.
#'
#' @param col_selection - a list of column names.
#' @param col_list - a list where data.table column names are the key and the values stored are stylized
#'        column names.
#' @return a list of column names, named by their stylized names. A column with no stylized name (e.g. a
#'         site's custom model) is named by itself rather than NA.
#' @export
get_display_col <- function(col_selection, col_list = COLNAME2LABEL) {
  display_col <- unname(col_list[col_selection])
  display_col[is.na(display_col)] <- col_selection[is.na(display_col)]
  setNames(col_selection, display_col)
}

#' Generalize the custom predicitive model names. For example: convert 'Forbsmod_TXARR.rda' to 'Forbsmod'.
#'
#' Custom predictive models are labeled with the R file name that stores the model in the IntELiMon data
#' processing program. The model name is formated <descriptor>_<sitename>.rda. This model name is stored in
#' the data.table recieved through the API. This function strips the file extension and site name from the
#' model name.
#'
#' @param dt - a data.table containing additional models as returned by
#'        app\logic\load_data_api$get_extra_models_for_1scan. Must have columns: site, model_script_name, and
#'        model_metric_value.
#' @export
generalize_model_name <- function(dt) {
  if (nrow(dt) == 0) return(dt)

  # Strip "_{site}.rda" (fall back to just ".rda") from the script name
  dt[, model_name := mapply(
    function(nm, site) sub(paste0("_", site, "\\.rda$"), "", nm),
    model_script_name, site
  )]
  dt[, model_name := sub("\\.rda$", "", model_name)]

  dt[, model_metric_value := suppressWarnings(as.numeric(model_metric_value))]
}

#' Pivot the flat extra_models table (one row per model per scan) into
#' a metrics-like wide table: one row per scan, identifying columns first,
#' then one column per model holding model_metric_value.
#'
#' @param models_dt - data.table containing output from app/logic/load_data_api$get_extra_models_for_scans.
#' @export
pivot_on_model <- function(models_dt, model = NULL) {
  # check for empty data.table
  if (nrow(models_dt) == 0) return(models_dt)

  # select only the desired model
  if (!is.null(model)) {
    models_dt <- models_dt[model_name == model]
    if (nrow(models_dt) == 0) return(models_dt)
  }

  dt$dcast(
    models_dt,
    site + plot + date + scanner_id ~ model_name,
    value.var = "model_metric_value",
    fun.aggregate = mean   # collapses accidental duplicates
  )
}

#' Identify if data must be downloaded through the web api or uploaded from the local disk.
#'
#' This is a simplistic check for missing location, or a novel agency name that is not named in the api.
#'
#' @param data - data.table from session$userData$scan_selection
#' @return boolean list
#' @export
is_data_on_disk <- function(data) {
  api_agencies <- api$get_agencies()$value
  has_api_agency <- data$Agency %in% api_agencies

  no_lat <- is.na(data$Latitude)

  !has_api_agency | no_lat
}

#' Exclude na from summary functions like min/max, while protecting against -Inf.
#'
#' A min or a max of NA returns -Inf. This function returns NA if all values are NA, but otherwise ignores NA.
#'
#' @param x - input data. Any data accepted by the fnc parameter
#' @param fnc - an R function to be applied to X. Must accept parameter na.rm. Min or max expected.
#' @export
safe_summary <- function(x, fnc) {
  if (all(is.na(x))) {
    return(NA_real_)
  }
  fnc(x, na.rm = TRUE)
}
