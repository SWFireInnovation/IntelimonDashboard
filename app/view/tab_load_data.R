box::use(
  bslib,
  data.table[rbindlist],
  fs[path_home],
  shiny,
  shinyFiles,
)

box::use(
  app/logic/init_session_userData[init_desktop_user_data],
  app/logic/load_data_dir,
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$nav_panel(
    title = "Load My Data",

    # -- Process .PTX files ------------------------------------------
    bslib$card(
      bslib$card_header("Process .PTX files"),
      shiny$tags$label("1. Select folders:"),
      bslib$layout_columns(
        shinyFiles$shinyDirButton(
          id = ns("ui_btn_dir_ptx"),
          title = "Select folder containing ptx files:",
          label = "Input: new PTX files"
        ),
        shiny$div(
          class = "intelimon-path-display",
          shiny$textOutput(ns("ui_txt_dir_ptx"), inline = TRUE)
        )
      ),
      shiny$tags$div(
        style = "text-align:center; font-size:20px; margin:4px 0;",
        "\u2193" # ↓
      ),
      bslib$layout_columns(
        shinyFiles$shinyDirButton(
          id = ns("ui_btn_dir_metrics_write"),
          title = "Select folder to save IntELiMon metrics:",
          label = "Output: IntELiMon metrics"
        ),
        shiny$div(
          class = "intelimon-path-display",
          shiny$textOutput(ns("ui_txt_dir_metrics_write"), inline = TRUE)
        )
      ),
      shiny$h6("2. Calculate metrics:"),
      shiny$actionButton(ns("ui_btn_run_intelimon"), "Run IntELiMon", class = "btn-primary"),
      shiny$tags$div(
        style = "text-align:center; font-size:20px; margin:4px 0;",
        "\u2193" # ↓
      ),
      shiny$actionButton(ns("ui_btn_run_points2pano"), "Run Points2Pano", class = "btn-primary"),
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
      shiny$h6("Map plot locations (optional): Choose 1"),
      bslib$layout_columns(
        shiny$actionButton(ns("ui_btn_load_dwnld_latlong"),
          "From IntELiMon download files",
          class = "btn-primary"
        ),
        shinyFiles$shinyFilesButton(
          id = ns("ui_btn_load_file_latlng"),
          title = "Select .kmz file:",
          label = "From my .kmz",
          multiple = FALSE
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {

    # shinyFiles$shinyDirChoose must be re-registered whenver roots changes
    # i.e. if a thumb drive is plugged in or unplugged.
    register_shinyDirChooser <- function(id, rts, default_rt = NULL) { # nolint: object_name_linter
      shinyFiles$shinyDirChoose(
        input,
        id,
        session = session,
        roots = rts,
        defaultRoot = default_rt,
        allowDirCreate = FALSE
      )
    }

    get_roots <- function() {
      c(Home = as.character(path_home()), shinyFiles$getVolumes()())
    }
    roots <- shiny$reactiveVal(get_roots())

    # check if any new drives have been plugged/unplugged when opening each pop-up window
    shiny$observeEvent({
      input$ui_btn_dir_ptx
      input$ui_btn_dir_metrics_write
      input$ui_btn_dir_metrics_read
    },
    {
      new_roots <- get_roots()
      if (!identical(names(new_roots), names(roots()))) {
        roots(new_roots)
      }
    })

    # -- Process .PTX files ------------------------------------------
    # if the root drive list has changed, re-initialize the shinyDirChooser
    shiny$observe({
      new_root <- roots()
      register_shinyDirChooser("ui_btn_dir_ptx", new_root, default_rt = NULL)
      register_shinyDirChooser("ui_btn_dir_metrics_write", new_root, default_rt = NULL)
    })

    dir_ptx <- shiny$reactive({
                               shinyFiles$parseDirPath(roots(), input$ui_btn_dir_ptx)})
    output$ui_txt_dir_ptx <- shiny$renderText({
                                               dir_ptx()})

    dir_metrics_write <- shiny$reactive({
                                         shinyFiles$parseDirPath(roots(), input$ui_btn_dir_metrics_write)})
    output$ui_txt_dir_metrics_write <- shiny$renderText({
                                                         dir_metrics_write()})

    # -- Upload metrics ------------------------------------------
    # if the root drive list has changed or a new metrics output folder is chosen:
    # re-initialize the shinyDirChooser
    dir_metric_roots <- shiny$reactiveVal()
    shiny$observe({
      dir_metrics_w <- dir_metrics_write()
      rt <- roots()
      has_write_dir <- "fs_path" %in% class(dir_metrics_w)

      if (has_write_dir) {
        new_rts <- c(metrics_output = dir_metrics_w, rt)
      } else {
        new_rts <- c(metrics_output = rt[[1]], rt)
      }

      register_shinyDirChooser("ui_btn_dir_metrics_read",
                               new_rts,
                               default_rt = if (has_write_dir) "metrics_output" else rt[[1]])

      dir_metric_roots(new_rts)
    })

    dir_metrics_read <- shiny$reactive({
                                        shinyFiles$parseDirPath(dir_metric_roots(),
                                                                input$ui_btn_dir_metrics_read)})

    shiny$observeEvent(dir_metrics_read(), {
      shiny$req(dir_metrics_read())
      read_dir <- dir_metrics_read()

      init_desktop_user_data(session)
      session$userData$data_paths(load_data_dir$get_dir_contents(read_dir))

      local_dt <- load_data_dir$build_scan_dt(session$userData$data_paths())
      api_dt <- session$userData$all_scans()

      new_dt <- local_dt[!api_dt, on = .(site, plot, date, scanner_id, Agency)]
      combined_dt <- rbindlist(list(new_dt, api_dt), fill = TRUE)
      session$userData$all_scans(combined_dt)
    })
  })
}
