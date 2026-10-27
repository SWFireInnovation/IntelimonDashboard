box::use(
  DT[selectRows],
  bslib[card_body, card_header, nav_panel, navset_card_pill],
  data.table[data.table, fsetequal, rbindlist, uniqueN],
  grDevices[hcl.colors],
  gridlayout[grid_card, grid_container, grid_place],
  leaflet,
  shiny,
)

box::use(
  api = app/logic/load_data_api,
  disk = app/logic/load_data_dir,
  app/logic/manage_data[
    downloaded_keys, get_scans4dwnld, is_data_on_disk, keep_downloaded, remove_scans,
    set_scan_numbers
  ],
  app/logic/map_fnc[in_drawn_shape, parse_click_id],
  app/view/map_controls[map_scan_points,
                        update_dwnld_scan_points,
                        update_point_labels,
                        update_selected_scan_points],
  wDT = app/view/widget_datatable,
  app/view/widget_mapLeaflet,
)

today <- Sys.Date()
beresheet <- as.Date("2000-01-01")

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
          shiny$selectInput(inputId = ns("ui_select_agency"),
            label = "Agency selection",
            choices = NULL,
            multiple = TRUE
          ),
          shiny$sliderInput(
            inputId = ns("ui_select_date_range"),
            label = "Select date range",
            min = beresheet,
            max = today,
            value = c(beresheet, today),
            step = 30,
            timeFormat = "%Y-%m-%d"
          ),
          shiny$actionButton(ns("btn_clear"), "\u2715  Clear All Plots", width = "100%"),
          shiny$actionButton(ns("btn_get_data"), "\u2913  Get Data", width = "100%"),
          shiny$actionButton(ns("btn_clear_downloads"), "\u2715  Clear All Downloads",
                             width = "100%"),
        )
      ),
      grid_place(
        area = "selection",
        navset_card_pill(
          title = "IntELiMon Plots",
          selected = "Location Map",
          height = "100%",
          full_screen = TRUE,
          nav_panel(title = "Location Map", widget_mapLeaflet$ui(ns("map"))),
          nav_panel(title = "Table", wDT$ui(ns("tbl_scan_filter")))
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
    filtered_plots_raw <- shiny$reactive({
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

    # Wait for both DT and sidebar_filtered_plots to update before displaying
    filtered_plots <- shiny$debounce(filtered_plots_raw, 250)
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

    #--Setting the selection------------------------------
    # Every change to the selection goes through here. Downloaded scans stay
    # selected (and their unit, remeasurement and scan grouping with them)
    # until they are removed with Clear All Downloads or on Set Treatments, so
    # the selection always covers the downloaded data (issue #24). `visible`
    # is the set of scans the user could see and deselect; when a downloaded
    # one among them is put back, a message says how to remove it.
    set_selection <- function(new, visible = NULL) {
      old <- session$userData$scan_selection()
      res <- keep_downloaded(new, old, session$userData$metrics())
      kept <- res$kept
      if (!is.null(visible) && nrow(kept) > 0) {
        kept <- kept[visible, on = selection_key, nomatch = 0]
      }
      if (!is.null(visible) && nrow(kept) > 0) {
        n <- nrow(kept)
        shiny$showNotification(
          paste0(
            n, " downloaded scan", if (n == 1) " stays" else "s stay", " loaded. Remove ",
            if (n == 1) "it" else "them", " on the Set Treatments tab, or with Clear All Downloads."
          ),
          type = "warning", duration = 8
        )
      }
      same <- nrow(old) == nrow(res$selection) &&
        isTRUE(tryCatch(fsetequal(old, res$selection), error = function(e) FALSE))
      if (!same) {
        session$userData$scan_selection(res$selection)
      } else if (!is.null(visible) && nrow(kept) > 0) {
        # the selection didn't change, so nothing else re-highlights the table
        # rows the user just clicked off
        highlight_selection()
      }
      invisible(res)
    }
    selection_key <- c("site", "plot", "date", "scanner_id")

    shiny$observeEvent(filtered_plots(), {
      markers <- filtered_plots()
      # remove selected plots that do not fit the updated filter
      all_clicks <- session$userData$scan_selection()
      all_clicks <- all_clicks[markers,
        on = .(site, plot, date),
        nomatch = 0, .SD,
        .SDcols = names(all_clicks)
      ]
      # downloaded scans stay selected even when the filters hide them
      set_selection(all_clicks)

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

      set_selection(updated_selection, visible = all_scans)
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
          Remeasurement = NA_integer_,
          ScanGroup = NA_integer_
        )]
        all_clicks <- rbind(all_clicks, selected)
      }

      # reassign to reactive variable; a downloaded plot clicked off stays loaded
      set_selection(all_clicks, visible = markers[site == site_list$site & plot == site_list$plot])
    })

    #----Select plots inside a drawn shape-------
    # A rectangle or polygon drawn with the map's tools adds every plot inside
    # it (all of its scans that pass the filters), as clicking each plot
    # would. Plots already selected stay selected. The shape is then removed
    # so the next one can be drawn.
    shiny$observeEvent(map$input$map_draw_new_feature, {
      markers <- filtered_plots()
      all_clicks <- session$userData$scan_selection()
      inside <- markers[in_drawn_shape(markers, map$input$map_draw_new_feature)]
      inside[, "id" := paste(site, plot, sep = "-")] # nolint: object_name_linter
      new <- inside[!id %in% all_clicks$id]
      widget_mapLeaflet$clear_drawn_shapes(proxy_map)

      n_new <- uniqueN(new$id)
      n_already <- uniqueN(inside$id) - n_new
      if (nrow(inside) == 0) {
        shiny$showNotification("No plots inside the drawn shape.", type = "warning", duration = 5)
        return()
      }
      shiny$showNotification(
        paste0(
          "Selected ", n_new, " plot", if (n_new == 1) "" else "s", " inside the drawn shape",
          if (n_already > 0) paste0(" (", n_already, " already selected)") else "", "."
        ),
        type = "message", duration = 5
      )
      if (n_new == 0) return()

      new[, ":="(
        Unit = "My Unit",
        Remeasurement = NA_integer_,
        ScanGroup = NA_integer_
      )]
      set_selection(rbind(all_clicks, new, use.names = TRUE))
    })

    # UPDATE from selection - and when the filters change the table's rows, so
    # the highlighted rows follow the scans rather than their old positions, and
    # when the table is first drawn (it is only drawn once the Table view opens,
    # so earlier highlights never reached it)
    table_drawn <- shiny$reactive(!is.null(tbl_dt$input$dt_rows_all))
    highlight_selection <- function() {
      all_scans <- sidebar_filtered_plots()
      selection <- session$userData$scan_selection()

      selected_rows <- all_scans[
        selection,
        on = selection_key,
        which = TRUE,
        nomatch = 0
      ]

      selectRows(tbl_dt$proxy, selected_rows)
    }
    highlight_triggers <- shiny$reactive(
      list(session$userData$scan_selection(), sidebar_filtered_plots(), table_drawn())
    )
    shiny$observeEvent(highlight_triggers(), {
      highlight_selection()
    })

    update_selected_scan_points(session, proxy_map,
                                col_names = list(lat = "Latitude", lng = "Longitude"),
                                lyrid = ~paste(site, plot, "select", sep = "-"))
    update_dwnld_scan_points(session, proxy_map,
                             col_names = list(lat = "Latitude", lng = "Longitude"),
                             lyrid = ~paste(site, plot, "dwnld", sep = "-"))

    shiny$observeEvent(input$btn_clear, {
      current <- session$userData$scan_selection()
      res <- set_selection(current[0])
      n_kept <- nrow(res$kept)
      shiny$showNotification(
        paste0(
          "Cleared selected plots.",
          if (n_kept > 0) {
            paste0(
              " ", n_kept, " downloaded scan", if (n_kept == 1) " stays" else "s stay",
              " loaded; use Clear All Downloads to remove ", if (n_kept == 1) "it." else "them."
            )
          } else {
            ""
          }
        ),
        type = "message", duration = 8
      )
    })

    #----Clear all downloads---------------------
    # Removes every downloaded scan's data (metrics, tree inventory, models)
    # and those scans from the selection, after a confirmation.
    shiny$observeEvent(input$btn_clear_downloads, {
      n <- nrow(downloaded_keys(session$userData$metrics()))
      if (n == 0) {
        shiny$showNotification("No scans have been downloaded.", type = "message", duration = 5)
        return()
      }
      shiny$showModal(shiny$modalDialog(
        title = "Clear all downloads?",
        paste0(
          "This removes the data of all ", n, " downloaded scan", if (n == 1) "" else "s",
          " from this session, along with their unit names, remeasurement numbers and scan ",
          "groupings. Figures already added to the report are kept. To use the scans again, ",
          "select them and click Get Data."
        ),
        footer = shiny$tagList(
          shiny$modalButton("Cancel"),
          shiny$actionButton(session$ns("btn_clear_downloads_ok"), "Clear all downloads",
                             class = "btn-danger")
        ),
        easyClose = TRUE
      ))
    })

    shiny$observeEvent(input$btn_clear_downloads_ok, {
      shiny$removeModal()
      keys <- downloaded_keys(session$userData$metrics())
      remove_scans(session, keys)
      shiny$showNotification(
        paste0("Cleared ", nrow(keys), " downloaded scan", if (nrow(keys) == 1) "" else "s", "."),
        type = "message", duration = 5
      )
    })

    shiny$observeEvent(input$btn_get_data, {
      selected <- get_scans4dwnld(session)
      nscans <- nrow(selected)
      nplots <- nrow(unique(selected, by = c("site", "plot")))

      load_from_disk <- is_data_on_disk(selected)
      if (any(load_from_disk)) {
        all_paths <- session$userData$data_paths()
        disk_paths <- all_paths[selected,
          on = .(site, plot, date, scanner_id),
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

      # number each plot's visits (Remeasurement) and group the scans into time
      # steps (Scan grouping)
      set_scan_numbers(session)

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

      # Download everything first and save it to the session only if every
      # request succeeded, so a server that stops responding part-way leaves
      # no half-downloaded scans behind.
      new_data <- tryCatch(
        list(
          metrics = rbindlist(
            list(
              api$get_metrics_for_scans(selected[!load_from_disk], progress = prog_obj),
              disk$read_metrics(disk_paths)
            ),
            fill = TRUE
          ),
          tree_inv = rbindlist(
            list(
              api$get_treeinv_for_scans(selected[!load_from_disk], progress = prog_obj),
              disk$read_treeinv(disk_paths)
            ),
            fill = TRUE
          ),
          extra_models = api$get_extra_models_for_scans(selected[!load_from_disk],
                                                        progress = prog_obj)
        ),
        error = function(e) {
          shiny$showNotification(
            paste(
              if (api$is_api_unreachable(e)) {
                api$API_UNREACHABLE_MSG
              } else {
                paste("The download failed:", conditionMessage(e))
              },
              "No new scans were downloaded; click Get Data to try again."
            ),
            type = "error", duration = NULL
          )
          NULL
        }
      )
      if (is.null(new_data)) return()

      session$userData$tree_inv <- rbindlist(
        list(session$userData$tree_inv, new_data$tree_inv), fill = TRUE
      )
      session$userData$extra_models(
        rbind(session$userData$extra_models(), new_data$extra_models)
      )
      session$userData$metrics(
        rbindlist(list(session$userData$metrics(), new_data$metrics), fill = TRUE)
      )
    })

    #-----renderUI components--------------------
    # Don't re-render when agency_levels updates and keep last selection.
    shiny$observeEvent(agency_levels(), {
      shiny$req(agency_levels())
      agencies <- agency_levels()

      shiny$updateSelectInput(
        session,
        "ui_select_agency",
        choices = agencies[order(agencies)],
        selected = shiny$isolate(input$ui_select_agency)
      )
    }, ignoreNULL = TRUE)

    # Don't re-render when all_scans updates and keep last selection.
    shiny$observeEvent(session$userData$all_scans(), {
      plots <- session$userData$all_scans()
      shiny$req(nrow(plots) > 0)
      min_yr <- min(plots$date)
      max_yr <- max(plots$date)

      last <- shiny$isolate(input$ui_select_date_range)
      new_value <- if (beresheet %in% last) {
        c(min_yr, max_yr)
      } else {
        c(last[1], last[2])
      }

      shiny$updateSliderInput(
        session,
        "ui_select_date_range",
        min = min_yr,
        max = max_yr,
        value = new_value
      )
    }, ignoreNULL = TRUE)

  })
}
