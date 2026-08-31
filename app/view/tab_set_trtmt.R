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
    title = "Set Treatments",
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
    ),

    shiny$dateInput(
      session$ns("date_select"),
      inputID = "date_select",
      label = shiny$h3("Add Each Treatment Date"),
      value =  Sys.Date(),
      format = "YYY-mm-dd",
      autoclose = TRUE
    ),

    shiny$actionButton(
      session$ns("add_trtmt"),
      "Add Date"
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {

    columns <- c('site', 'plot', 'date', 'scanner_id', "Unit", "Remeasurement")

    output$selected_plots <- DT$renderDT({
      selected_scans <- session$userData$scan_selection()

      nscans <- nrow(selected_scans)
      metrics_msg <- "Selected scans have not been downloaded! Return to Selection Map tab."
      shiny$validate(
        shiny$need(
          nscans > 0,
          "No scans selected. Return to Selection Map tab."
        ),
        shiny$need(
          !is.null(session$userData$metrics()),
          metrics_msg
        ),
        shiny$need(
          nrow(session$userData$metrics()) == nscans,
          metrics_msg
        )
      )

      # set the default table sorting
      selected_scans <- selected_scans[order(plot, site, -date)]

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


