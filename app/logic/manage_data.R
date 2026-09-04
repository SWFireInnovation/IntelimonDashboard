box::use(
  dt = data.table,
)

box::use(
  api = app/logic/load_data_api,
  app/logic/map_fnc,
)

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
