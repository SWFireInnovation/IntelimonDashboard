box::use(
  shiny,
  bslib[nav_panel],
  glue[glue],
  graphics[hist]
)

box::use(
  app/logic/load_data_dir[list_plot_files, load_selected_plots]
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)
  # Sidebar with a slider input for number of bins
  nav_panel(
    title = "Histogram",
    shiny$sidebarLayout(
      shiny$sidebarPanel(
          shiny$uiOutput(ns("plot_selector_ui")),
          shiny$uiOutput(ns("column_selector_ui")),
          shiny$uiOutput(ns('bins_ui'))
      ),

      # Show a plot of the generated distribution
      shiny$mainPanel(
          shiny$plotOutput(ns("col_hist"))
      )
    )
  )
}

#' @export
server <- function(id, data_dir) {
  shiny$moduleServer(id, function(input, output, session){
    # Dynamically render the selection UI based on available files.
    # Reactive expression to fetch raw file names and create clean labels
    file_select <- shiny$reactive({
      shiny$req(data_dir())
      list_plot_files(data_dir())
    })

    output$plot_selector_ui <- shiny$renderUI({
      shiny$req(data_dir())
      plot_files <- file_select()

      if (length(plot_files) == 0) {
        return(shiny$p("No CSV files found in the 'data' folder."))
      }

      shiny$selectInput(
        inputId = session$ns("selected_plots"),
        label = "Choose Plots to Load:",
        choices = names(plot_files), # Shows clean names to user
        multiple = TRUE,          # Allows selecting more than one file
        selected = names(plot_files)[1:2]
      )
    })

    combined_data <- shiny$reactive({
      shiny$req(input$selected_plots)
      shiny$req(data_dir())

      load_selected_plots(data_dir(), input$selected_plots, file_select())
    })

    output$column_selector_ui <- shiny$renderUI({
      shiny$req(input$selected_plots)

      df <- combined_data()
      shiny$req(df)

      shiny$selectInput(
        inputId = session$ns("selected_column"),
        label = "Choose Column:",
        choices = names(df),
        selected = names(df)[-1]
      )
    })

    output$bins_ui <- shiny$renderUI({
      shiny$req(combined_data(), input$selected_column)

      df <- combined_data()
      col <- input$selected_column

      x <- df[[col]]

      # remove NA
      x <- x[!is.na(x)]

      shiny$req(length(x) > 0)

      # you can tune this logic depending on your data
      shiny$sliderInput(
        session$ns("bins"),
        "Number of bins:",
        min = 2,
        max = max(3, length(x)),   # scale with data size
        value = min(3, length(x))
      )
    })

    # Dynamically render the plot
    output$col_hist <- shiny$renderPlot({
      shiny$req(combined_data(), input$selected_column)

      df <- combined_data()
      col <- input$selected_column

      print(col)

      # Verify the expected columns exist before plotting
      if (!(col %in% names(df))) {
        shiny$showNotification("Selected files must contain column.", type = "error")
        return(NULL)
      }

      # generate bins based on input$bins from ui.R
      x    <- df[, col]
      bins <- seq(min(x), max(x), length.out = input$bins + 1)

      # draw the histogram with the specified number of bins
      hist(x, breaks = bins, col = 'darkgray', border = 'white',
           xlab = col,
           main = glue('Histogram of {col}'))

    })
  })
}