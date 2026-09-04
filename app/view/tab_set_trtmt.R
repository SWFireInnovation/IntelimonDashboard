box::use(
  DT,
  bslib,
  dt = data.table,
  shiny,
)

box::use(
  app/logic/manage_data,
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
      shiny$div(
        style = "text-align:right;",
        shiny$actionLink(
          ns("btn_clear_selection"),
          label = "Clear selection",
          icon = shiny$icon("xmark")
        )
      ),
      DT$DTOutput(
        ns("tbl_selected_scans"),
        height = "100%"
      )
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
      selected_rows <- input$tbl_selected_scans_rows_selected
      if (is.null(selected_rows)) {
        shiny$showNotification(
          "No scans selected. Click on the desired rows in the the table to the left",
          type = "warning",
          duration = 30
        )
      }

      # get the row for the original sorting (this always seems to be the same as selected_rows)
      orig_display_row <- input$tbl_selected_scans_rows_all[selected_rows]

      # get the data.table with the original sorting
      displayed_scans <- dt$copy(session$userData$scan_selection())
      displayed_scans <- displayed_scans[order(plot, site, -date)]

      if (nzchar(input$ui_enter_unit)) {
        displayed_scans[orig_display_row, "Unit" := as.character(input$ui_enter_unit)] # nolint: object_name_linter
      }

      if (nzchar(input$ui_enter_remeas)) {
        displayed_scans[orig_display_row, "Remeasurement" := as.integer(input$ui_enter_remeas)] # nolint: object_name_linter
      }

      session$userData$scan_selection(displayed_scans)
    })

    #---Data Table-------------------------------
    columns <- c("site", "plot", "date", "scanner_id", "Unit", "Remeasurement")

    output$tbl_selected_scans <- DT$renderDT({
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
        # make site, plot, date, scanner_id ReadOnly, but allow unit and remeasurement to be changed
        editable = list(target = "cell", disable = list(columns = c(0, 1, 2, 3))),
        options = list(
          pageLength = 50,
          ordering = TRUE,
          paging = FALSE,
          # sort by date, then site w/in each date, then plot w/in each site
          order = list(list(2, "asc"), list(0, "asc"), list(1, "asc"))
        )
      )
    })

    proxy <- DT$dataTableProxy(
      "tbl_selected_scans",
      session = session
    )

    shiny$observeEvent(input$btn_clear_selection, {
      DT$selectRows(proxy, NULL)
    })

    # allow the user to change table values
    shiny$observeEvent(input$tbl_selected_scans_cell_edit, {
      changes <- input$tbl_selected_scans_cell_edit

      selected_scans <- session$userData$scan_selection()
      displayed_scans <- selected_scans[, ..columns]

      displayed_scans <- DT$editData(displayed_scans, changes, rownames = FALSE)

      session$userData$scan_selection(selected_scans[, (columns) := displayed_scans])
    })
  })
}
