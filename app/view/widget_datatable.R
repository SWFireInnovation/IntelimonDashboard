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
#' @return - list with names proxy, containing a proxy of the widget, and input, that contains the input for
#'         the server with the approriate name space.
#' @export
server <- function(id, data_reactive, columns, sort_order, edit_options = FALSE) {
  shiny$moduleServer(id, function(input, output, session) {

    output$dt <- DT$renderDT({
      data <- data_reactive()
      ndata <- nrow(data)
      shiny$validate(
        shiny$need(
          ndata > 0,
          "No scans to display."
        )
      )

      DT$datatable(
        data[, ..columns],
        filter = "top",
        rownames = FALSE,
        selection = "multiple",
        editable = edit_options,
        options = list(
          pageLength = 50,
          ordering = TRUE,
          paging = FALSE,
          # sort by date, then site w/in each date, then plot w/in each site
          order = sort_order
        )
      )
    })

    proxy <- DT$dataTableProxy(
      "dt",
      session = session
    )

    shiny$observeEvent(input$btn_clear_selection, {
      DT$selectRows(proxy, NULL)
    })

    list(
      proxy = proxy,
      input = input
    )
  })
}
