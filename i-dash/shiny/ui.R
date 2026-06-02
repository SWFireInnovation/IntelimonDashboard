#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)

# Define UI for application that draws a histogram
fluidPage(

    # Application title
    titlePanel("TLS Monitoring"),
    
    tabsetPanel(
      id = "load_data",
      tabPanel(title = "Load Data", value = "data_input_tab",
               textInput("ui_data_dir", "Enter Data Directory Path:"),
               actionButton("submit_dir", "Load Directory")
               )
    ),

    # Sidebar with a slider input for number of bins
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
)
