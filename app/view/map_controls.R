box::use(
  leaflet,
  shiny[observeEvent, reactiveVal, req],
)

box::use(
  app/logic/manage_data[safe_summary],
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
                                pts_reactive,
                                map_id = "map",
                                col_names = list(lat = "Latitude", lng = "Longitude", label = "plots")) {
  zoom_name <- paste0(map_id, "_zoom")
  bounds_name <- paste0(map_id, "_bounds")

  observeEvent(
    {
      input[[zoom_name]]
      input[[bounds_name]]
      pts_reactive()
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

      pts <- pts_reactive()
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
            offset = c(8, -2),
            noHide = TRUE,
            textOnly = TRUE,
            className = "plot-label",
            style = list("font-weight" = "bold")
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
#' @param grp - string. group name of markers.
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
      # black ring (stroke) around an opaque fill so markers stand out on any basemap
      color = "black",
      weight = 1,
      opacity = 1,
      fillColor = color,
      fillOpacity = 1,
      radius = 4
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
                                        lyrid = ~paste(site, plot, "selected", sep = "-")) {
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
                                     lyrid = ~paste(site, plot, "dwnld", sep = "-")) {
  observeEvent(
    {
      session$userData$metrics()
      session$userData$all_scans()
    },
    {
      metrics <- session$userData$metrics()

      # nothing downloaded (or all downloads removed): clear the blue markers
      if (is.null(metrics) || nrow(metrics) == 0) {
        proxy_map |>
          leaflet$clearGroup("Downloaded") |>
          leaflet$removeControl("Downloaded_legend")
        return()
      }

      # locations come from every known scan, not the selection, so downloaded
      # scans stay on the map when they are deselected or the selection is cleared
      loc <- get_metric_loc(metrics, session$userData$all_scans())

      # can be changed by `filtered_plots()` or by `input$map_marker_click`
      map_scan_points(proxy_map, loc, col_names, color = "blue", grp = "Downloaded",
                      lyr_id = lyrid, clickble = FALSE)
    }
  )
}

#' Deepest zoom the maps fit to: Esri World Imagery has no tiles past about
#' level 18 in many areas, and fitting to one plot would otherwise go to 20.
#' @export
MAX_FIT_ZOOM <- 17

#' Adjust map extent of leaflet$leafletProxy. This function uses a shiny$observeEvent() based on changes
#' to fit2pts.
#'
#' The map is only fitted when the extent of fit2pts differs from the last fit, so a refresh of
#' fit2pts that leaves the points as they were (e.g. the table being shown) does not undo the user's
#' panning and zooming.
#'
#' @param proxy_map - a leaflet$leafletProxy object for a rendered map
#' @param fit2pts - a reactive containing a data.table with 2 columns containing EPSG 3857 formatted location
#'        data (used to set map extent). Pass the reactive object, not the current value (no parenthases)
#' @param col_names - a list defining column names of lat and lng location data
#' @param visible - a reactive, TRUE while the map is on screen. Fitting a hidden map (it has no
#'        size) leaves it shrunk in a corner, so a fit requested while it is hidden waits until
#'        it is shown.
#' @export
update_extent <- function(proxy_map, fit2pts, col_names = list(lat = "Latitude", lng = "Longitude"),
                          visible = function() TRUE) {
  last_fit <- reactiveVal(NULL)
  fit_pending <- reactiveVal(FALSE)

  pts_extent <- function() {
    pts <- fit2pts()
    if (nrow(pts) == 0) {
      return(NULL)
    }
    c(
      lng1 = safe_summary(pts[[col_names$lng]], min),
      lat1 = safe_summary(pts[[col_names$lat]], min),
      lng2 = safe_summary(pts[[col_names$lng]], max),
      lat2 = safe_summary(pts[[col_names$lat]], max)
    )
  }

  fit_to_extent <- function(ext) {
    last_fit(ext)
    proxy_map |>
      leaflet$fitBounds(
        lng1 = ext[["lng1"]], lat1 = ext[["lat1"]], lng2 = ext[["lng2"]], lat2 = ext[["lat2"]],
        options = list(padding = c(15, 15), maxZoom = MAX_FIT_ZOOM)
        # past the deepest level the basemap imagery has
        # a single plot gives a zero-size extent, which would zoom
      )
  }

  observeEvent(fit2pts(), {
    ext <- pts_extent()
    if (is.null(ext)) {
      last_fit(NULL)
      fit_pending(FALSE)
    } else if (!identical(ext, last_fit())) {
      if (visible()) fit_to_extent(ext) else fit_pending(TRUE)
    }
  })

  observeEvent(visible(), {
    if (visible() && fit_pending()) {
      fit_pending(FALSE)
      ext <- pts_extent()
      if (!is.null(ext) && !identical(ext, last_fit())) fit_to_extent(ext)
    }
  })
}
