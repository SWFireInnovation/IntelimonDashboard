box::use(
  shiny,
  bslib[nav_panel, card_header, card_body],
  gridlayout[grid_container, grid_card, grid_card_plot],
  leaflet,
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  nav_panel(title = "Selection Map",
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
                  shiny$selectInput(
                    inputId = ns("mySelectInput"),
                    label = "Agency selection",
                    choices = list("ALL" = "NULL", "usfws" = "a", "choice b" = "b")
                  ),
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
  shiny$moduleServer(id, function(input, output, session){
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
        options = leaflet$providerTileOptions(
          maxZoom = 20
        )
      ) |>

      # Initial view
      leaflet$setView(
        lng = -95,
        lat = 39,
        zoom = 4
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