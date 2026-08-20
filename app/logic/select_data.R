box::use(
  dt = data.table,
)

box::use(
  api = app/logic/load_data_api,
  app/logic/map_fnc
)

#' @export
build_scan_loc_dt <- function() {
  # get list of every scan (uniqueID = site, plot, date)
  # this is
  scan_loc_dt <- api$get_all_scans()

  # Replace uneeded columns with desired data name and type
  dt$setnames(scan_loc_dt,
              c('site_site', 'status', 'updated_at', 'error_message'),
              c('site', 'Longitude', 'Latitude', 'Agency')
  )
  # empty columns and then assign the correct datatype
  scan_loc_dt[, c("Longitude", "Latitude", "Agency") := NULL]
  scan_loc_dt[, ':='(
    Longitude = NA_real_,
    Latitude = NA_real_,
    Agency = NA_character_,
    date = as.Date(as.character(date), '%Y%m%d')
  )]

  # add location data (lat/long)
  loc_dt <- map_fnc$convert_api_loc2leaflet(api$get_all_plot_loc())
  # unify site column naming
  dt$setnames(loc_dt, c('site_name'), c('site'))
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