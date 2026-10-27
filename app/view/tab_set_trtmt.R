box::use(
  DT,
  bslib,
  dt = data.table,
  shiny,
)

box::use(
  app/logic/constants[TREATMENT_TYPES],
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
          max_height = "620px",
          min_height = "100px",
          bslib$card_header(shiny$h4("Add Treatment Dates")),
          bslib$card_body(
            fill = FALSE,
            shiny$helpText(
              "Scans collected after a treatment date are moved into a new scan grouping.
              Adding or deleting a date regroups every scan and replaces scan groupings
              entered by hand."
            ),
            shiny$dateInput(
              ns("ui_selected_date"),
              label = shiny$h6("Select Date"),
              value = Sys.Date(),
              format = "yyyy-mm-dd",
              autoclose = TRUE
            ),
            # what was done on that date: kept with the date for the report and
            # for later analysis; several can be picked for a combined treatment
            shiny$selectizeInput(
              ns("ui_trtmt_type"),
              label = shiny$h6("Treatment"),
              choices = TREATMENT_TYPES,
              multiple = TRUE,
              options = list(placeholder = "Pick one or more (optional)")
            ),
            shiny$actionButton(
              ns("btn_add_trtmt"),
              "Add Date"
            ),
            # the dates added so far, with the delete control for the selected one
            # directly beneath them
            shiny$h6("Treatment dates", style = "margin-top: 8px;"),
            DT$DTOutput(
              ns("tbl_trtmt_dates"),
              fill = FALSE
            ),
            shiny$div(
              style = "text-align:right; margin-top: 4px;",
              shiny$actionLink(
                ns("btn_delete_trtmt"),
                label = NULL,
                icon = shiny$icon("trash"),
                title = "Delete the selected treatment date"
              )
            )
          )
        ),
        bslib$card(
          bslib$card_header(shiny$h4("Set Unit Name, Remeasurement or Scan Grouping")),
          shiny$helpText(
            "To assign a unit name, remeasurement number or scan grouping, select the scans in the
            table to the left, enter the desired values below and hit the Assign button."
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
          shiny$textInput(
            ns("ui_enter_group"),
            label = "Scan Grouping",
            placeholder = "1 (first time step)",
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
        # removes the selected scans from the session, with their downloaded data
        style = "text-align:right;",
        shiny$actionLink(
          ns("btn_remove_scans"),
          label = "Remove selected scans",
          icon = shiny$icon("trash"),
          title = "Remove the selected scans and their downloaded data from this session"
        )
      ),
      wDT$ui(ns("tbl_selected_scans"))
    )
  )
}

# The treatment types picked for a date as one value ("Thinning, Piling and
# burning"); NA when none was picked.
treatment_type <- function(types) {
  if (length(types) == 0) NA_character_ else paste(types, collapse = ", ")
}

# The scans in the order handed to the scan table. DT reports selected and
# edited rows by their position in this data, whatever order the table is
# displayed in, so assignments and edits are applied to this same order.
table_order <- function(scans) dt$copy(scans)[order(plot, site, -date)]

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
            TreatmentDate = input$ui_selected_date,
            TreatmentType = treatment_type(input$ui_trtmt_type)
          )
        )
        session$userData$trtmt_dates(trtmt_dates[order(TreatmentDate)])
        shiny$updateSelectizeInput(session, "ui_trtmt_type", selected = "")

        manage_data$set_scan_groups(session)
      }
    })

    output$tbl_trtmt_dates <- DT$renderDT({
      trtmt_dates <- session$userData$trtmt_dates()


      DT$datatable(
        session$userData$trtmt_dates(),
        colnames = c("Date", "Treatment"),
        filter = "none",
        rownames = FALSE,
        selection = "single",
        # dates are changed by deleting and adding them, so the
        # scan groupings follow
        editable = FALSE,
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
      manage_data$set_scan_groups(session)
    })

    #------Assign Unit, Remeasurement or Scan Grouping----
    shiny$observeEvent(input$btn_assign, {
      # always initializes as NULL
      selected_rows <- tbl_dt$input$dt_rows_selected
      if (is.null(selected_rows)) {
        shiny$showNotification(
          "No scans selected. Click on the desired rows in the the table to the left",
          type = "warning",
          duration = 30
        )
        return()
      }

      displayed_scans <- selected_scans()

      if (nzchar(input$ui_enter_unit)) {
        displayed_scans[selected_rows, "Unit" := as.character(input$ui_enter_unit)] # nolint: object_name_linter
      }

      if (nzchar(input$ui_enter_remeas)) {
        displayed_scans[selected_rows, "Remeasurement" := as.integer(input$ui_enter_remeas)] # nolint: object_name_linter
      }

      # the cards and the report group scans into time steps by this column
      if (nzchar(input$ui_enter_group)) {
        group <- as.integer(input$ui_enter_group)
        displayed_scans[selected_rows, "ScanGroup" := group] # nolint: object_name_linter
      }

      session$userData$scan_selection(displayed_scans)
    })

    #------Remove scans and their downloaded data----
    # The way to take downloaded scans out of the session one by one (issue
    # #24): deselecting them on the Selection Map keeps them loaded.
    shiny$observeEvent(input$btn_remove_scans, {
      rows <- tbl_dt$input$dt_rows_selected
      if (length(rows) == 0) {
        shiny$showNotification(
          "No scans selected. Click the rows of the scans to remove in the table.",
          type = "warning"
        )
        return()
      }
      keys <- selected_scans()[rows, manage_data$SCAN_KEY, with = FALSE]
      n_dl <- nrow(keys[manage_data$downloaded_keys(session$userData$metrics()),
                        on = manage_data$SCAN_KEY, nomatch = 0])
      n <- nrow(keys)
      shiny$showModal(shiny$modalDialog(
        title = "Remove selected scans?",
        paste0(
          "This removes ", n, " scan", if (n == 1) "" else "s", " from this session",
          if (n_dl == n) {
            paste0(", with ", if (n == 1) "its" else "their", " downloaded data")
          } else if (n_dl > 0) {
            paste0(", with the downloaded data of the ", n_dl, " already downloaded")
          } else {
            ""
          },
          ". Figures already added to the report are kept. To use ",
          if (n == 1) "it" else "them", " again, select ", if (n == 1) "it" else "them",
          " on the Selection Map and click Get Data."
        ),
        footer = shiny$tagList(
          shiny$modalButton("Cancel"),
          shiny$actionButton(session$ns("btn_remove_scans_ok"), "Remove", class = "btn-danger")
        ),
        easyClose = TRUE
      ))
      remove_pending(keys)
    })

    remove_pending <- shiny$reactiveVal(NULL)
    shiny$observeEvent(input$btn_remove_scans_ok, {
      shiny$removeModal()
      keys <- remove_pending()
      shiny$req(keys)
      n <- manage_data$remove_scans(session, keys)
      remove_pending(NULL)
      shiny$showNotification(
        paste0("Removed ", n, " scan", if (n == 1) "" else "s", "."),
        type = "message", duration = 5
      )
    })

    #---Data Table-------------------------------
    columns <- c("site", "plot", "date", "scanner_id", "Unit", "Remeasurement", "ScanGroup")
    selected_scans <- shiny$reactive({
      session$userData$scan_selection()[order(plot, site, -date)]
    })

    tbl_dt <- wDT$server("tbl_selected_scans",
      selected_scans,
      columns,
      sort_order = list(list(2, "asc"), list(0, "asc"), list(1, "asc")),
      # make site, plot, date, scanner_id ReadOnly, but allow unit and remeasurement to be changed
      edit_options = list(target = "cell", disable = list(columns = c(0, 1, 2, 3))),
      col_labels = c(columns[-length(columns)], "Scan grouping")
    )

    # allow the user to change table values
    shiny$observeEvent(tbl_dt$input$dt_cell_edit, {
      changes <- tbl_dt$input$dt_cell_edit

      # edited rows index the table's data, in table_order()
      selected_scans <- table_order(session$userData$scan_selection())
      displayed_scans <- selected_scans[, ..columns]

      displayed_scans <- DT$editData(displayed_scans, changes, rownames = FALSE)

      session$userData$scan_selection(selected_scans[, (columns) := displayed_scans])
    })
  })
}
