box::use(
  DT,
  bslib,
  dt = data.table,
  shiny,
)

box::use(
  app/logic/manage_data,
  wDT = app/view/widget_datatable,
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
          full_screen = FALSE,
          fill = FALSE,
          max_height = "500px",
          min_height = "100px",
          bslib$card_header(shiny$h4("Add Treatment Dates")),
          bslib$card_body(
            fill = FALSE,
            shiny$helpText(
              "Scans measured after treatment dates will have their remeasurement numbers
                                                      automatically increased."
            ),
            shiny$dateInput(
              ns("ui_selected_date"),
              label = shiny$h6("Select Date"),
              value = Sys.Date(),
              format = "yyyy-mm-dd",
              autoclose = TRUE
            ),
            shiny$actionButton(
              ns("btn_add_trtmt"),
              "Add Date"
            ),
            shiny$div(
              style = "text-align:right; margin-top: 5px;", # "display:flex; justify-content:flex-end;", #
              shiny$actionLink(
                ns("btn_delete_trtmt"),
                label = NULL, # "Delete selected",
                icon = shiny$icon("trash"),
              ),
              DT$DTOutput(
                ns("tbl_trtmt_dates")
              )
            )
          )
        ),
        bslib$card(
          bslib$card_header(shiny$h4("Set Unit Name or Remeasurement")),
          shiny$helpText(
            "To assign a unit name or remeasurement number, select the scans in the table to the left,
            enter the desired values below and hit the Assign button."
          ),
          shiny$textInput(
            ns("ui_enter_unit"),
            label = "Unit Name",
            placeholder = "BigCreek",
            value = "",
            updateOn = "change"
          ),
          shiny$textInput(
            ns("ui_enter_remeas"),
            label = "Scan Remeasurement",
            placeholder = "0 (initial scan)",
            value = "",
            updateOn = "change"
          ),
          shiny$actionButton(
            ns("btn_assign"),
            "Assign"
          )
        )
      ),
      wDT$ui(ns("tbl_selected_scans"))
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {
    #----Add Treatment Dates---------------------
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
      trtmt_dates <- session$userData$trtmt_dates()


      DT$datatable(
        session$userData$trtmt_dates(),
        colnames = "",
        caption = "Treatment Dates",
        filter = "none",
        rownames = FALSE,
        height = "100%",
        selection = "single",
        editable = TRUE,
        options = list(
          ordering = TRUE,
          searching = FALSE,
          paging = FALSE,
          dom = "t"
        )
      )
    })

    # delete treament dates
    shiny$observeEvent(input$btn_delete_trtmt, {
      row <- input$tbl_trtmt_dates_rows_selected
      if (is.null(row) || length(row) == 0) {
        shiny$showNotification(
          "Select a treatment date to delete.",
          type = "warning"
        )
        return()
      }
      trtmt_dates <- session$userData$trtmt_dates()

      trtmt_dates <- trtmt_dates[-row]
      session$userData$trtmt_dates(trtmt_dates)
    })

    #------Assign Unit or Remeasurement----------
    shiny$observeEvent(input$btn_assign, {
      # always initializes as NULL
      selected_rows <- tbl_dt$input$dt_rows_selected
      if (is.null(selected_rows)) {
        shiny$showNotification(
          "No scans selected. Click on the desired rows in the the table to the left",
          type = "warning",
          duration = 30
        )
      }

      displayed_scans <- selected_scans()

      if (nzchar(input$ui_enter_unit)) {
        displayed_scans[selected_rows, "Unit" := as.character(input$ui_enter_unit)] # nolint: object_name_linter
      }

      if (nzchar(input$ui_enter_remeas)) {
        displayed_scans[selected_rows, "Remeasurement" := as.integer(input$ui_enter_remeas)] # nolint: object_name_linter
      }

      session$userData$scan_selection(displayed_scans)
    })

    #---Data Table-------------------------------
    columns <- c("site", "plot", "date", "scanner_id", "Unit", "Remeasurement")
    selected_scans <- shiny$reactive({
      session$userData$scan_selection()[order(plot, site, -date)]
    })

    tbl_dt <- wDT$server("tbl_selected_scans",
      selected_scans,
      columns,
      sort_order = list(list(2, "asc"), list(0, "asc"), list(1, "asc")),
      # make site, plot, date, scanner_id ReadOnly, but allow unit and remeasurement to be changed
      edit_options = list(target = "cell", disable = list(columns = c(0, 1, 2, 3)))
    )

    # allow the user to change table values
    shiny$observeEvent(tbl_dt$input$dt_cell_edit, {
      changes <- tbl_dt$input$dt_cell_edit

      selected_scans <- session$userData$scan_selection()
      displayed_scans <- selected_scans[, ..columns]

      displayed_scans <- DT$editData(displayed_scans, changes, rownames = FALSE)

      session$userData$scan_selection(selected_scans[, (columns) := displayed_scans])
    })
  })
}
