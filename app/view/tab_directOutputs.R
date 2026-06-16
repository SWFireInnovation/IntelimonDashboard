box::use(
  shiny[moduleServer, NS, selectInput],
  bslib[nav_panel, card_header, card_body],
  gridlayout[grid_container, grid_card, grid_card_plot],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  nav_panel(
      title = "Direct outputs",
      grid_container(
        layout = c(
          "IntELiMonDSS directOutputs"
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
          card_header("Select Statistics"),
          card_body(
            selectInput(
              inputId = "treeStatistics",
              label = "Mean Tree Statistics",
              choices = list(
                "Basal area" = "a",
                "Diameters" = "b",
                "Mean heights" = "value3",
                "Maximum heights" = "value4"
              )
            ),
            selectInput(
              inputId = "volumeStatistics",
              label = "Mean Volume Statistics",
              choices = list(
                "micro-Ground cover" = "a",
                "micro-Understory" = "b",
                "micro-Midstory" = "value3",
                "micro-Overstory" = "value4"
              )
            ),
            selectInput(
              inputId = "mySelectInput",
              label = "Mean Canopy Statistics",
              choices = list("Canopy base height" = "a", "Gap fraction" = "b")
            )
          )
        ),
        grid_card(
          area = "directOutputs",
          card_body(
            grid_container(
              layout = c(
                "treeStats   volumeStats",
                "canopyStats .          "
              ),
              row_sizes = c(
                "1fr",
                "1fr"
              ),
              col_sizes = c(
                "1fr",
                "1fr"
              ),
              gap_size = "10px",
              grid_card_plot(area = "treeStats"),
              grid_card_plot(area = "canopyStats"),
              grid_card_plot(area = "volumeStats")
            )
          )
        )
      )
    )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session){

  })
}