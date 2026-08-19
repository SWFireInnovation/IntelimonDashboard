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
          shiny$radioButtons(
            inputId = ns("myRadioButtons"),
            label = "Plot selection",
            choices = list("choice a" = "a", "choice b" = "b"),
            width = "100%"
          ),
          shiny$textInput(
            inputId = ns("myTextInput"),
            label = "Treatment dates",
            value = "YYYYMMDD, YYYYMMDD..."
          ),
          shiny$dateRangeInput(
            inputId = ns("daterange"),
            label = "Select date range",
            start = "2021-01-01",
            end = Sys.Date(),
            min = "2021-01-01",
            max = Sys.Date(),
            format = "yyyy-mm-dd"
          )
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

    # Discrete palette for plot mapping
    n_color <- length(unique(plots$Agency))
    color_palette <- leaflet$colorFactor(hcl.colors(n_color, 'Set 3'), levels = plots$Agency)

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
        ) |>
        leaflet$addCircleMarkers(data = plots,
                                 lng = ~Longitude,
                                 lat = ~Latitude,
                                 color = ~color_palette(Agency),
                                 radius = 4
        ) |>
        leaflet$addLegend(data = plots,
                          position = 'bottomright',
                          pal = color_palette, values=~Agency,
                          opacity = 0.6
        )
    })

    output$ui_select_agency <- shiny$renderUI({
      agencies <- api$get_agencies()$value
      shiny$selectInput(
        inputId = session$ns("ui_select_agency"),
        label = "Agency selection",
        choices = agencies[order(agencies)],
        multiple = TRUE

      )
    })

    # Return dates as YYYYMMDD
    selected_dates <- shiny$reactive({
      c(
        start = format(input$daterange[1], "%Y%m%d"),
        end   = format(input$daterange[2], "%Y%m%d")
      )
    })

    output$dates <- shiny$renderPrint({
      selected_dates()
    })
  })
}
