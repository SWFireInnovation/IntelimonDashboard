box::use(
  sf,
  tidyr,
)

#' @export
extract_lat_long_from_api <- function(plot_dt,
                                      location_col = "location",
                                      output_col = c("Longitude", "Latitude")) {
  plot_dt[, (location_col) := gsub("[POINT()]", "", get(location_col))]
  plot_dt <- tidyr$separate(plot_dt, col = location_col, into = output_col, sep = " ")
  plot_dt
}

#' @export
set_crs <- function(plot_dt,
                    coord_col = c("Longitude", "Latitude"),
                    imon_crs = 3857) {
  sf$st_as_sf(plot_dt,
    coords = coord_col,
    crs = imon_crs
  )
}

#' @export
convert_crs <- function(pts,
                        target_crs = 4326) {
  # Transform to WGS84 (EPSG:4326)
  sf$st_transform(pts, target_crs)
}

#' @export
convert_api_loc2leaflet <- function(plot_dt,
                                    location_col = "location",
                                    api_crs = 3857,
                                    leaflet_crs = 4326) {
  # convert POINT(-9078227.3364 3934562.5600000024) into lat long
  plot_dt <- extract_lat_long_from_api(plot_dt, location_col, output_col = c("Longitude", "Latitude"))

  plots_crs_api <- set_crs(plot_dt, imon_crs = api_crs, coord_col = c("Longitude", "Latitude"))

  plots_crs_leaflet <- convert_crs(plots_crs_api, leaflet_crs)

  # Extract coordinates back into data table
  coords_dt <- sf$st_coordinates(plots_crs_leaflet)

  # assign coordinates to data table
  plot_dt$Longitude <- coords_dt[, 1]
  plot_dt$Latitude <- coords_dt[, 2]

  plot_dt
}
