box::use(
  bslib[card_body, card_header, nav_panel],
  gridlayout[grid_card, grid_container],
  shiny,
  stats[na.omit],
)

box::use(
  app/logic/manage_data[pivot_on_model],
  app/view/card_metrics,
  app/view/card_points2pano,
  app/view/sidebar_plot_controls[standard_plt_ctrls],
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  nav_panel(
    title = "Custom models",
    grid_container(
      layout = c(
        "IntELiMonDSS modelSpace"
      ),
      row_sizes = c(
        "1fr"
      ),
      col_sizes = c(
        "250px",
        "1fr"
      ),
      gap_size = "10px",
      grid_card(
        area = "IntELiMonDSS",
        card_header("Select Models"),
        card_body(
          standard_plt_ctrls(ns),
          #-----Select Model---------------------
          shiny$selectInput(ns("ui_select_modelA"), "Window A available models",
                            choices = list("Load data first" = "")),
          shiny$selectInput(ns("ui_select_modelB"), "Window B available models",
                            choices = list("Load data first" = "")),
          shiny$selectInput(ns("ui_select_modelC"), "Window C available models",
                            choices = list("Load data first" = ""))
        )
      ),
      grid_card(
        area = "modelSpace",
        card_body(
          grid_container(
            layout = c(
              "modelA modelB",
              "modelC panoViewer"
            ),
            row_sizes = c("1fr", "1fr"),
            col_sizes = c("1fr", "1fr"),
            gap_size = "10px",
            grid_card(area = "modelA",
              card_metrics$ui(ns("modelA"))
            ),
            grid_card(area = "modelB",
              card_metrics$ui(ns("modelB"))
            ),
            grid_card(area = "modelC",
              card_metrics$ui(ns("modelC"))
            ),
            grid_card(
              area = "panoViewer",
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

    # Populate the Window A-C dropdowns whenever the more data is imported,
    # staggering defaults so the three cards start on different models.
    shiny$observeEvent(session$userData$extra_models(), {
      x_models <- session$userData$extra_models()

      model_choices <- sort(unique(na.omit(x_models[["model_name"]])))

      if (length(model_choices) == 0) {
        model_choices <- c("No custom models available")
      }

      pick <- function(k) model_choices[min(k, length(model_choices))]
      shiny$updateSelectInput(session, "ui_select_modelA", choices = model_choices, selected = pick(1))
      shiny$updateSelectInput(session, "ui_select_modelB", choices = model_choices, selected = pick(2))
      shiny$updateSelectInput(session, "ui_select_modelC", choices = model_choices, selected = pick(3))
    })

    # make input reactive so that it will update when passed to other module.
    selected_plot_type     <- shiny$reactive(input$ui_select_plot_type)
    selected_data_type     <- shiny$reactive(input$ui_select_data_type)
    btn_errorbars     <- shiny$reactive(input$ui_btn_show_errorbars)
    btn_treaments    <- shiny$reactive(input$ui_btn_show_treatments)

    #---------Model A----------------------------
    dt_a <- shiny$reactive(pivot_on_model(session$userData$extra_models(), input$ui_select_modelA))
    card_metrics$server("modelA",
      session,
      data_dt = dt_a,
      metric_col = shiny$reactive(input$ui_select_modelA),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    #---------Model B----------------------------
    dt_b <- shiny$reactive(pivot_on_model(session$userData$extra_models(), input$ui_select_modelB))
    card_metrics$server("modelB",
      session,
      data_dt = dt_b,
      metric_col = shiny$reactive(input$ui_select_modelB),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    #---------Model C----------------------------
    dt_c <- shiny$reactive(pivot_on_model(session$userData$extra_models(), input$ui_select_modelC))
    card_metrics$server("modelC",
      session,
      data_dt = dt_c,
      metric_col = shiny$reactive(input$ui_select_modelC),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type
    )

    #------Points2Pano---------------------------
    card_points2pano$server("panoViewer", session)

  })
}
