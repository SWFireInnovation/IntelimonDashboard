box::use(
  DT[selectRows, replaceData],
  bslib[card_body, card_header, nav_panel, navset_pill],
  data.table[data.table, fsetequal, rbindlist],
  grDevices[hcl.colors],
  gridlayout[grid_card, grid_container],
  leaflet,
  shiny,
)

box::use(
  api = app/logic/load_data_api,
  disk = app/logic/load_data_dir,
  app/logic/manage_data[get_scans4dwnld, is_data_on_disk, set_remeas_by_yr],
  app/logic/map_fnc[parse_click_id],
  app/view/map_controls[map_scan_points,
                        update_dwnld_scan_points,
                        update_point_labels,
                        update_selected_scan_points],
  wDT = app/view/widget_datatable,
  app/view/widget_mapLeaflet,
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  nav_panel(
    title = "Selection Map",
    grid_container(
      layout = c(
        "IntELiMonDSS selection"
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
        card_header("Select Scans"),
        card_body(
          shiny$uiOutput(ns("ui_select_agency")),
          shiny$uiOutput(ns("ui_select_date_range")),
          shiny$actionButton(ns("btn_clear"), "\u2715  Clear All Plots", width = "100%"),
          shiny$actionButton(ns("btn_get_data"), "\u2913  Get Data", width = "100%"),
        )
      ),
      grid_card(
        area = "selection",
        full_screen = TRUE,
        height = "100%",
        card_header("IntELiMon Plots"),
        card_body(
          fill = TRUE,
          height = "100%",
          fillable = TRUE,
          navset_pill(
            #title = "IntELiMon Plots",
            selected = "Location Map",
            #navbar_options = navbar_options(collapsible = TRUE),
            #theme = bs_theme(),
            #header = shiny$tags$head(shiny$includeCSS("app/static/styles.css")),
            nav_panel(title = "Location Map", widget_mapLeaflet$ui(ns("map"))),
            nav_panel(title = "Table", wDT$ui(ns("tbl_scan_filter")))
          )
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {
    #--Filter scans----------------------------------------
    # This can filter plots from the drop down menus in the sidebar, or from the DT data.table filtering
    # options in the table
    # filter the scans based on the sidebar filters (sent to DT table display)
    sidebar_filtered_plots <- shiny$reactive({
      plots <- session$userData$all_scans()
      shiny$req(input$ui_select_date_range)
      filter_plots <- plots[date >= input$ui_select_date_range[1] & date <= input$ui_select_date_range[2]]
      if (is.null(input$ui_select_agency) ||
            length(input$ui_select_agency) == 0) {
        return(filter_plots)
      }
      filter_plots[Agency %in% input$ui_select_agency]
    })

    # Take the filtered plots handed to the data.table, and apply any filters from that table to the mapped
    # plots
    filtered_plots <- shiny$reactive({
      sidebar_filtered_dt <- sidebar_filtered_plots()
      tbl_filtered_index <- tbl_dt$input$dt_rows_all

      if (is.null(tbl_filtered_index) || is.null(sidebar_filtered_dt)) {
        return(sidebar_filtered_dt)
      }
      if (length(tbl_filtered_index) > 0 && max(tbl_filtered_index) > nrow(sidebar_filtered_dt)) {
        return(sidebar_filtered_dt)
      }
      sidebar_filtered_dt[tbl_filtered_index]
    })

    # --------Create Map ------------------------
    map <- widget_mapLeaflet$server("map",
                                    fit2pts =  filtered_plots,
                                    col_names = list(lat = "Latitude", lng = "Longitude"))
    proxy_map <- map$proxy
    #-----Map plot locations---------------------
    # Discrete palette for plot mapping. `levels` is the set of distinct
    # agencies, not the whole column: passing all 11k+ scan rows makes
    # colorFactor warn about duplicate levels on every startup.
    #
    # `unique()` rather than `sort(unique())` - colorFactor takes the levels in
    # the order given, so de-duplicating in place preserves the existing
    # agency-to-colour assignment. Sorting them would keep the same nine
    # colours but shuffle which agency gets which.
    agency_levels <- shiny$reactive({
      unique(session$userData$all_scans()$Agency)
    })
    color_palette <- shiny$reactive({
      leaflet$colorFactor(
        hcl.colors(length(agency_levels()), "Dark 2"),
        levels = agency_levels()
      )
    })

    shiny$observeEvent(filtered_plots(), {
      markers <- filtered_plots()
      # remove selected plots that do not fit the updated filter
      all_clicks <- session$userData$scan_selection()
      all_clicks <- all_clicks[markers,
        on = .(site, plot, date),
        nomatch = 0, .SD,
        .SDcols = names(all_clicks)
      ]
      session$userData$scan_selection(all_clicks)

      map_scan_points(proxy_map,
        markers,
        col_names = list(lat = "Latitude", lng = "Longitude"),
        color = ~color_palette()(Agency),
        lgnd_colors = color_palette()(agency_levels()),
        lgnd_labels = agency_levels(),
        lyr_id = ~paste(site, plot, sep = "-"),
        grp = "filtered",
        clickble = TRUE
      )
    })

    #-----Show labels once zoomed in-------------
    update_point_labels(map$input,
                        proxy_map,
                        filtered_plots,
                        map_id = "map",
                        col_names = list(lat = "Latitude", lng = "Longitude", label = "plot"))

    #----Plots table-----------------------------
    # this is an initial, static render that is updated by the observeEvent below
    columns <- c("site", "plot", "date", "Agency", "Latitude", "Longitude", "scanner_id")
    tbl_dt <- wDT$server("tbl_scan_filter",
                         sidebar_filtered_plots,
                         columns,
                         list(list(0, "asc"), list(1, "asc"), list(2, "asc")),
                         edit_options = FALSE)

    #----Select plots----------------------------
    selection_key <- c("site", "plot", "date", "scanner_id")
    # add to selected plots from ---TABLE---
    shiny$observeEvent(tbl_dt$input$dt_rows_selected, {
      # always initializes as NULL
      dt_selected_rows <- tbl_dt$input$dt_rows_selected

      if (is.null(dt_selected_rows)) {
        dt_selected_rows <- 0
      }
      all_scans <- sidebar_filtered_plots()
      dt_selected_scans <- all_scans[dt_selected_rows]

      current_selection <- session$userData$scan_selection()

      # remove unselected (inner join)
      updated_selection <- current_selection[dt_selected_scans,
                                             on = selection_key,
                                             nomatch = 0, .SD,
                                             .SDcols = names(current_selection)]

      # add newly selected
      added_selection <- dt_selected_scans[!current_selection, on = selection_key]

      if (nrow(added_selection) > 0) {
        added_selection[, ":="(
          id = paste(site, plot, sep = "-"),
          Unit = "My Unit",
          Remeasurement = NA_real_
        )]
        updated_selection <- rbind(updated_selection, added_selection, fill = TRUE)
      }

      if (!fsetequal(current_selection, updated_selection)) {
        session$userData$scan_selection(updated_selection)
      }
    })

    # add to selected plots from ---MAP---
    shiny$observeEvent(map$input$map_marker_click, {
      click <- map$input$map_marker_click
      markers <- filtered_plots()
      all_clicks <- session$userData$scan_selection()

      if (is.null(click$id)) {
        return()
      }

      site_list <- parse_click_id(click, sep = "-", labels = c("site", "plot"))

      if (click$id %in% all_clicks$id) {
        # if clicked on a second time, remove (un-select)
        all_clicks <- all_clicks[id != click$id]
      } else {
        selected <- markers[site == site_list$site & plot == site_list$plot]
        selected[, ":="(
          id = click$id,
          Unit = "My Unit",
          Remeasurement = NA_real_
        )]
        all_clicks <- rbind(all_clicks, selected)
      }

      # reassign to reactive variable
      session$userData$scan_selection(all_clicks)
    })

    # UPDATE from selection
    shiny$observeEvent(session$userData$scan_selection(), {
      all_scans <- sidebar_filtered_plots()
      selection <- session$userData$scan_selection()

      selected_rows <- all_scans[
        selection,
        on = selection_key,
        which = TRUE,
        nomatch = 0
      ]

      selectRows(tbl_dt$proxy, selected_rows)
    })

    update_selected_scan_points(session, proxy_map,
                                col_names = list(lat = "Latitude", lng = "Longitude"),
                                lyrid = ~paste(site, plot, sep = "-"))
    update_dwnld_scan_points(session, proxy_map,
                             col_names = list(lat = "Latitude", lng = "Longitude"),
                             lyrid = ~paste(site, plot, sep = "-"))

    shiny$observeEvent(input$btn_clear, {
      current <- session$userData$scan_selection()
      session$userData$scan_selection(current[0])
      shiny$showNotification("Cleared selected plots.", type = "message", duration = 5)
    })

    shiny$observeEvent(input$btn_get_data, {
      selected <- get_scans4dwnld(session)
      nscans <- nrow(selected)
      nplots <- nrow(unique(selected, by = c("site", "plot")))

      load_from_disk <- is_data_on_disk(selected)
      if (any(load_from_disk)) {
        all_paths <- session$userData$data_paths()
        disk_paths <- all_paths[selected,
                                on = .(site, plot, date),
                                nomatch = 0
        ]
      } else {
        disk_paths <- data.table()
      }

      if (nscans == 0) {
        shiny$showNotification(
          "No scans selected. Click on a desired plot and set date range.",
          type = "warning", duration = 5
        )
        return()
      }

      # assign a default remeasurement number based on sequential years of measurment
      set_remeas_by_yr(session)
      # create a progress bar
      dwnld_prog <- shiny$Progress$new(session)
      on.exit(dwnld_prog$close())
      dwnld_prog$set(
        message = paste("Getting data from", nscans, " new scans at", nplots, "plots..."),
        value = 0
      )
      prog_obj <- list(
        step = 1 / (nscans * 3),
        obj = dwnld_prog,
        detail = ""
      )

      # download data from the API and save to this session
      session$userData$metrics(
        rbindlist(
          list(
                 session$userData$metrics(),
                 api$get_metrics_for_scans(selected[!load_from_disk], progress = prog_obj),
                 disk$read_metrics(disk_paths)
          ),
          fill = TRUE
        )
      )

      session$userData$tree_inv <- rbindlist(
        list(
             session$userData$tree_inv,
             api$get_treeinv_for_scans(selected[!load_from_disk], progress = prog_obj),
             disk$read_treeinv(disk_paths)
          ),
          fill = TRUE
      )

      session$userData$extra_models(
        rbind(
          session$userData$extra_models(),
          api$get_extra_models_for_scans(selected[!load_from_disk], progress = prog_obj)
        )
      )
    })

    #-----renderUI components--------------------
    output$ui_select_agency <- shiny$renderUI({
      agencies <- agency_levels()
      shiny$selectInput(
        inputId = session$ns("ui_select_agency"),
        label = "Agency selection",
        choices = agencies[order(agencies)],
        multiple = TRUE
      )
    })

    output$ui_select_date_range <- shiny$renderUI({
      plots <- session$userData$all_scans()
      min_yr <- min(plots$date)
      max_yr <- max(plots$date)
      shiny$sliderInput(
        inputId = session$ns("ui_select_date_range"),
        label = "Select date range",
        min = min_yr,
        max = max_yr,
        value = c(min_yr, max_yr),
        step = 30,
        timeFormat = "%Y-%m-%d"
      )
    })
  })
}
