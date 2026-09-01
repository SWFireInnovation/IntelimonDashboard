box::use(
  bslib,
  DT,
  dt = data.table,
  gridlayout[grid_card, grid_card_plot, grid_container],
  shiny,
)

box::use(
  app/logic/manage_data
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

        bslib$card(
          bslib$card_header(shiny$h4("Add Treatment Dates")),
          shiny$dateInput(
            ns("ui_selected_date"),
            label = shiny$h6("Select Date"),
            value =  Sys.Date(),
            format = "yyyy-mm-dd",
            autoclose = TRUE
          ),

          shiny$actionButton(
            ns("btn_add_trtmt"),
            "Add Date"
          ),

          DT$DTOutput(
            ns("tbl_trtmt_dates")
          )
        )
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

    shiny$observeEvent(input$btn_add_trtmt, {
      trtmt_dates <- session$userData$trtmt_dates()

      is_new <- !(input$ui_selected_date %in% trtmt_dates$TreatmentDate)
      if (!is_new) {
        shiny$showNotification(
          "Date already added.",
          type = "warning"
        )
        return()
      } else if (is_new) {
        trtmt_dates <- rbind(
          trtmt_dates,
          dt$data.table(
            TreatmentDate = input$ui_selected_date
          )
        )
        session$userData$trtmt_dates(trtmt_dates)

        manage_data$set_remeas_by_trtmt(session, input$ui_selected_date)
      }
    })

    output$tbl_trtmt_dates <- DT$renderDT({
        DT$datatable(
          session$userData$trtmt_dates(),
          colnames="",
          caption = "Treatment Dates",
          filter = "none",
          rownames = FALSE,
          selection = "single",
          options = list(
            pageLength = 10,
            ordering = TRUE,
            searching = FALSE,
            paging = FALSE,
            dom = "t"
          )
        )
    })

    #---Data Table-------------------------------
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
        rownames = FALSE,
        selection = "multiple",
        options = list(
          pageLength = 50,
          ordering = TRUE,
          paging = FALSE,
          # sort by date, then site w/in each date, then plot w/in each site
          order = list(list(2, "asc"), list(0, "asc"), list(1, "asc"))
        )
      )
    })
  })
}


