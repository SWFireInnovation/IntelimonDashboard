#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#
box::use(
  bslib[bs_theme, page_navbar]
)

box::use(
  view/tab_help,
  view/tab_rothRmel,
  view/tab_forestry,
  view/tab_fuels,
  view/tab_raster,
  view/tab_predictive_models,
  view/tab_directOutputs,
  view/tab_selectionMap,
  view/tab_histogram,
  view/tab_load_data
)

# Define UI for application that draws a histogram
ui <- page_navbar(
      # Application title
      title = "IntELiMon Dashboard",
      selected = "Selection Map",
      collapsible = TRUE,
      theme = bs_theme(),

      if (!file.exists("../data_loc.yaml")) {
            tab_load_data$ui("Load Data")
      },

    tab_histogram$ui("Histogram"),
    tab_selectionMap$ui("Selection Map"),
    tab_directOutputs$ui("Direct outputs"),
    tab_predictive_models$ui("Predictive models"),
    tab_raster$ui("Raster products"),
    tab_fuels$ui("Fuels exports"),
    tab_forestry$ui("Forestry exports"),
    tab_rothRmel$ui("rothRmel"),
    tab_help$ui("Help")
)
