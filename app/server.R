#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#


box::use(
  view/tab_selectionMap,
  view/tab_histogram,
  view/tab_load_data
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  data_dir <- tab_load_data$server("Load Data")
  tab_histogram$server("Histogram", data_dir = data_dir)
  tab_selectionMap$server("Selection Map")
}
