box::use(
  leaflet,
  shiny[observeEvent, req],
)

box::use(
  app/logic/map_fnc[get_metric_loc, get_plots_in_view],
)

#' Add labels to mapped points based on zoom level and bounding box. This function uses a shiny$observeEvent()
#'
#' Function modifies the proxy map passed to it and does not return anything.
#'
#' @param input - shiny ui input object for a leaflet.
#' @param proxy_map - a leaflet$leafletProxy object for a rendered map
#' @param pts - a data.table containing coordinate information
#' @param mapID - a str identifying the map namespace ID i.e. output$map1 <- renderLeaflet() has a mapID of 1.
#' @param col_names - a named list identifying column names for lattitude, longitude and labels.
#' @export
update_point_labels <- function(input,
                                proxy_map,
                                pts,
                                map_id = "map",
                                col_names = list(lat = "Latitude", lng = "Longitude", label = "plots")) {
  zoom_name <- paste0(map_id, "_zoom")
  bounds_name <- paste0(map_id, "_bounds")

  observeEvent(
    {
      input[[zoom_name]]
      input[[bounds_name]]
    },
    {
      req(input[[zoom_name]])
      req(input[[bounds_name]])

      min_zoom_label <- 11
      max_plots <- 80

      # immediately exit if zoomed out
      if (input[[zoom_name]] < min_zoom_label) {
        proxy_map |>
          leaflet$clearGroup("plot-labels")
        return()
      }

      # Filter to minimum labels
      # if zoomed in, filter plots to current extent.
      plt_mark <- get_plots_in_view(pts, input[[bounds_name]])

      nplts <- nrow(plt_mark)
      # if there are too many plots in the current view, clear labels and return
      if (nplts > max_plots || nplts == 0) {
        proxy_map |>
          leaflet$clearGroup("plot-labels")
        return()
      }

      proxy_map |>
        leaflet$clearGroup("plot-labels") |>
        leaflet$addLabelOnlyMarkers(
          data = plt_mark,
          lng = plt_mark[[col_names$lng]],
          lat = plt_mark[[col_names$lat]],
          label = plt_mark[[col_names$label]],
          group = "plot-labels",
          labelOptions = leaflet$labelOptions(
            noHide = TRUE,
            textOnly = TRUE,
            className = "plot-label"
          )
        )
    }
  )
}

#' Map a data.table of selected or downloaded scan points to a leaflet$leafletProxy
#'
#' Function modifies the proxy map passed to it and does not return anything.
#'
#' @param proxy_map - a leaflet$leafletProxy object for a rendered map
#' @param pts - a data.table containing coordinate information
#' @param col_names - a named list identifying column names for lattitude, longitude and labels.
#' @param color - color of mapped markers. Can be single string (e.g. 'red') or a color palete with column
#'        column name (e.g. ~color_palette(Agency) where color_palette <- leaflet$colorFactor())
#' @param lgnd_colors - if NULL, legend is assigned a single color (color as string above). If color is a
#'        color palette with levels, a list of each color must be provided
#'        (e.g. color_palette(unique(df$Agency)))
#' @param lgnd_labels - if NULL, grp is used for all colors. If a color palette is used, supply a list
#'        (e.g. unique(df$Agency))
#' @param lyr_id - ID for each point. e.g. ~paste(site, plot, sep = "-"). Used when a point is clicked on.
#' @param grp - string. group name of markers
#' @param clickble - boolean. TRUE if point can be selected on map.
#' @export
map_scan_points <- function(proxy_map,
                            pts,
                            col_names = list(lat = "Latitude", lng = "Longitude"),
                            color = "blue",
                            lgnd_colors = NULL,
                            lgnd_labels = NULL,
                            lyr_id = NULL,
                            grp = "all_clicks",
                            clickble = FALSE) {

  if (is.null(lgnd_colors)) {
    lgnd_colors <- color
  }
  if (is.null(lgnd_labels)) {
    lgnd_labels <- grp
  }

  proxy_map |>
    leaflet$clearGroup(grp) |>
    leaflet$removeControl(paste0(grp, "_legend")) |>
    leaflet$addCircleMarkers(
      layerId = lyr_id,
      group = grp,
      data = pts,
      # make sure that you can still click on filtered plots to deselect
      options = leaflet$pathOptions(clickable = clickble),
      lng = pts[[col_names$lng]],
      lat = pts[[col_names$lat]],
      color = color,
      radius = 2
    ) |>
    leaflet$addLegend(
      layerId = paste0(grp, "_legend"),
      data = pts,
      position = "bottomleft",
      colors = lgnd_colors,
      labels = lgnd_labels,
      opacity = 0.6
    )
}

#' Add selected scans to a leaflet$leafletProxy. This function uses a shiny$observeEvent() based on changes
#' to selected scans
#'
#' Function modifies the proxy map passed to it and does not return anything.
#'
#' @param session - shiny session
#' @param proxy_map - a leaflet$leafletProxy object for a rendered map
#' @param col_names - a named list identifying column names for lattitude, longitude and labels.
#' @param lyr_id - ID for each point. e.g. ~paste(site, plot, sep = "-"). Used when a point is clicked on.
#' @export
update_selected_scan_points <- function(session,
                                        proxy_map,
                                        col_names = list(lat = "Latitude", lng = "Longitude"),
                                        lyrid = ~paste(site, plot, sep = "-")) {
  observeEvent(session$userData$scan_selection(), {
    mark <- session$userData$scan_selection()
    req(mark)
    # can be changed by `filtered_plots()` or by `input$map_marker_click`
    map_scan_points(proxy_map, mark, col_names, color = "gold", grp = "Selected", clickble = FALSE,
                    lyr_id = lyrid)
  })
}

#' Add downloaded scans to a leaflet$leafletProxy. This function uses a shiny$observeEvent() based on changes
#' to downloaded metrics.
#'
#' Function modifies the proxy map passed to it and does not return anything.
#'
#' @inheritParam update_selected_scan_points
#' @export
update_dwnld_scan_points <- function(session,
                                     proxy_map,
                                     col_names = list(lat = "Latitude", lng = "Longitude"),
                                     lyrid = ~paste(site, plot, sep = "-")) {
  observeEvent(
    {
      # if only metrics is monitored, then new selected scans cause all metrics to be overwritten
      session$userData$metrics()
      session$userData$scan_selection()
    },
    {
      metrics <- session$userData$metrics()
      scans <- session$userData$scan_selection()

      if (is.null(metrics) || nrow(metrics) == 0) {
        return()
      }

      loc <- get_metric_loc(metrics, scans)

      # can be changed by `filtered_plots()` or by `input$map_marker_click`
      map_scan_points(proxy_map, loc, col_names, color = "blue", grp = "Downloaded",
                      lyr_id = lyrid, clickble = FALSE)
    }
  )
}

#' Adjust map extent of leaflet$leafletProxy. This function uses a shiny$observeEvent() based on changes
#' to fit2pts.
#'
#' @param proxy_map - a leaflet$leafletProxy object for a rendered map
#' @param fit2pts - a reactive containing a data.table with 2 columns containing EPSG 3857 formatted location
#'        data (used to set map extent). Pass the reactive object, not the current value (no parenthases)
#' @param col_names - a list defining column names of lat and lng location data
#' @export
update_extent <- function(proxy_map, fit2pts, col_names = list(lat = "Latitude", lng = "Longitude")) {

  observeEvent(fit2pts(),
               {
                 pts <- fit2pts()
                 if (nrow(pts) == 0) {
                   return()
                 }

                 proxy_map |>
                   leaflet$fitBounds(
                     lng1 = min(pts[[col_names$lng]]), lat1 = min(pts[[col_names$lat]]),
                     lng2 = max(pts[[col_names$lng]]), lat2 = max(pts[[col_names$lat]]),
                     options = list(padding = c(15, 15))
                   )
               })
}
