box::use(
  bslib[card_body, card_header, nav_panel],
  gridlayout[grid_card, grid_container, grid_place],
  shiny,
  stats[na.omit],
)

box::use(
  app/logic/constants[COLNAME2LABEL],
  app/logic/manage_data[get_display_col, pivot_on_model],
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
            grid_place(area = "modelA",
              card_metrics$ui(ns("modelA"))
            ),
            grid_place(area = "modelB",
              card_metrics$ui(ns("modelB"))
            ),
            grid_place(area = "modelC",
              card_metrics$ui(ns("modelC"))
            ),
            grid_place(
              area = "panoViewer",
              card_points2pano$ui(ns("panoViewer"))
            )
          )
        )
      )
    )
  )
}

# Shown on the cards when none of the loaded scans has custom model outputs.
NO_MODELS_MSG <- paste(
  "No custom models were run on the loaded scans. Custom models exist only for",
  "sites with a model calibrated from field data; see Help."
)

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
      choices_display <- get_display_col(model_choices, COLNAME2LABEL)
      shiny$updateSelectInput(session, "ui_select_modelA", choices = choices_display, selected = pick(1))
      shiny$updateSelectInput(session, "ui_select_modelB", choices = choices_display, selected = pick(2))
      shiny$updateSelectInput(session, "ui_select_modelC", choices = choices_display, selected = pick(3))
    })

    # make input reactive so that it will update when passed to other module.
    selected_plot_type     <- shiny$reactive(input$ui_select_plot_type)
    selected_data_type     <- shiny$reactive(input$ui_select_data_type)
    btn_errorbars     <- shiny$reactive(input$ui_btn_show_errorbars)
    btn_treaments    <- shiny$reactive(input$ui_btn_show_treatments)

    # One model's values per scan for a card. With scans loaded but no models
    # run on them, the card says so rather than asking for data to be loaded.
    model_data <- function(model) {
      shiny$reactive({
        models <- session$userData$extra_models()
        shiny$validate(
          shiny$need(
            nrow(session$userData$metrics()) > 0,
            "No data loaded - press Get Data on the Selection Map tab."
          ),
          shiny$need(nrow(models) > 0, NO_MODELS_MSG)
        )
        pivot_on_model(models, model())
      })
    }

    #---------Model A----------------------------
    dt_a <- model_data(shiny$reactive(input$ui_select_modelA))
    card_metrics$server("modelA",
      session,
      data_dt = dt_a,
      metric_col = shiny$reactive(input$ui_select_modelA),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type,
      report_source = "Custom models"
    )

    #---------Model B----------------------------
    dt_b <- model_data(shiny$reactive(input$ui_select_modelB))
    card_metrics$server("modelB",
      session,
      data_dt = dt_b,
      metric_col = shiny$reactive(input$ui_select_modelB),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type,
      report_source = "Custom models"
    )

    #---------Model C----------------------------
    dt_c <- model_data(shiny$reactive(input$ui_select_modelC))
    card_metrics$server("modelC",
      session,
      data_dt = dt_c,
      metric_col = shiny$reactive(input$ui_select_modelC),
      errorbars_on = btn_errorbars,
      treatlines_on = btn_treaments,
      plot_type = selected_plot_type,
      data_type = selected_data_type,
      report_source = "Custom models"
    )

    #------Points2Pano---------------------------
    card_points2pano$server("panoViewer", session)

  })
}
