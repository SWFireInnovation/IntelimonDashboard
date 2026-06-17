box::use(
  bslib[nav_panel],
  shiny,
)

box::use(
  app/logic/load_data_dir[get_data_path],
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  nav_panel(
    title = "Load Data",
    shiny$textInput(ns("ui_data_dir"), "Enter Data Directory Path:"),
    shiny$actionButton(ns("submit_dir"), "Load Directory")
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {
    # Initialize data_dir reactively based on yaml existence
    data_dir <- shiny$reactiveVal(get_data_path())

    # update data_dir if input through the UI.
    shiny$observeEvent(input$submit_dir, {
      shiny$req(input$ui_data_dir)

      if (dir.exists(input$ui_data_dir)) {
        data_dir(input$ui_data_dir)
      } else {
        shiny$showNotification("Directory does not exist.", type = "error")
      }
    })
    # return the reactive so the main server can pass it to other modules
    data_dir
  })
}
