box::use(
  bslib,
  shiny,
  shinyFiles,
)

box::use(
  app/logic/load_data_dir[get_data_path],
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$nav_panel(
    title = "Load My Data",

    # -- Process .PTX files ------------------------------------------
    bslib$card(
      bslib$card_header("Process .PTX files"),
      shiny$tags$label("Select folders:"),
      bslib$layout_columns(
        shinyFiles$shinyDirButton(
          id = ns("ui_btn_dir_ptx"),
          title = "Select folder containing ptx files:",
          label = "Input: new PTX files"
        ),
        shiny$div(
          class = "intelimon-path-display",
          shiny$textOutput(ns("ui_txt_dir_ptx"), inline = TRUE),
        )
      ),
      bslib$layout_columns(
        shinyFiles$shinyDirButton(
          id = ns("ui_btn_dir_metrics_write"),
          title = "Select folder to save IntELiMon metrics:",
          label = "Output: IntELiMon metrics"
        ),
        shiny$div(
          class = "intelimon-path-display",
          shiny$textOutput(ns("ui_txt_dir_metrics_write"), inline = TRUE),
        )
      ),
      shiny$h6("Calculate metrics:"),
      shiny$actionButton(ns("ui_btn_run_intelimon"), "Run IntELiMon", class = "btn-primary"),
      shiny$helpText("Calculate IntELiMon metrics from TLS point clouds.")
    ),
    # -- Upload files ------------------------------------------
    bslib$card(
      bslib$card_header("Load IntELiMon data"),
      bslib$card_footer("Select folder:"),
      shinyFiles$shinyDirButton(
        id = ns("ui_btn_dir_metrics_read"),
        title = "Select folder containing IntELiMon metrics:",
        label = "Load IntELiMon metrics"
      ),
      bslib$card_footer("Map points (optional)"),
      shinyFiles$shinyFilesButton(
        id = ns("ui_btn_load_pts"),
        title = "Select .kmz file:",
        label = "Get plot locations",
        multiple = FALSE
      )
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {
    roots <- shinyFiles$getVolumes()()

    # -- Process .PTX files ------------------------------------------
    shinyFiles$shinyDirChoose(
      input,
      "ui_btn_dir_ptx",
      session = session,
      roots = roots,
      allowDirCreate = FALSE
    )
    dir_ptx <- shiny$reactive({shinyFiles$parseDirPath(roots, input$ui_btn_dir_ptx)})
    output$ui_txt_dir_ptx <- shiny$renderText({dir_ptx()})

    shinyFiles$shinyDirChoose(
      input,
      "ui_btn_dir_metrics_write",
      session = session,
      roots = roots,
      allowDirCreate = FALSE
    )
    dir_metrics_write <- shiny$reactive({shinyFiles$parseDirPath(roots, input$ui_btn_dir_metrics_write)})
    output$ui_txt_dir_metrics_write <- shiny$renderText({dir_metrics_write()})

    # -- Upload metrics ------------------------------------------
    shiny$observeEvent({input$ui_btn_dir_metrics_read
                       dir_metrics_write()}, {
      shinyFiles$shinyDirChoose(
        input,
        "ui_btn_dir_metrics_read",
        session = session,
        roots = c(metrics = dir_metrics_write(), roots),
        allowDirCreate = FALSE
      )
    })
    dir_metrics_read <- shiny$reactive({shinyFiles$parseDirPath(roots, input$ui_btn_dir_metrics_read)})
  })
}
