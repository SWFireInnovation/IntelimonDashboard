box::use(
  shiny[moduleServer, NS],
  bslib[nav_panel]
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  nav_panel(title = "Fuels exports")
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session){

  })
}