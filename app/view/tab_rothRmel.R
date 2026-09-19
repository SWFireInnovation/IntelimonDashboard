# app/view/tab_rothRmel.R
# ---------------------------------------------------------------------------
# rothRmel tab. Enter winds / fuel moistures / canopy assumptions in the
# sidebar; three plot cards graph a chosen fire-behavior metric over scan
# date, and the fourth card is the Points2Pano viewer. Fire behavior
# (Rothermel surface + Van Wagner crown) is computed per scan from the loaded
# metrics + the wide additional-models table, so treatment-driven changes in
# fuel and canopy structure show up as trends over time.
#
# Ported from the standalone IntELiMon DST.
# ---------------------------------------------------------------------------
box::use(
  bslib[card_body, card_header, nav_panel],
  gridlayout[grid_card, grid_container, grid_place],
  shiny,
)

box::use(
  app/logic/fire_behavior[scan_fire_behavior],
  app/logic/manage_data[pivot_on_model],
  app/view/card_metrics,
  app/view/card_points2pano,
  app/view/sidebar_plot_controls[standard_plt_ctrls],
)

# Choices for the three metric dropdowns, grouped surface vs crown.
metric_choices <- list(
  "Surface fire" = list(
    "Rate of spread (ch/hr)"           = "ros_ch_hr",
    "Rate of spread (m/min)"           = "ros_m_min",
    "Fireline intensity (kW/m)"        = "fli_kw_m",
    "Flame length (ft)"                = "flame_ft",
    "Flame length (m)"                 = "flame_m",
    "Reaction intensity (BTU/ft2/min)" = "rxn_int",
    "Heat per unit area (BTU/ft2)"     = "hpa"
  ),
  "Crown fire" = list(
    "Crown-initiation intensity Io (kW/m)" = "crown_Io",
    "Critical active-crown ROS Ro (m/min)" = "crown_Ro",
    "Torching index (mph)"                 = "torching_idx",
    "Crowning index (mph)"                 = "crowning_idx",
    "Crown fire type (0/1/2)"              = "fire_type_num"
  )
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  nav_panel(
    title = "rothRmel",
    grid_container(
      layout = c("IntELiMonDSS rothSpace"),
      row_sizes = c("1fr"),
      col_sizes = c("264px", "1fr"),
      gap_size = "10px",
      grid_card(
        area = "IntELiMonDSS",
        card_header("Fire behavior inputs"),
        card_body(
          style = "overflow-y: auto;",
          shiny$radioButtons(ns("fuel_src"), "Surface fuel source",
            choices = list(
              "Scan level fuels" = "scan",
              "Fuel tool values" = "tool"
            ),
            selected = "scan", width = "100%"
          ),
          shiny$uiOutput(ns("fuel_src_note")),
          shiny$tags$hr(style = "margin:6px 0;"),
          standard_plt_ctrls(ns),
          shiny$tags$hr(style = "margin:6px 0;"),
          shiny$selectInput(ns("ui_select_metric_1"), "Card 1 metric",
            choices = metric_choices, selected = "ros_ch_hr"
          ),
          shiny$selectInput(ns("ui_select_metric_2"), "Card 2 metric",
            choices = metric_choices, selected = "fli_kw_m"
          ),
          shiny$selectInput(ns("ui_select_metric_3"), "Card 3 metric",
            choices = metric_choices, selected = "torching_idx"
          ),
          shiny$tags$hr(style = "margin:6px 0;"),
          shiny$tags$strong("Wind & slope"),
          shiny$numericInput(ns("wind_mph"), "20-ft wind speed (mi/h)",
            value = 10, min = 0, max = 100, step = 1
          ),
          shiny$numericInput(ns("waf"), "Wind adjustment factor (midflame)",
            value = 0.3, min = 0.05, max = 1, step = 0.05
          ),
          shiny$numericInput(ns("slope_pct"), "Slope (%)",
            value = 0, min = 0, max = 200, step = 5
          ),
          shiny$tags$hr(style = "margin:6px 0;"),
          shiny$tags$strong("Dead fuel moisture (%)"),
          shiny$numericInput(ns("m1"), "1-hour", value = 6, min = 1, max = 60, step = 1),
          shiny$numericInput(ns("m10"), "10-hour", value = 7, min = 1, max = 60, step = 1),
          shiny$numericInput(ns("m100"), "100-hour", value = 8, min = 1, max = 60, step = 1),
          shiny$numericInput(ns("mx_dead"), "Dead moisture of extinction",
            value = 25, min = 10, max = 60, step = 1
          ),
          shiny$tags$hr(style = "margin:6px 0;"),
          shiny$tags$strong("Live fuel"),
          shiny$numericInput(ns("m_herb"), "Herbaceous moisture (%)",
            value = 90, min = 30, max = 300, step = 10
          ),
          shiny$numericInput(ns("m_woody"), "Woody moisture (%)",
            value = 90, min = 30, max = 300, step = 10
          ),
          shiny$numericInput(ns("live_herb_load"), "Herbaceous load (tons/acre)",
            value = 0, min = 0, max = 10, step = 0.1
          ),
          shiny$numericInput(ns("live_woody_load"), "Woody load (tons/acre)",
            value = 0, min = 0, max = 10, step = 0.1
          ),
          shiny$tags$hr(style = "margin:6px 0;"),
          shiny$tags$strong("Canopy"),
          shiny$numericInput(ns("fmc"), "Foliar moisture content (%)",
            value = 100, min = 60, max = 200, step = 10
          ),
          shiny$helpText(
            style = "font-size:11px;",
            "Surface: Rothermel (1972) + Byram. Crown: Van Wagner (1977) with ",
            "Rothermel (1991) crown spread. Dead loads and fuel-bed depth come ",
            "from each scan; live loads and weather are held constant across ",
            "scans. Validate against BehavePlus before operational use."
          )
        )
      ),
      grid_card(
        area = "rothSpace",
        card_body(
          grid_container(
            layout = c(
              "card1GridArea card2GridArea",
              "card3GridArea panoGridArea"
            ),
            row_sizes = c("1fr", "1fr"),
            col_sizes = c("1fr", "1fr"),
            gap_size = "10px",
            grid_place(
              area = "card1GridArea",
              card_metrics$ui(ns("card1"))
            ),
            grid_place(
              area = "card2GridArea",
              card_metrics$ui(ns("card2"))
            ),
            grid_place(
              area = "card3GridArea",
              card_metrics$ui(ns("card3"))
            ),
            grid_place(
              area = "panoGridArea",
              card_points2pano$ui(ns("panoViewer"))
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
    # -- Fire behavior table (recomputes when data or any input changes) -----
    env <- shiny$reactive({
      bed <- if (identical(input$fuel_src, "tool")) {
        session$userData$fuel_tool_values()
      } else {
        NULL
      }
      list(
        bed             = bed,
        wind_mph        = input$wind_mph,
        waf             = input$waf,
        slope_pct       = input$slope_pct,
        m1              = input$m1,
        m10             = input$m10,
        m100            = input$m100,
        mx_dead         = input$mx_dead,
        m_herb          = input$m_herb,
        m_woody         = input$m_woody,
        live_herb_load  = input$live_herb_load,
        live_woody_load = input$live_woody_load,
        fmc             = input$fmc
      )
    })

    fire_behavior <- shiny$reactive({
      shiny$validate(shiny$need(
        nrow(session$userData$metrics()) > 0,
        "No data loaded - press Get Data on the Selection Map tab."
      ))
      if (identical(input$fuel_src, "tool")) {
        shiny$validate(shiny$need(
          !is.null(session$userData$fuel_tool_values()),
          paste(
            "No fuel values submitted yet - set them on the Fuels exports tab",
            "and press Submit fuel values, or switch back to scan level fuels."
          )
        ))
      }
      scan_fire_behavior(session$userData$metrics(), pivot_on_model(session$userData$extra_models()), env())
    })

    output$fuel_src_note <- shiny$renderUI({
      b <- session$userData$fuel_tool_values()
      if (identical(input$fuel_src, "scan")) {
        return(shiny$div(
          class = "imn-fnote",
          paste(
            "Surface fuels come from each scan's Brown time-lag",
            "loads and fuel bed depth."
          )
        ))
      }
      if (is.null(b)) {
        return(shiny$div(
          class = "imn-sim-warn", shiny$tags$b("Nothing submitted. "),
          "Set values on the Fuels exports tab and press Submit fuel values."
        ))
      }
      shiny$div(
        class = "imn-okbox",
        shiny$tags$b(b$label), shiny$tags$br(),
        sprintf("%s · %s", b$system, b$aggregation), shiny$tags$br(),
        shiny$tags$span(
          style = "color:var(--imn-dim)",
          "Surface fuels held constant across scans; canopy still per-scan."
        )
      )
    })

    # One card renderer bound to a metric-dropdown input id. `light` switches
    # the palette for the SVG/PNG downloads (white page instead of glass card).
    # make input reactive so that it will update when passed to other module.
    selected_plot_type     <- shiny$reactive(input$ui_select_plot_type)
    selected_data_type     <- shiny$reactive(input$ui_select_data_type)
    btn_errorbars     <- shiny$reactive(input$ui_btn_show_errorbars)
    btn_treaments    <- shiny$reactive(input$ui_btn_show_treatments)

    card_metrics$server("card1",
      session,
      data_dt = fire_behavior,
      metric_col = shiny$reactive(input$ui_select_metric_1),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    card_metrics$server("card2",
      session,
      data_dt = fire_behavior,
      metric_col = shiny$reactive(input$ui_select_metric_2),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    card_metrics$server("card3",
      session,
      data_dt = fire_behavior,
      metric_col = shiny$reactive(input$ui_select_metric_3),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    # -- Points2Pano viewer --------------------------------------------------
    card_points2pano$server("panoViewer", session)
  })
}
