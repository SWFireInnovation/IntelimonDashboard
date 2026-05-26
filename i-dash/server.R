#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(yaml)
library(glue)
# could simplify and remove
library(purrr)
library(dplyr)

intelimon_out <- read_yaml('../data_loc.yaml')$data_dir
data_dir <- file.path(intelimon_out, 'metrics')



# Define server logic required to draw a histogram
function(input, output, session) {
  
  # Reactive expression to fetch raw file names and create clean labels
  file_select <- reactive({
    
    file_names <- list.files(data_dir, pattern = "\\.csv$")
    
    plot_names <- tools::file_path_sans_ext(file_names)
    
    setNames(file_names, plot_names)
    
  })
  
  # Dynamically render the selection UI based on available files
  output$plot_selector_ui <- renderUI({
    plot_files <- file_select()
    
    if (length(plot_files) == 0) {
      return(p("No CSV files found in the 'data' folder."))
    }
    
    selectInput(
      inputId = "selected_plots",
      label = "Choose Plots to Load:",
      choices = names(plot_files), # Shows clean names to user
      multiple = TRUE,          # Allows selecting more than one file
      selected = names(plot_files)[1:2]
    )
  })

  # Reactive expression to load and combine the selected CSV data
  combined_data <- reactive({
    req(input$selected_plots)
    plot_files <- file_select()
    
    # Map user selection back to actual file names and build full paths
    selected_files <- plot_files[input$selected_plots]
    full_paths <- file.path(data_dir, selected_files)
    
    # Read all selected files and merge them into a single data frame
    full_paths %>% 
      setNames(input$selected_plots) %>% 
      map_df(~read.csv(.x), .id = "Plot_ID")
  })
  
  
  output$column_selector_ui <- renderUI({
    req(input$selected_plots)
    
    df <- combined_data()
    req(df)
    
    selectInput(
      inputId = "selected_column",
      label = "Choose Column:",
      choices = names(df),
      selected = names(df)[1]
    )
  })
  
  # Dynamically render the plot
  output$col_hist <- renderPlot({
    print('Plot triggered')
    print(input$selected_column)
    req(combined_data(), input$selected_column)
    
    df <- combined_data()
    col <- input$selected_column
    
    print(col)
    
    # Verify the expected columns exist before plotting
    if (!(col %in% names(df))) {
      showNotification("Selected files must contain column.", type = "error")
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

}
