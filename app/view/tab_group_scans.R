box::use(
  bslib,
  DT,
  gridlayout[grid_card, grid_card_plot, grid_container],
  shiny,
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$nav_panel(
    title = "Group Scans",
    fillable = TRUE,

    bslib$layout_sidebar(
      fillable = TRUE,
      height = "100%",

      sidebar = bslib$sidebar(
        position = "right",
        width = 350,

      ),
      DT$DTOutput(
        ns("selected_plots"),
        height = "100%"
      )
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {

    columns <- c('site', 'plot', 'date', 'scanner_id', "Unit", "Remeasurement")

    output$selected_plots <- DT$renderDT({
      selected_scans <- session$userData$scan_selection()

      shiny$validate(
        shiny$need(
          nrow(selected_scans) > 0,
          "No scans selected. Return to Selection Map tab."
        )
      )

      DT$datatable(
        selected_scans[, ..columns],
        filter = "top",
        rownames = TRUE,
        selection = "multiple",
        options = list(
          pageLength = 50,
          ordering = TRUE,
          # sort by date, then site w/in each date, then plot w/in each site
          order = list(list(2, "asc"), list(0, "asc"), list(1, "asc"))
        )
      )
    })
  })
}


