box::use(
  bslib[bs_theme, card_body, card_header, nav_panel, navbar_options, page_navbar],
  grDevices[hcl.colors],
  gridlayout[grid_card, grid_container],
  leaflet,
  shiny,
)

box::use(
  api = app/logic/load_data_api,
  app/logic/manage_data[get_scans4dwnld, set_remeas_by_yr],
  app/logic/map_fnc[parse_click_id],
  app/view/map_controls[update_dwnld_scan_points, update_point_labels, update_selected_scan_points],
  wDT = app/view/widget_datatable,
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  nav_panel(
    title = "Selection Map",
    grid_container(
      layout = c(
        "IntELiMonDSS selection"
      ),
      row_sizes = c(
        "1fr"
      ),
      col_sizes = c(
        "250px",
        "1fr"
      ),
      gap_size = "10px",
      grid_card(
        area = "IntELiMonDSS",
        card_header("Select Scans"),
        card_body(
          shiny$uiOutput(ns("ui_select_agency")),
          shiny$uiOutput(ns("ui_select_date_range")),
          shiny$actionButton(ns("btn_clear"), "\u2715  Clear All Plots", width = "100%"),
          shiny$actionButton(ns("btn_get_data"), "\u2913  Get Data", width = "100%"),
        )
      ),
      grid_card(
        area = "selection",
        full_screen = TRUE,
        # card_header("IntELiMon Plots"),
        page_navbar(
          title = "IntELiMon Plots",
          selected = "Location Map",
          navbar_options = navbar_options(collapsible = TRUE),
          theme = bs_theme(),
          header = shiny$tags$head(shiny$includeCSS("app/static/styles.css")),
          nav_panel(title = "Location Map", leaflet$leafletOutput(ns("map"))),
          nav_panel(title = "Table", wDT$ui(ns("tbl_scan_filter")))
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {
    #-----Base Map-------------------------------
    output$map <- leaflet$renderLeaflet({
      leaflet$leaflet(
        options = leaflet$leafletOptions(
          crs = leaflet$leafletCRS(
            crsClass = "L.CRS.EPSG3857",
            code = "EPSG:3857",
            proj4def = "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
            resolutions = NULL
          )
        )
      ) |>
        # Esri World Imagery (satellite basemap)
        leaflet$addProviderTiles(
          leaflet$providers$Esri.WorldImagery,
          options = leaflet$providerTileOptions(maxZoom = 20),
          group = "Satellite"
        ) |>
        # Esri World Imagery (political basemap)
        leaflet$addProviderTiles(
          leaflet$providers$Esri.WorldGrayCanvas,
          options = leaflet$providerTileOptions(maxZoom = 20),
          group = "Base Map"
        ) |>
        leaflet$addLayersControl(
          baseGroups = c("Satellite", "Base Map"),
          options    = leaflet$layersControlOptions(collapsed = FALSE),
          position   = "topright"
        )
    })

    #-----Map plot locations---------------------
    # Discrete palette for plot mapping. `levels` is the set of distinct
    # agencies, not the whole column: passing all 11k+ scan rows makes
    # colorFactor warn about duplicate levels on every startup.
    #
    # `unique()` rather than `sort(unique())` - colorFactor takes the levels in
    # the order given, so de-duplicating in place preserves the existing
    # agency-to-colour assignment. Sorting them would keep the same nine
    # colours but shuffle which agency gets which.
    color_palette <- shiny$reactive({
      agency_levels <- unique(session$userData$all_scans()$Agency)

      leaflet$colorFactor(
        hcl.colors(length(agency_levels), "Dark 2"),
        levels = agency_levels
      )
    })

    # make reactive markers
    filtered_plots <- shiny$reactive({
      plots <- session$userData$all_scans()
      filter_plots <- plots[date >= input$ui_select_date_range[1] & date <= input$ui_select_date_range[2]]
      if (is.null(input$ui_select_agency) ||
            length(input$ui_select_agency) == 0) {
        return(filter_plots)
      }
      filter_plots[Agency %in% input$ui_select_agency]
    })

    proxy_map <- leaflet$leafletProxy("map", session)

    shiny$observeEvent(filtered_plots(), {
      markers <- filtered_plots()
      shiny$req(nrow(markers) > 0)
      # remove selected plots that do not fit the updated filter
      all_clicks <- session$userData$scan_selection()
      all_clicks <- all_clicks[markers,
        on = .(site, plot, date),
        nomatch = 0, .SD,
        .SDcols = names(all_clicks)
      ]
      session$userData$scan_selection(all_clicks)

      proxy_map |>
        leaflet$clearMarkers() |>
        leaflet$clearControls() |>
        leaflet$addCircleMarkers(
          data = markers,
          layerId = ~ paste(site, plot, sep = "-"),
          lng = ~Longitude,
          lat = ~Latitude,
          color = ~ color_palette()(Agency),
          radius = 4
        ) |>
        leaflet$addLegend(
          data = markers,
          position = "bottomleft",
          pal = color_palette(),
          values = ~Agency,
          opacity = 0.6
        ) |>
        leaflet$fitBounds(
          lng1 = min(markers$Longitude), lat1 = min(markers$Latitude),
          lng2 = max(markers$Longitude), lat2 = max(markers$Latitude),
          options = list(padding = c(15, 15))
        )
    })

    #-----Show labels once zoomed in-------------
    update_point_labels(input,
                        proxy_map,
                        filtered_plots(),
                        map_id = "map",
                        col_names = list(lat = "Latitude", lng = "Longitude", label = "plot"))

    #----Plots table-----------------------------
    columns <- c("site", "plot", "date", "scanner_id", "Latitude", "Longitude")
    tbl_dt <- wDT$server("tbl_scan_filter",
                            filtered_plots,
                            columns,
                            list(list(0, "asc"), list(1, "asc"), list(2, "asc")),
                            edit_options = FALSE)

    #----Select plots----------------------------
    shiny$observeEvent(input$map_marker_click, {
      click <- input$map_marker_click

      markers <- filtered_plots()
      all_clicks <- session$userData$scan_selection()

      if (is.null(click$id)) {
        return()
      }

      site_list <- parse_click_id(click, sep = "-", labels = c("site", "plot"))

      if (click$id %in% all_clicks$id) {
        # if clicked on a second time, remove (un-select)
        all_clicks <- all_clicks[id != click$id]
      } else {
        selected <- markers[site == site_list$site & plot == site_list$plot]
        selected[, ":="(
          id = click$id,
          Unit = "My Unit",
          Remeasurement = NA_real_
        )]
        all_clicks <- rbind(all_clicks, selected)
      }

      # reassign to reactive variable
      session$userData$scan_selection(all_clicks)
    })

    update_selected_scan_points(session, proxy_map, col_names = list(lat = "Latitude", lng = "Longitude"))
    update_dwnld_scan_points(session, proxy_map, col_names = list(lat = "Latitude", lng = "Longitude"))

    shiny$observeEvent(input$btn_clear, {
      current <- session$userData$scan_selection()
      session$userData$scan_selection(current[0])
      shiny$showNotification("Cleared selected plots.", type = "message", duration = 5)
    })

    shiny$observeEvent(input$btn_get_data, {
      selected <- get_scans4dwnld(session)
      nscans <- nrow(selected)
      nplots <- nrow(unique(selected, by = c("site", "plot")))

      if (nscans == 0) {
        shiny$showNotification(
          "No scans selected. Click on a desired plot and set date range.",
          type = "warning", duration = 5
        )
        return()
      }

      # assign a default remeasurement number based on sequential years of measurment
      set_remeas_by_yr(session)

      # create a progress bar
      dwnld_prog <- shiny$Progress$new(session)
      on.exit(dwnld_prog$close())
      dwnld_prog$set(
        message = paste("Getting data from", nscans, " new scans at", nplots, "plots..."),
        value = 0
      )
      prog_obj <- list(
        step = 1 / (nscans * 3),
        obj = dwnld_prog,
        detail = ""
      )

      # download data from the API and save to this session
      session$userData$metrics(
        rbind(
          session$userData$metrics(),
          api$get_metrics_for_scans(selected, progress = prog_obj)
        )
      )

      session$userData$tree_inv <- rbind(
        session$userData$tree_inv,
        api$get_treeinv_for_scans(selected, progress = prog_obj)
      )

      session$userData$extra_models(
        rbind(
          session$userData$extra_models(),
          api$get_extra_models_for_scans(selected, progress = prog_obj)
        )
      )
    })

    #-----renderUI components--------------------
    output$ui_select_agency <- shiny$renderUI({
      agencies <- api$get_agencies()$value
      shiny$selectInput(
        inputId = session$ns("ui_select_agency"),
        label = "Agency selection",
        choices = agencies[order(agencies)],
        multiple = TRUE
      )
    })

    output$ui_select_date_range <- shiny$renderUI({
      plots <- session$userData$all_scans()
      min_yr <- min(plots$date)
      max_yr <- max(plots$date)
      shiny$sliderInput(
        inputId = session$ns("ui_select_date_range"),
        label = "Select date range",
        min = min_yr,
        max = max_yr,
        value = c(min_yr, max_yr),
        step = 30,
        timeFormat = "%Y-%m-%d"
      )
    })
  })
}
