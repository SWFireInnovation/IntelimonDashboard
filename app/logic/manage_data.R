box::use(
  dt = data.table,
  stats[setNames],
)

box::use(
  app/logic/constants[COLNAME2LABEL],
  api = app/logic/load_data_api,
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

#' Set the remeasurement value for each scan based on a lazy evaluation of measurement year.
#'
#' Assign each measurement year a number, starting with 0, and label each scan with its corresponding
#' remeasurement number. For example, if the first scan was in 2023, all scans from that year are given a
#' remeasurement number of 0. And if the next year with scans is 2024, all scans in that year are assigned a
#' remeasurement number of 1.
#'
#' @param session - a shiny session object.
#' @export
set_remeas_by_yr <- function(session) {
  selected <- session$userData$scan_selection()

  # rank data by year and assign as remeasurement number
  selected[, Remeasurement := dt$frank(format(date, "%Y"), ties.method = "dense") - 1L]

  session$userData$scan_selection(selected)
}

#' Set the remeasurement values pre and post treatment date.
#'
#' Existing post treatment remeasurement values that are the same as pre treatment remeasurement values are
#' increased. If remeasurment values have not been assigned, pre treatment values are assigned 0 and post
#' treatment values are assigned 1.
#'
#' Results are applied to session$userData$scan_selection() and nothing is returned.
#'
#' @param session - a shiny session object
#' @param trtmt_date -  a date value
#' @export
set_remeas_by_trtmt <- function(session, trtmt_date) {
  # by updating in place, the reactiveVal doesn't notice it's been updated, so a copy is necessary
  selected <- dt$copy(session$userData$scan_selection())

  if (nrow(selected) == 0) {
    return()
  }

  before_t <- selected$date < trtmt_date
  after_t <- selected$date >= trtmt_date

  before_rnum <- unique(selected[before_t, Remeasurement])
  after_rnum <- unique(selected[after_t, Remeasurement])

  # if all pre and post treatment scans already have different remeasurement numbers
  if (!any(after_rnum %in% before_rnum)) {
    return()
    # if pre and post treatment scans have overlapping remeasurement numbers (but are not all NA)
  } else if (any(after_rnum %in% before_rnum) && !is.null(after_rnum)) {
    selected[after_t, Remeasurement := Remeasurement + 1L]
    # if the remeasurement column is empty
  } else if (is.null(after_rnum) && is.null(before_rnum)) {
    selected[before_t, Remeasurement := 0]
    selected[after_t, Remeasurement := 1]
  }

  session$userData$scan_selection(selected)
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
#' @param col_list - a list where data.table column names are the key and the values stored are stylized column
#'        names.
#' @return a list of stylized column names.
#' @export
get_display_col <- function(col_selection, col_list = COLNAME2LABEL) {
  display_col <- col_list[col_selection]
  setNames(names(display_col), display_col)
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
