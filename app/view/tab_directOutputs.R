box::use(
  bslib[card_body, card_header, nav_panel],
  gridlayout[grid_card, grid_card_plot, grid_container],
  shiny,
)

box::use(
  plt = app/logic/plotting
)

# Points2Pano iframe crop (pixels). The burnpro3d page is cross-origin, so
# its own UI (header, bottom nav bar, side arrows) can't be restyled from
# this app; instead the iframe is oversized and shifted so those strips are
# clipped out of view. Set all to 0 for the full page.
PANO_CROP_TOP    <- 70   # px of the pano page's top header to hide
PANO_CROP_BOTTOM <- 90   # px of the pano page's bottom nav bar to hide
PANO_CROP_LEFT   <- 60   # px of the left edge (side arrow) to hide
PANO_CROP_RIGHT  <- 60   # px of the right edge (side arrow) to hide


# Y-axis labels for the volume metrics
VOLUME_METRIC_LABELS <- c(
  mGCvol = "Ground cover volume (mGCvol)",
  mUSvol = "Understory volume (mUSvol)",
  mMSvol = "Midstory volume (mMSvol)",
  mOSvol = "Overstory volume (mOSvol)"
)

# Y-axis labels for the tree metrics
TREE_METRIC_LABELS <- c(
  Basalarea  = "Basal area (Basalarea)",
  MDBH       = "Mean DBH (MDBH)",
  StemsPacre = "Stems per acre (StemsPacre)",
  TreesN     = "Number of trees (TreesN)",
  MeanTH     = "Mean tree height (MeanTH)",
  MaxTH      = "Maximum tree height (MaxTH)"
)

# Y-axis labels for the canopy metrics
CANOPY_METRIC_LABELS <- c(
  CBH         = "Canopy base height (CBH)",
  canopyCover = "Canopy cover (canopyCover)",
  gapFraction = "Gap fraction (1 - canopyCover)",
  LAI         = "Leaf area index (LAI)",
  OLAI        = "Overstory LAI (OLAI)",
  MLAI        = "Midstory LAI (MLAI)",
  ULAI        = "Understory LAI (ULAI)"
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
          shiny$selectInput(ns("plot_mode"), "Plot type",
            choices = list(
              "Time series" = "timeseries",
              "Time series individual plot" = "individual",
              "Box and Whisker" = "boxplot",
              "Bar" = "bar"
            ),
            selected = "timeseries", width = "100%"
          ),
          shiny$selectInput(ns("data_type"), "Data type",
            choices = list(
              "Raw data"       = "raw",
              "Percent change" = "percent"
            ),
            selected = "raw", width = "100%"
          ),
          shiny$radioButtons(ns("show_treatments"), "Treatment date lines",
            choices = list("On" = "on", "Off" = "off"),
            selected = "on", inline = TRUE, width = "100%"
          ),
          shiny$radioButtons(ns("show_errorbars"), "Error bars",
            choices = list("On" = "on", "Off" = "off"),
            selected = "on", inline = TRUE, width = "100%"
          ),
          shiny$selectInput(ns("treeStatistics"), "Tree statistics",
            choices = list(
              "Basal area"          = "Basalarea",
              "Mean DBH"            = "MDBH",
              "Stems per acre"      = "StemsPacre",
              "Number of trees"     = "TreesN",
              "Mean tree height"    = "MeanTH",
              "Maximum tree height" = "MaxTH"
            ),
            selected = "Basalarea"
          ),
          shiny$selectInput(ns("volumeStatistics"), "Volume statistics",
            choices = list(
              "Ground cover volume" = "mGCvol",
              "Understory volume"   = "mUSvol",
              "Midstory volume"     = "mMSvol",
              "Overstory volume"    = "mOSvol"
            ),
            selected = "mGCvol"
          ),
          shiny$selectInput(ns("canopyStatistics"), "Canopy statistics",
            choices = list(
              "Canopy base height" = "CBH",
              "Canopy cover"       = "canopyCover",
              "Gap fraction"       = "gapFraction",
              "Leaf area index"    = "LAI",
              "Overstory LAI"      = "OLAI",
              "Midstory LAI"       = "MLAI",
              "Understory LAI"     = "ULAI"
            ),
            selected = "CBH"
          )
        )
      ),
      grid_card(
        area = "directOutputs",
        grid_container(
          layout = c(
            "treeStats   volumeStats",
            "canopyStats panoViewer "
          ),
          row_sizes = c("1fr", "1fr"),
          col_sizes = c("1fr", "1fr"),
          gap_size = "10px",
          grid_card(
            area = "treeStats", full_screen = TRUE,
            card_body(plt$plot_card_ui(ns, "treeStats"))
          ),
          grid_card(
            area = "canopyStats", full_screen = TRUE,
            card_body(plt$plot_card_ui(ns, "canopyStats"))
          ),
          grid_card(
            area = "volumeStats", full_screen = TRUE,
            card_body(plt$plot_card_ui(ns, "volumeStats"))
          ),
          grid_card(
            area = "panoViewer",
            full_screen = TRUE,
            card_header(
              class = "d-flex justify-content-between align-items-center",
              shiny$span("Points2Pano"),
              shiny$div(
                class = "d-flex align-items-center gap-2",
                shiny$actionButton(ns("btn_pano_prev"), "\u25C0", class = "btn-sm"),
                shiny$div(
                  class = "pano-info",
                  shiny$textOutput(ns("pano_label"), inline = TRUE)
                ),
               shiny$actionButton(ns("btn_pano_next"), "\u25B6", class = "btn-sm")
              )
            ),
            card_body(
              padding = 0,
              shiny$uiOutput(ns("pano_frame"), style = "height: 100%;")
            )
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
    metric_card <- function(session, id, input_id, labels, prefix) {
      plot_fn <- function(light = FALSE) {
        key <- input[[input_id]]

        plt$metric_series_plot(key, labels[[key]], session$userData$metrics(),
          session$userData$trtmt_dates(),
          input$show_errorbars, input$show_treatments,
          input$plot_mode, input$data_type,
          light = light
        )
      }
      stats_fn <- function() {
        key <- input[[input_id]]
        plt$metric_series_stats(
          key, labels[[key]], session$userData$metrics(),
          session$userData$trtmt_dates(), input$data_type
        )
      }
      output[[id]] <- shiny$renderPlot(
        plot_fn(),
        bg = "transparent",
        res = 110)
      plt$register_plot_download(output, id, plot_fn, prefix)
      plt$register_plot_stats(output, id, stats_fn)
    }

    metric_card(session, "treeStats", "treeStatistics", TREE_METRIC_LABELS, "tree_stats")
    metric_card(session, "volumeStats", "volumeStatistics", VOLUME_METRIC_LABELS, "volume_stats")
    metric_card(session, "canopyStats", "canopyStatistics", CANOPY_METRIC_LABELS, "canopy_stats")


    # -- Points2Pano viewer --------------------------------------------------
    pano_idx <- shiny$reactiveVal(1)

    # Populated scans available to the viewer (in scan_calls order)
    pano_scans <- shiny$reactive({
      sc <- session$userData$scan_selection()
      sc[nzchar(date)]
    })


    # Reset to the first record whenever scan_calls changes
    shiny$observeEvent(session$userData$scan_selection(), {
      pano_idx(1)
    })

    shiny$observeEvent(input$btn_pano_prev, {
      n <- nrow(pano_scans())
      if (n == 0) {
        return()
      }
      pano_idx(if (pano_idx() <= 1) n else pano_idx() - 1) # wrap
    })

    shiny$observeEvent(input$btn_pano_next, {
      n <- nrow(pano_scans())
      if (n == 0) {
        return()
      }
      pano_idx(if (pano_idx() >= n) 1 else pano_idx() + 1) # wrap
    })

    output$pano_label <- shiny$renderText({
      df <- pano_scans()
      if (nrow(df) == 0) {
        return("No scans loaded")
      }

      row <- df[min(pano_idx(), nrow(df))]
      date_fmt <- row$date

      sprintf(
        "Site: %s | Plot: %s | %s | Scanner: %s",
        row$site, row$plot, date_fmt, row$scanner_id
      )
    })

    output$pano_frame <- shiny$renderUI({
      df <- pano_scans()

      if (nrow(df) == 0) {
        return(shiny$div(
          style = "display:flex; align-items:center; justify-content:center;
                   height:100%; color:#888; text-align:center; padding:20px;",
          "No scans loaded - select plots on the Selection Map tab and press Get Scans."
        ))
      }

      idx <- min(pano_idx(), nrow(df))
      row <- df[idx]

      pano_url <- sprintf(
        "https://burnpro3d.sdsc.edu/points2pano/?plot=%s_%s&ts=%s&m=Basalarea",
        row$site, row$plot, format(row$date, "%Y%m%d")
      )

      shiny$div(
        style = "width:100%; height:100%; overflow:hidden; position:relative;",
        shiny$tags$iframe(
          src = pano_url,
          style = sprintf(
            "position:absolute; top:-%dpx; left:-%dpx;
             width:calc(100%% + %dpx); height:calc(100%% + %dpx); border:none;",
            PANO_CROP_TOP, PANO_CROP_LEFT,
            PANO_CROP_LEFT + PANO_CROP_RIGHT,
            PANO_CROP_TOP + PANO_CROP_BOTTOM
          ),
          title = paste("Points2Pano:", row$scan_name)
        )
      )
    })
  })
}
