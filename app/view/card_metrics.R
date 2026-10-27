box::use(
  bslib,
  shiny,
)

box::use(
  app/logic/constants[COLNAME2LABEL],
  app/logic/report[report_item],
  app/logic/report_analysis[describe_series],
  plt = app/view/plotting,
  app/view/report_store[add_to_report, plot_thumbnail],
  app/view/sidebar_plot_controls[DATA_TYPES, ERROR_BARS, PLOT_TYPES, choice_label],
)

# Subheading of a graph in the report, under its metric's heading.
PLOT_SUBHEADINGS <- list(
  timeseries = "Time series plot",
  individual = "Individual plot time series",
  boxplot = "Box and Whisker plot",
  bar = "Bar chart"
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
#' @param report_source Tab name recorded with items this card adds to the report.
#' @param report_settings reactive() -> named list of extra settings recorded
#'   with report items (e.g. the rothRmel fire behavior inputs).
#' @param report_methods reactive() -> keys of METHODS (app/logic/report.R)
#'   behind the card's values, explained in any report holding its items.
#' @export
server <- function(id, session, data_dt, metric_col, errorbars_on, treatlines_on, plot_type,
                   data_type, report_source = "", report_settings = function() list(),
                   report_methods = function() character()) {
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
        trtmt_dates  = session$userData$trtmt_dates(),
        scan_groups  = session$userData$scan_selection()
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

    #------Add to report-------------------------
    # Adds whichever view the card is showing, with the settings behind it:
    # the plot (on the light export palette) or the statistics table.
    # The automated description is built from the same per-scan rows and time
    # steps the card draws (see app/logic/report_analysis.R).
    describe_card <- function() {
      st <- data_state()
      prep <- plt$.series_prep(st$metric, st$label, st$data_dt, st$trtmt_dates, st$data_type,
                               st$scan_groups)
      describe_series(prep$raw, prep$y_label, prep$pct, st$trtmt_dates$TreatmentDate, st$metric)
    }

    shiny$observeEvent(input$plot_add_report, {
      opts <- plt_options()
      data_label <- choice_label(DATA_TYPES, data_type())
      analysis <- tryCatch(describe_card(), error = function(e) NULL)
      item <- tryCatch(
        if (identical(input$plot_view, "stats")) {
          tbl <- stats_dt()
          report_item("table", attr(tbl, "imn_label"), report_source,
            settings = c(list(`Data type` = data_label), report_settings()),
            table = tbl, note = plt$STATS_NOTE, analysis = analysis,
            subheading = "Statistics", methods = report_methods()
          )
        } else {
          p <- plt_fn(light = TRUE)
          bars <- if (opts$plot_type %in% c("timeseries", "bar")) {
            choice_label(ERROR_BARS, opts$errorbars)
          }
          report_item("figure", p$labels$title, report_source,
            settings = c(
              list(
                `Plot type` = choice_label(PLOT_TYPES, opts$plot_type),
                `Data type` = data_label,
                `Error bars` = bars,
                `Treatment lines` = if (identical(opts$treatlines, "on")) "On" else "Off"
              ),
              report_settings()
            ),
            plot = p, analysis = analysis,
            subheading = PLOT_SUBHEADINGS[[opts$plot_type]], thumb = plot_thumbnail(p),
            methods = report_methods()
          )
        },
        error = function(e) NULL
      )
      if (is.null(item)) {
        shiny$showNotification("Nothing to add yet: this card has no data to show.",
                               type = "warning")
        return()
      }
      add_to_report(session, item)
    })
  })
}
