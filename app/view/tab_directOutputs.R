box::use(
  bslib[card_body, card_header, nav_panel],
  gridlayout[grid_card, grid_container, grid_place],
  shiny,
)

box::use(
  app/logic/constants[COLNAME2LABEL],
  app/logic/manage_data[get_display_col],
  app/view/card_metrics,
  app/view/card_points2pano,
  app/view/sidebar_plot_controls[standard_plt_ctrls],
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  nav_panel(
    title = "Standard outputs",
    grid_container(
      layout = c(
        "IntELiMonDSS directOutputs"
      ),
      row_sizes = c(
        "1fr"
      ),
      col_sizes = c(
        "258px",
        "1fr"
      ),
      gap_size = "10px",
      grid_card(
        area = "IntELiMonDSS",
        card_header("Select Statistics"),
        card_body(
          standard_plt_ctrls(ns),
          shiny$selectInput(ns("ui_select_treeStat"),
            "Tree statistics",
            choices = get_display_col(
              c("Basalarea",
                "MDBH",
                "StemsPacre",
                "MeanTH",
                "MaxTH"
              ),
              COLNAME2LABEL
            ),
            selected = "Basalarea"
          ),
          shiny$selectInput(ns("ui_select_volumeStat"), "Volume statistics",
            choices =  get_display_col(
              c("mGCvol",
                "mUSvol",
                "mMSvol",
                "mOSvol"
              ),
              COLNAME2LABEL
            ),
            selected = "mGCvol"
          ),
          shiny$selectInput(ns("ui_select_canopyStat"), "Canopy statistics",
            choices =  get_display_col(
              c("CBH",
                "canopyCover",
                "gapFraction",
                "LAI",
                "OLAI",
                "MLAI",
                "ULAI"
              ),
              COLNAME2LABEL
            ),
            selected = "CBH"
          )
        )
      ),
      grid_card(
        area = "directOutputs",
        grid_container(
          layout = c(
            "treeGridArea   volumeGridArea",
            "canopyGridArea panoGridArea"
          ),
          row_sizes = c("1fr", "1fr"),
          col_sizes = c("1fr", "1fr"),
          gap_size = "10px",
          grid_place(
            area = "treeGridArea",
            card_metrics$ui(ns("treeStats"))
          ),
          grid_place(
            area = "canopyGridArea",
            card_metrics$ui(ns("canopyStats"))
          ),
          grid_place(
            area = "volumeGridArea",
            card_metrics$ui(ns("volumeStats"))
          ),
          grid_place(
            area = "panoGridArea",
            card_points2pano$ui(ns("panoViewer"))
          )
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {

    # -- Metric time-series cards -------------------------------------------
    # Each card is a builder taking `light`: the screen render uses the Aurora
    # palette, the SVG/PNG downloads re-run it light for a white page.

    # make input reactive so that it will update when passed to other module.
    selected_plot_type     <- shiny$reactive(input$ui_select_plot_type)
    selected_data_type     <- shiny$reactive(input$ui_select_data_type)
    btn_errorbars     <- shiny$reactive(input$ui_btn_show_errorbars)
    btn_treaments    <- shiny$reactive(input$ui_btn_show_treatments)

    card_metrics$server("treeStats",
      session,
      data_dt = session$userData$metrics,
      metric_col = shiny$reactive(input$ui_select_treeStat),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    card_metrics$server("canopyStats",
      session,
      data_dt = session$userData$metrics,
      metric_col = shiny$reactive(input$ui_select_canopyStat),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    card_metrics$server("volumeStats",
      session,
      data_dt = session$userData$metrics,
      metric_col = shiny$reactive(input$ui_select_volumeStat),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    # -- Points2Pano viewer --------------------------------------------------
    card_points2pano$server("panoViewer", session)
  })
}
