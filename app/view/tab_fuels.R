box::use(
  bslib[nav_panel],
  shiny[NS, moduleServer],
)

#' @export
ui <- function(id) {
  ns <- NS(id) # nolint: object_usage_linter

  nav_panel(title = "Fuels exports")
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {})
}
