library(shiny)
library(ggplot2)
library(bslib)
library(gridlayout)
library(leaflet)


ui <- page_navbar(
  title = "IntELiMon Dashboard",
  selected = "Selection Map",
  collapsible = TRUE,
  theme = bslib::bs_theme(),
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
          selectInput(
            inputId = "mySelectInput",
            label = "Agency selection",
            choices = list("ALL" = "NULL", "usfws" = "a", "choice b" = "b")
          ),
          radioButtons(
            inputId = "myRadioButtons",
            label = "Plot selection",
            choices = list("choice a" = "a", "choice b" = "b"),
            width = "100%"
          ),
          textInput(
            inputId = "myTextInput",
            label = "Treatment dates",
            value = "YYYYMMDD, YYYYMMDD..."
          ),
          
          dateRangeInput(
            inputId = "daterange",
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
        leafletOutput("map", height = 400)
      )
    )
  ),
  nav_panel(
    title = "Direct outputs",
    grid_container(
      layout = c(
        "IntELiMonDSS directOutputs"
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
        card_header("Select Statistics"),
        card_body(
          selectInput(
            inputId = "treeStatistics",
            label = "Mean Tree Statistics",
            choices = list(
              "Basal area" = "a",
              "Diameters" = "b",
              "Mean heights" = "value3",
              "Maximum heights" = "value4"
            )
          ),
          selectInput(
            inputId = "volumeStatistics",
            label = "Mean Volume Statistics",
            choices = list(
              "micro-Ground cover" = "a",
              "micro-Understory" = "b",
              "micro-Midstory" = "value3",
              "micro-Overstory" = "value4"
            )
          ),
          selectInput(
            inputId = "mySelectInput",
            label = "Mean Canopy Statistics",
            choices = list("Canopy base height" = "a", "Gap fraction" = "b")
          )
        )
      ),
      grid_card(
        area = "directOutputs",
        card_body(
          grid_container(
            layout = c(
              "treeStats   volumeStats",
              "canopyStats .          "
            ),
            row_sizes = c(
              "1fr",
              "1fr"
            ),
            col_sizes = c(
              "1fr",
              "1fr"
            ),
            gap_size = "10px",
            grid_card_plot(area = "treeStats"),
            grid_card_plot(area = "canopyStats"),
            grid_card_plot(area = "volumeStats")
          )
        )
      )
    )
  ),
  nav_panel(
    title = "Predictive models",
    grid_container(
      layout = c(
        "IntELiMonDSS ."
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
        card_header("Select Models"),
        card_body()
      )
    )
  ),
  nav_panel(
    title = "Raster products",
    grid_container(
      layout = c(
        "IntELiMonDSS ."
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
        card_header("Select Raster"),
        card_body()
      )
    )
  ),
  nav_panel(title = "Fuels exports"),
  nav_panel(title = "Forestry exports"),
  nav_panel(title = "rothRmel"),
  nav_panel(title = "Help")
)


server <- function(input, output) {
  
  # Return dates as YYYYMMDD
  selected_dates <- reactive({
    c(
      start = format(input$daterange[1], "%Y%m%d"),
      end   = format(input$daterange[2], "%Y%m%d")
    )
  })
  
  output$dates <- renderPrint({
    selected_dates()
  })
  
  
  output$map <- renderLeaflet({
    
    leaflet(
      options = leafletOptions(
        crs = leafletCRS(
          crsClass = "L.CRS.EPSG3857",
          code = "EPSG:3857",
          proj4def = "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
          resolutions = NULL
        )
      )
    ) |>
      
      # Esri World Imagery (satellite basemap)
      addProviderTiles(
        providers$Esri.WorldImagery,
        options = providerTileOptions(
          maxZoom = 20
        )
      ) |>
      
      # Initial view
      setView(
        lng = -95,
        lat = 39,
        zoom = 4
      )
  })
  
}

shinyApp(ui, server)
  

