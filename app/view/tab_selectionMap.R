box::use(
  bslib[card_body, card_header, nav_panel],
  gridlayout[grid_card, grid_container],
  leaflet,
  shiny,
  grDevices[hcl.colors],
)

box::use(
  api = app/logic/load_data_api,
  app/logic/map_fnc,
  app/logic/select_data,
)

# load all plot locations
plots <- select_data$build_scan_loc_dt()

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  nav_panel(
    title = "Selection Map",
    grid_container(
      layout = c(
        "IntELiMonDSS leaflet_map"
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
          shiny$uiOutput(ns("ui_select_date_range"))
        )
      ),
      grid_card(
        area = "leaflet_map",
        full_screen = TRUE,
        card_header("IntELiMon Plot Locations"),
        leaflet$leafletOutput(ns("map"), height = 400)
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
          leaflet$providers$CartoDB.Positron,
          options = leaflet$providerTileOptions(maxZoom = 20),
          group = "Base Map"
        ) |>
        leaflet$addLayersControl(
          baseGroups = c("Satellite", "Base Map"),
          options    = leaflet$layersControlOptions(collapsed = FALSE),
          position   = "topright"
        ) |>
        # Initial view
        leaflet$setView(
          lng = -95,
          lat = 39,
          zoom = 4
        )
    })

    #-----Map plot locations---------------------
    # Discrete palette for plot mapping
    n_color <- length(unique(plots$Agency))
    color_palette <- leaflet$colorFactor(hcl.colors(n_color, 'Dark 2'), levels = plots$Agency)

    # make reactive markers
    filtered_plots <- shiny$reactive({
      filter_plots <- plots[date >= input$ui_select_date_range[1] & date <= input$ui_select_date_range[2]]
      if (is.null(input$ui_select_agency) ||
        length(input$ui_select_agency) == 0) {
        return(filter_plots)
      }
      filter_plots[Agency %in% input$ui_select_agency]
    })

    # empty dt of same schema, plus new ID column
    session$userData$scan_selection <- shiny$reactiveVal(plots[0][, id := character()])

    proxy_map <- leaflet$leafletProxy("map", session)

    shiny$observeEvent(filtered_plots(), {
      markers <- filtered_plots()
      # remove selected plots that do not fit the updated filter
      all_clicks <- session$userData$scan_selection()
      all_clicks[markers, on = .(site, plot, date), nomatch = 0]
      session$userData$scan_selection(all_clicks)

      proxy_map |>
        leaflet$clearMarkers() |>
        leaflet$clearControls() |>
        leaflet$addCircleMarkers(data = markers,
                                 layerId = ~paste(site, plot, sep = "-"),
                                 lng = ~Longitude,
                                 lat = ~Latitude,
                                 color = ~color_palette(Agency),
                                 radius = 4
        ) |>
        leaflet$addLegend(data = markers,
                          position = 'bottomright',
                          pal = color_palette, values=~Agency,
                          opacity = 0.6
        )
  }
  )

    #----Select plots----------------------------
    shiny$observeEvent(input$map_marker_click,
    {
      click <- input$map_marker_click

      markers <- filtered_plots()
      all_clicks <- session$userData$scan_selection()

      if (is.null(click$id)) return()

      # extract site and plot from the click id
      click_id <- strsplit(click$id, '-')[[1]]
      if (length(click_id) != 2){
        return()
      } else if (length(click_id) == 2) {
        clk_site <- click_id[[1]]
        clk_plt <- click_id[[2]]
      }

      if (click$id %in% all_clicks$id) {
        #if clicked on a second time, remove (un-select)
        all_clicks <- all_clicks[id != click$id]
      } else {
        selected <- markers[site == clk_site & plot == clk_plt]
        selected[, id := click$id]
        all_clicks <- rbind(all_clicks, selected)
      }

      # reassign to reactive variable
      session$userData$scan_selection(all_clicks)

    }
    )

    shiny$observeEvent(session$userData$scan_selection(),{
      # can be changed by `filtered_plots()` or by `input$map_marker_click`
      proxy_map |>
        leaflet$clearGroup('all_clicks') |>
        leaflet$addCircleMarkers(group = 'all_clicks',
                                 #layerId = ~paste("filtered", site, plot, sep = "-"),
                                 data = session$userData$scan_selection(),
                                 # make sure that you can still click on filtered plots to deselect
                                 options = leaflet$pathOptions(clickable = FALSE),
                                 lng = ~Longitude,
                                 lat = ~Latitude,
                                 color = 'blue',
                                 radius = 2
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
      min_yr <- min(plots$date)
      max_yr <- max(plots$date)
      shiny$sliderInput(
        inputId = session$ns('ui_select_date_range'),
        label = "Select date range",
        min = min_yr,
        max = max_yr,
        value = c(min_yr, max_yr),
        step = 30,
        timeFormat = '%Y-%m-%d'
      )
    })
  })
}
