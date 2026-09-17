box::use(
  bslib,
  shiny,
)

box::use(
  app/logic/constants[COLNAME2LABEL],
  plt = app/view/plotting,
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$card(
    full_screen = TRUE,
    bslib$card_body(plt$plot_card_ui(ns("plot")),
      min_height = 150
    )
  )
}

#' @param id module id - must match the id `ui()` was called with.
#' @param session active user server sesion pased to all modules
#' @param metric_col reactive() -> selected metric column, e.g. "MDBH".
#' @param errorbars_on,treatlines_on,plot_mode,data_type reactive() -> the
#'   matching sidebar control's current value.
#' @export
server <- function(id, session, data_dt, metric_col, errorbars_on, treatlines_on, plot_type, data_type) {
  shiny$moduleServer(id, function(input, output, session) {
    # -- Metric time-series cards -------------------------------------------
    # Each card is a builder taking `light`: the screen render uses the Aurora
    # palette, the SVG/PNG downloads re-run it light for a white page.

    #-----------Selected Options/Data------------
    # capture current state of options and data selected
    plt_options <- shiny$reactive({
      list(
        errorbars    = errorbars_on(),
        treatlines   = treatlines_on(),
        plot_type    = plot_type()
      )
    })

    data_state <- shiny$reactive({
      col <- metric_col()
      label <- tryCatch(
        COLNAME2LABEL[[col]],
        error = function(e) {
          col
        }
      )

      list(
        metric       = col,
        label        = if (is.null(label) || is.na(label)) col else label,
        data_type    = data_type(),
        data_dt      = data_dt(),
        trtmt_dates  = session$userData$trtmt_dates()
      )
    })

    #--------ggplot Builder for current state----
    plt_fn <- function(light = FALSE) {
      plt$metric_series_plot(data_state(), plt_options(), light)
    }

    output$plot <- shiny$renderPlot(
                                    plt_fn(light  = FALSE),
                                    bg = "transparent",
                                    res = 110)
    # the downloads must be able to remake the plot with a different background to before they save
    plt$register_plot_download(output, "plot", plt_fn, id)

    #------Stats table builder for data state----
    # create stats table
    stats_dt <- shiny$reactive({
                                plt$metric_series_stats(data_state()) })
    # the output stats are created reactively. Pass the reactiveObject, not the data.table,
    # so it can render reactively(dynamically)
    plt$render_plot_stats(output, "plot", stats_dt)
  })
}
