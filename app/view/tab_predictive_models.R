box::use(
  shiny[moduleServer, NS],
  bslib[nav_panel, card_header, card_body],
  gridlayout[grid_container, grid_card],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

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
    )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session){

  })
}