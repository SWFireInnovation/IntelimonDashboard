box::use(
  DT,
  shiny,
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  shiny$tagList(
    shiny$div(
      style = "text-align:left;",
      shiny$actionLink(
        ns("btn_clear_selection"),
        label = "Clear selection",
        icon = shiny$icon("xmark")
      )
    ),
    DT$DTOutput(
      ns("dt"),
      height = "100%"
    )
  )
}

#' @param id - string. Namespace daisy chains module calls of other modules
#' @param data_reactive - shiny$reactive containing a data.table to be displayed in an interactive chart
#' @param columns - list of column names to display in the data.table
#' @param sort_order - list defining the sorting of the columns based on index.
#'        exp: list(list(2, "asc"), list(0, "asc"), list(1, "asc")))
#' @param col_labels - optional display names for `columns`, in the same order; the column names are
#'        shown when NULL.
#' @return - list with names proxy, containing a proxy of the widget, and input, that contains the input for
#'         the server with the approriate name space.
#' @export
server <- function(id, data_reactive, columns, sort_order, edit_options = FALSE,
                   col_labels = NULL) {
  shiny$moduleServer(id, function(input, output, session) {

    # TRUE once there are rows to show. The table is drawn from isolated data
    # and then updated in place by replaceData() below, but replaceData() can't
    # fill a table that was never drawn (the "No scans to display." message
    # shown when a tab is opened before any data exist). Redrawing whenever
    # this flips covers that; a reactiveVal only invalidates when its value
    # changes, so ordinary edits still go through replaceData().
    has_rows <- shiny$reactiveVal(FALSE)
    shiny$observe({
      has_rows(isTRUE(nrow(data_reactive()) > 0))
    })

    output$dt <- DT$renderDT({
      has_rows()
      data <- shiny$isolate(data_reactive())
      ndata <- nrow(data)
      shiny$validate(
        shiny$need(
          ndata > 0,
          "No scans to display."
        )
      )

      DT$datatable(
        data[, ..columns],
        colnames = if (is.null(col_labels)) columns else col_labels,
        filter = "top",
        rownames = FALSE,
        selection = "multiple",
        editable = edit_options,
        options = list(
          ordering = TRUE,
          paging = FALSE,
          # sort by date, then site w/in each date, then plot w/in each site
          order = sort_order,
          fixedHeader = TRUE,
          # fix order: f = global search box, i = info-text(1of3), t =  table
          dom = "it",
          language = list(
            info = "Rows _START_ - _END_ ",
            infoFiltered = "(filtered from _MAX_ total)"
          )
        )
      ) |>
        (\(tbl) {
          if ("Latitude" %in% columns) {
            DT$formatRound(tbl, columns = c("Latitude", "Longitude"), digits = 3)
          } else {
            tbl
          }
        })()

    })

    proxy <- DT$dataTableProxy(
      "dt",
      session = session
    )

    # ensure that updates use the same column subset and rownames setting
    shiny$observeEvent(data_reactive(), {
      DT$replaceData(proxy, data_reactive()[, ..columns],
                     resetPaging = FALSE, rownames = FALSE, clearSelection = "none")
    }, ignoreInit = TRUE)

    shiny$observeEvent(input$btn_clear_selection, {
      DT$selectRows(proxy, NULL)
    })

    list(
      proxy = proxy,
      input = input
    )
  })
}
