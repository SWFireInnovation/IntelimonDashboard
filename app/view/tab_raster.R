box::use(
  bslib[card_body, card_header, nav_panel],
  gridlayout[grid_card, grid_container],
  shiny[NS, moduleServer],
)

#' @export
ui <- function(id) {
  ns <- NS(id) # nolint: object_usage_linter

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
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {})
}
