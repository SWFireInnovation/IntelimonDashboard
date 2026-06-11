#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#
box::use(
  bslib[bs_theme, card_body, card_header, nav_panel, page_navbar],
  gridlayout[grid_card, grid_card_plot, grid_container],
  leaflet[leafletOutput],
  shiny[actionButton, dateRangeInput, radioButtons, selectInput, textInput, uiOutput],
)

# Define UI for application that draws a histogram
page_navbar(
    # Application title
    title = "IntELiMon Dashboard",
    selected = "Selection Map",
    collapsible = TRUE,
    theme = bs_theme(),

    nav_panel(
      title = "Load Data",
      textInput("ui_data_dir", "Enter Data Directory Path:"),
      actionButton("submit_dir", "Load Directory")
    ),

    # Sidebar with a slider input for number of bins
    nav_panel(
      title = "Histogram",
      sidebarLayout(
        sidebarPanel(
            uiOutput("plot_selector_ui"),
            uiOutput("column_selector_ui"),
            uiOutput('bins_ui')
        ),

        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("col_hist")
        )
      )
    ),

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
