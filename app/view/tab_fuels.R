# app/view/tab_fuels.R
# ---------------------------------------------------------------------------
# Fuels exports tab. Surface depth / time-lag / canopy fuel cards prefilled from
# the loaded scans, a "Mean fuel loading" card averaging the per-scan surface
# fuel loadings sent to rothRmel (with the source of every value), plus an AOI
# draw map. Reads metrics + the wide additional-
# models table through app/logic/dst_state.R, and writes the drawn polygon to
# session$userData$aoi_polygon and the submitted fuel bed to
# session$userData$fuel_tool_values (picked up by the rothRmel tab).
#
# Ported from the standalone IntELiMon DST's Fuel tool tab. Dynamic input ids
# built inside renderUI are namespaced with session$ns.
# ---------------------------------------------------------------------------
box::use(
  bslib[card_body, card_header, nav_panel],
  data.table[as.data.table, copy, data.table],
  gridlayout[grid_card, grid_container],
  mirai[mirai],
  sf[st_area, st_polygon, st_sf, st_sfc, st_transform],
  shiny[...],
)

box::use(
  app/logic/fuel[
    BROWN_CLASSES,
    CANOPY_FUEL_ROWS,
    SURFACE_FUEL_MODELS,
    TIMELAG_FUEL_MODELS,
    brown_class_load
  ],
  app/logic/fuel_bed[
    MODELED_COLS,
    default_fuel_source,
    mean_fuel_loading,
    merge_scan_models,
    point_in_time_label,
    scan_fuel_loads,
    select_scans
  ],
  app/logic/fuel_models[fuel_model_bed, fuel_model_choices, fuel_model_lookup, is_litter_model],
  app/logic/lcp[build_flammap_lcp, bundle_fuel_rasters, describe_iftdss_tif],
  app/logic/lcp_canopy[describe_canopy_correction, describe_crown_check],
  app/logic/lcp_surface[describe_surface_normalization],
  app/logic/manage_data[pivot_on_model],
  app/view/card_mapLeaflet,
  app/view/map_controls[update_dwnld_scan_points, update_point_labels],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  nav_panel(
    title = "Fuels exports",
    grid_container(
      layout = c("IntELiMonDSS fuelSpace"),
      row_sizes = c("1fr"),
      col_sizes = c("264px", "1fr"),
      gap_size = "10px",
      grid_card(
        area = "IntELiMonDSS",
        card_header("Fuel data source"),
        card_body(
          radioButtons(ns("fuel_source"),
            label = NULL,
            choices = list(
              "Modeled/User defined" = "modeled",
              "LANDFIRE derived" = "landfire"
            ),
            selected = "modeled", width = "100%"
          ),
          # point in time for the card means and the LCP's surface fuels; the
          # date field sits in the third choice's label
          radioButtons(ns("fuel_agg"), "Point in time",
            choiceNames = list(
              "Most recent per plot",
              "Mean of all scans",
              div(
                class = "imn-agg-date",
                tags$span("Nearest"),
                dateInput(ns("fuel_date"), NULL, width = "110px")
              )
            ),
            choiceValues = list("recent", "all", "date"),
            selected = "recent", width = "100%"
          ),
          # LANDFIRE fuel-model picker. Rendered server-side rather than with a
          # conditionalPanel so it does not depend on a namespaced id resolving
          # inside a JS expression.
          uiOutput(ns("fbfm_block"))
        )
      ),
      grid_card(
        area = "fuelSpace",
        card_body(
          grid_container(
            layout = c(
              "surfaceFuelGridArea canopyFuelGridArea",
              "timelagFuelGridArea mapGridArea",
              "calcFuelGridArea mapGridArea"
            ),
            row_sizes = c("auto", "auto", "1fr"),
            col_sizes = c("1fr", "1fr"),
            gap_size = "10px",
            grid_card(
              area = "surfaceFuelGridArea", class = "fuel-card",
              card_header("Surface fuels"),
              card_body(uiOutput(ns("surface_fuel_ui")))
            ),
            grid_card(
              area = "canopyFuelGridArea", class = "fuel-card",
              card_header("Canopy fuels"),
              card_body(uiOutput(ns("canopy_fuel_ui")))
            ),
            grid_card(
              area = "timelagFuelGridArea", class = "fuel-card",
              card_header("Time lag fuels"),
              card_body(uiOutput(ns("timelag_fuel_ui")))
            ),
            grid_card(
              area = "calcFuelGridArea", class = "fuel-card imn-calc-card",
              card_header(
                class = "imn-calc-head",
                "Mean fuel loading", uiOutput(ns("calc_model_tag"), inline = TRUE)
              ),
              card_body(
                uiOutput(ns("calc_fuel_ui")),
                actionButton(ns("submit_fuels"), "↑  Submit fuel values",
                  width = "100%", class = "btn-primary imn-submit"
                ),
                uiOutput(ns("submit_status"))
              )
            ),
            grid_card(
              area = "mapGridArea", class = "fuel-card", full_screen = TRUE,
              card_body(
                fill = TRUE,
                div(
                  style = "display:flex; gap:10px; height:100%;",
                  div(
                    style = "flex:1; min-width:0; min-height:200px; height:100%;",
                    card_mapLeaflet$ui(ns("aoi_map"))
                  ),
                  div(
                    style = "width:150px; flex:none; display:flex;
                             flex-direction:column; gap:6px;",
                    actionButton(ns("btn_fuel_raster"), "Fuel raster export", width = "100%"),
                    actionButton(ns("btn_fuel_dud2"), "Download FastFuels", width = "100%"),
                    actionButton(ns("btn_fuel_dud4"), "Download FCCS", width = "100%")
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # The scans of the sidebar's point in time: the most recent per plot, all
    # of them, or each plot's scan nearest the chosen date.
    aggregate_scans <- function(src) {
      if (nrow(src) == 0) {
        return(data.table())
      }
      select_scans(as.data.table(copy(src)), input$fuel_agg, input$fuel_date)
    }

    fuel_scans <- reactive({
      aggregate_scans(session$userData$metrics())
    })
    fuel_models <- reactive({
      aggregate_scans(pivot_on_model(session$userData$extra_models()))
    })

    # Mean of a column, looked up in whichever table holds it. Direct scan
    # metrics (CBH, canopyCover, LF_*) live in `metrics`; the fuel/cover/time-
    # lag MODELS (MFBDmod, onehrmod, Grassmod, ...) live in the wide models
    # table. Falls back across both so column placement doesn't matter.
    fuel_mean <- function(col) {
      for (m in list(fuel_scans(), fuel_models())) {
        if (nrow(m) > 0 && col %in% names(m)) {
          v <- suppressWarnings(as.numeric(m[[col]]))
          if (!all(is.na(v))) {
            return(mean(v, na.rm = TRUE))
          }
        }
      }
      NA_real_
    }

    # One label + editable numeric box row (dynamic id -> namespaced).
    fuel_input_row <- function(id_suffix, label, value) {
      ns <- session$ns
      val <- if (is.na(value)) NA else round(value, 3)
      div(
        class = "fuel-row",
        tags$span(label, class = "fuel-label"),
        div(
          style = "width:76px; flex:none;",
          tags$div(
            class = "compact-num",
            numericInput(ns(id_suffix), label = NULL, value = val)
          )
        )
      )
    }

    # ---- LANDFIRE fuel model resolution -----------------------------------
    # The scan metrics carry the LANDFIRE fire behavior fuel model codes:
    #   LF_FBFM13 -> Anderson 13, LF_FBFM40 -> Scott & Burgan 40.
    # Take the modal value across the aggregated scans.
    lf_fbfm_code <- reactive({
      col <- if (identical(input$fbfm_system, "FBFM13")) "LF_FBFM13" else "LF_FBFM40"
      for (m in list(fuel_scans(), fuel_models())) {
        if (nrow(m) > 0 && col %in% names(m)) {
          v <- m[[col]]
          v <- v[!is.na(v) & nzchar(as.character(v))]
          if (length(v) > 0) {
            tt <- sort(table(as.character(v)), decreasing = TRUE)
            return(names(tt)[1])
          }
        }
      }
      NA_character_
    })

    # The resolved model: the scan's LANDFIRE code unless the user overrides it
    active_fuel_model <- reactive({
      sys <- if (identical(input$fbfm_system, "FBFM13")) "FBFM13" else "FBFM40"
      ov <- input$fbfm_override
      valid <- unlist(fuel_model_choices(sys), use.names = FALSE)
      key <- if (!is.null(ov) && nzchar(ov) && ov %in% valid) ov else lf_fbfm_code()
      fuel_model_lookup(key, sys)
    })

    # Sidebar block: which classification to use (Anderson 13 and Scott &
    # Burgan 40 are separate systems and are NOT interchangeable, so the
    # choice is explicit), the code resolved from the scan, and an override.
    # In LANDFIRE mode the model is the surface fuel bed; in Modeled mode it
    # only sets the bulk density the surface loadings are scaled with.
    output$fbfm_block <- renderUI({
      ns <- session$ns
      sys <- if (identical(input$fbfm_system, "FBFM13")) "FBFM13" else "FBFM40"
      code <- lf_fbfm_code()

      tagList(
        tags$hr(style = "margin:6px 0;"),
        tags$strong("LANDFIRE fuel model"),
        if (!identical(input$fuel_source, "landfire")) {
          div(
            class = "imn-fnote",
            paste(
              "Each scan uses its own LANDFIRE code unless overridden. Modeled mode",
              "scales the model to the measured depth and uses it wherever a",
              "measurement is missing."
            )
          )
        },
        radioButtons(ns("fbfm_system"), NULL,
          choices = list(
            "Scott & Burgan 40 (LF_FBFM40)" = "FBFM40",
            "Anderson 13 (LF_FBFM13)" = "FBFM13"
          ),
          selected = sys, width = "100%"
        ),
        div(
          class = "imn-fnote",
          "The two systems are separate classifications - pick the one you",
          " intend to model with; they are not interchangeable."
        ),
        div(
          class = "imn-fread",
          div(
            tags$span("From scan"),
            tags$b(if (is.na(code)) "not reported" else as.character(code))
          )
        ),
        selectInput(ns("fbfm_override"), "Override",
          choices = c(
            "Use scan value" = "",
            fuel_model_choices(sys)
          ),
          # a code from the other system is not valid here, so an
          # override only survives a system switch if it exists in
          # the newly selected classification
          selected = {
            cur <- input$fbfm_override
            valid <- unlist(fuel_model_choices(sys), use.names = FALSE)
            if (is.null(cur) || !nzchar(cur) || !(cur %in% valid)) {
              ""
            } else {
              cur
            }
          },
          width = "100%"
        )
      )
    })

    # ---- Default fuel data source ------------------------------------------
    # Modeled/User defined when the scans carry a fuel bed depth or 1-100 hour
    # time-lag models, LANDFIRE derived when they carry none. Set only when the
    # data changes, so the radio stays the user's to switch.
    observeEvent(list(session$userData$metrics(), session$userData$extra_models()), {
      if (nrow(session$userData$metrics()) == 0) {
        return()
      }
      dates <- as.Date(session$userData$metrics()$date)
      updateDateInput(session, "fuel_date",
        value = max(dates, na.rm = TRUE),
        min = min(dates, na.rm = TRUE), max = max(dates, na.rm = TRUE)
      )
      has_data <- vapply(MODELED_COLS, function(col) !is.na(fuel_mean(col)), logical(1))
      updateRadioButtons(session, "fuel_source",
        selected = default_fuel_source(MODELED_COLS[has_data])
      )
    })

    # ---- Surface fuels card (depths + bare ground) -------------------------
    output$surface_fuel_ui <- renderUI({
      tagList(lapply(names(SURFACE_FUEL_MODELS), function(k) {
        m <- SURFACE_FUEL_MODELS[[k]]
        fuel_input_row(paste0("sf_", k), m$label, fuel_mean(m$col))
      }))
    })

    # ---- Time lag fuels card (counts -> Brown tons/acre) ----
    output$timelag_fuel_ui <- renderUI({
      ns <- session$ns

      rows <- lapply(names(TIMELAG_FUEL_MODELS), function(k) {
        m <- TIMELAG_FUEL_MODELS[[k]]
        val <- fuel_mean(m$col)
        cnt <- if (is.na(val)) NA else round(val, 1) # modeled means, not field tallies
        div(
          class = "fuel-row",
          tags$span(m$label, class = "fuel-label"),
          div(
            style = "width:58px; flex:none;",
            tags$div(
              class = "compact-num",
              numericInput(ns(paste0("tl_", k)), label = NULL, value = cnt, step = 0.1)
            )
          ),
          div(
            style = "width:58px; flex:none; text-align:right; font-size:12px;",
            textOutput(ns(paste0("tl_out_", k)), inline = TRUE)
          )
        )
      })

      tagList(div(
        class = "timelag-card",
        div(
          class = "fuel-row", style = "font-weight:bold;",
          tags$span("", class = "fuel-label"),
          tags$span("Count", style = "width:58px; font-size:11px;"),
          tags$span("Tons/acre", style = "width:58px; text-align:right; font-size:11px;")
        ),
        rows,
        hr(style = "margin:2px 0;"),
        div(
          class = "fuel-row", style = "font-weight:bold;",
          tags$span("Total", class = "fuel-label"),
          tags$span("", style = "width:58px;"),
          div(
            style = "width:58px; text-align:right; font-size:12px;",
            textOutput(ns("tl_out_total"), inline = TRUE)
          )
        )
      ))
    })

    # Per-class tons/acre outputs (gray boxes) + total
    local({
      for (k in names(TIMELAG_FUEL_MODELS)) {
        local({
          key <- k
          output[[paste0("tl_out_", key)]] <- renderText({
            load <- brown_class_load(
              input[[paste0("tl_", key)]],
              BROWN_CLASSES[[key]]
            )
            if (is.na(load)) "-" else sprintf("%.3f", load)
          })
        })
      }
    })

    output$tl_out_total <- renderText({
      total <- sum(vapply(names(TIMELAG_FUEL_MODELS), function(k) {
        load <- brown_class_load(input[[paste0("tl_", k)]], BROWN_CLASSES[[k]])
        if (is.na(load)) 0 else load
      }, numeric(1)))
      sprintf("%.3f", total)
    })

    # ---- Canopy fuels card ----
    output$canopy_fuel_ui <- renderUI({
      landfire <- input$fuel_source == "landfire"

      rows <- lapply(names(CANOPY_FUEL_ROWS), function(k) {
        r <- CANOPY_FUEL_ROWS[[k]]
        # In LANDFIRE mode, CBD comes from LF_CBD; other canopy rows have no
        # LANDFIRE equivalent -> blank/editable.
        val <- if (landfire && r$col != "LF_CBD") NA else fuel_mean(r$col)
        # canopyCover is a 0-1 ratio -> show as percent
        if (r$col == "canopyCover" && !is.na(val)) val <- val * 100
        fuel_input_row(paste0("cf_", k), r$label, val)
      })
      tagList(rows)
    })

    # ---- Mean fuel loading (calculation card) ------------------------------
    # Surface fuel loadings are computed for every scan (app/logic/fuel_bed.R)
    # from that scan's own depth, time-lag counts and LANDFIRE fuel model (or
    # the sidebar override). The card shows their mean over the aggregated
    # scans with what each value was derived from; the per-scan table is what
    # gets submitted, so rothRmel tracks the loadings through time. Modeled
    # mode takes each dead class from its count or from the fuel model scaled
    # to the measured depth, falling back to the model where a scan has no
    # measurement. LANDFIRE mode uses each scan's standard fuel model.
    dead_classes <- c(d1 = "onehr", d10 = "tenhr", d100 = "hunhr")
    calc_labels <- c(
      d1 = "1-hour", d10 = "10-hour", d100 = "100-hour",
      herb = "Live herb", woody = "Live woody"
    )
    num_input <- function(id) {
      v <- suppressWarnings(as.numeric(input[[id]]))
      if (length(v) != 1) NA_real_ else v
    }
    fmt_num <- function(x, digits = 3) {
      if (length(x) == 0 || is.na(x)) "-" else formatC(x, format = "f", digits = digits)
    }
    drop_na <- function(x) x[!is.na(x)]

    scan_table <- reactive({
      merge_scan_models(
        session$userData$metrics(), pivot_on_model(session$userData$extra_models())
      )
    })

    # Fuel model for one scan: the sidebar override, else the scan's own code
    scan_fuel_model <- reactive({
      sys <- if (identical(input$fbfm_system, "FBFM13")) "FBFM13" else "FBFM40"
      col <- if (sys == "FBFM13") "LF_FBFM13" else "LF_FBFM40"
      ov <- input$fbfm_override
      if (!is.null(ov) && nzchar(ov) && ov %in% unlist(fuel_model_choices(sys))) {
        fm <- fuel_model_lookup(ov, sys)
        return(function(row) fm)
      }
      function(row) fuel_model_lookup(row[[col]], sys)
    })

    # A box the user changed from its prefilled mean replaces every scan's
    # value; an untouched box leaves each scan with its own.
    edited_value <- function(id, col, digits) {
      v <- num_input(id)
      if (is.na(v)) {
        return(NULL)
      }
      prefilled <- fuel_mean(col)
      if (!is.na(prefilled) && isTRUE(all.equal(v, round(prefilled, digits)))) NULL else v
    }

    scan_loads <- reactive({
      edits <- c(
        list(depth_cm = edited_value("sf_mfbd", SURFACE_FUEL_MODELS$mfbd$col, 3)),
        lapply(dead_classes, function(k) {
          edited_value(paste0("tl_", k), TIMELAG_FUEL_MODELS[[k]]$col, 1)
        })
      )
      scan_fuel_loads(
        scan_table(), scan_fuel_model(),
        prefer = vapply(names(dead_classes), function(k) {
          v <- input[[paste0("calc_src_", k)]]
          if (is.null(v)) "auto" else v
        }, character(1)),
        edits = edits,
        landfire = identical(input$fuel_source, "landfire")
      )
    })

    mean_loading <- reactive(mean_fuel_loading(aggregate_scans(scan_loads())))

    output$calc_model_tag <- renderUI({
      codes <- unique(drop_na(scan_loads()$fbfm))
      model <- if (length(codes) == 0) {
        "No fuel model"
      } else if (length(codes) == 1) {
        codes
      } else {
        sprintf("%d fuel models", length(codes))
      }
      tags$span(
        class = "imn-calc-tag", title = paste(sort(codes), collapse = ", "),
        if (length(codes) == 0) {
          model
        } else if (identical(input$fuel_source, "landfire")) {
          paste(model, "LANDFIRE")
        } else {
          paste(model, "bulk density")
        }
      )
    })

    # Row structure only: rebuilt when the mode or the data change, never on
    # an edit, so the source pickers keep their selection. Each class defaults
    # to "Auto": the count, or the fuel model x depth where a grass model's
    # count is effectively zero or a scan has no count.
    output$calc_fuel_ui <- renderUI({
      ns <- session$ns
      landfire <- identical(input$fuel_source, "landfire")

      value <- function(id) {
        tags$span(textOutput(ns(id), inline = TRUE), class = "imn-calc-val")
      }
      source_text <- function(id) {
        tags$span(textOutput(ns(id), inline = TRUE), class = "imn-calc-src")
      }
      calc_row <- function(label, src, val, class = NULL) {
        div(class = paste("fuel-row", class), tags$span(label, class = "fuel-label"), src, val)
      }
      source_cell <- function(k) {
        if (landfire) {
          return(source_text(paste0("calc_srcl_", k)))
        }
        div(
          class = "imn-calc-src imn-calc-pick",
          selectInput(ns(paste0("calc_src_", k)), NULL,
            choices = c(
              "Auto" = "auto", "Time lag count" = "count", "Fuel model × depth" = "model"
            ),
            selected = "auto", selectize = FALSE
          )
        )
      }

      tagList(
        calc_row(
          "Class", tags$span("Derived from", class = "imn-calc-src"),
          tags$span("Mean t/ac", class = "imn-calc-val"),
          class = "imn-calc-hdr"
        ),
        lapply(names(dead_classes), function(k) {
          calc_row(calc_labels[[k]], source_cell(k), value(paste0("calc_val_", k)))
        }),
        lapply(c("herb", "woody"), function(k) {
          calc_row(
            calc_labels[[k]], source_text(paste0("calc_srcl_", k)),
            value(paste0("calc_val_", k))
          )
        }),
        tags$hr(style = "margin:2px 0;"),
        calc_row("Total load", tags$span(class = "imn-calc-src"), value("calc_total"),
          class = "imn-calc-total"
        ),
        calc_row("Fuel bed depth (ft)", source_text("calc_depth_src"), value("calc_depth")),
        calc_row("Dead Mx (%)", source_text("calc_mx_src"), value("calc_mx")),
        calc_row(
          "Canopy (CBH · CC · CBD)", tags$span("Canopy card", class = "imn-calc-src"),
          value("calc_canopy"),
          class = "imn-calc-wide"
        ),
        calc_row(
          "1000-hour, duff", tags$span("Not used by Rothermel", class = "imn-calc-src"),
          value("calc_ref"),
          class = "imn-calc-ref imn-calc-wide"
        ),
        uiOutput(ns("calc_note"))
      )
    })

    local({
      for (k in names(calc_labels)) {
        local({
          key <- k
          output[[paste0("calc_val_", key)]] <- renderText(
            fmt_num(mean_loading()$load_tonsac[[key]])
          )
          output[[paste0("calc_srcl_", key)]] <- renderText(mean_loading()$sources[[key]])
        })
      }
    })
    output$calc_total <- renderText({
      loads <- mean_loading()$load_tonsac
      fmt_num(if (all(is.na(loads))) NA else sum(loads, na.rm = TRUE))
    })
    output$calc_depth <- renderText(fmt_num(mean_loading()$depth_ft, 2))
    output$calc_depth_src <- renderText(mean_loading()$depth_source)
    output$calc_mx <- renderText(fmt_num(mean_loading()$mx_dead_pct, 0))
    output$calc_mx_src <- renderText(mean_loading()$mx_source)
    output$calc_canopy <- renderText({
      sprintf(
        "%s m · %s%% · %s",
        fmt_num(num_input("cf_cbh"), 1), fmt_num(num_input("cf_cc"), 0),
        fmt_num(num_input("cf_cbd")/100, 2)
      )
    })
    output$calc_ref <- renderText({
      sprintf(
        "%s t/ac · %s cm",
        fmt_num(brown_class_load(input$tl_thohr, BROWN_CLASSES$thohr), 2),
        fmt_num(num_input("sf_mdd"), 1)
      )
    })

    # "1-hour in 2 of 6 scans, 10-hour in 6 of 6 scans" for one fallback source
    fallback_note <- function(m, used, msg) {
      parts <- unlist(lapply(names(m$fallback), function(k) {
        n <- m$fallback[[k]][used]
        if (!is.na(n) && n > 0) sprintf("%s in %d of %d scans", calc_labels[[k]], n, m$n)
      }))
      if (length(parts) > 0) sprintf(msg, paste(parts, collapse = ", "))
    }

    # "Auto" scans that took the fuel model over a grass model's near-zero count
    grass_note <- function(m) {
      parts <- unlist(lapply(names(m$grass_model), function(k) {
        n <- m$grass_model[[k]]
        if (n > 0) sprintf("%s in %d of %d scans", calc_labels[[k]], n, m$n)
      }))
      if (length(parts) > 0) {
        sprintf(
          "Grass fuel model with almost no time-lag count (%s), so Auto uses the fuel model × depth.",
          paste(parts, collapse = ", ")
        )
      }
    }

    output$calc_note <- renderUI({
      m <- mean_loading()
      loads <- scan_loads()
      if (m$n == 0) {
        return(div(class = "imn-fnote", "Load scans to compute fuel loadings."))
      }
      landfire <- identical(input$fuel_source, "landfire")
      sys <- if (identical(input$fbfm_system, "FBFM13")) "FBFM13" else "FBFM40"
      codes <- unique(drop_na(loads$fbfm))
      non_burnable <- codes[vapply(codes, function(code) {
        isTRUE(fuel_model_bed(fuel_model_lookup(code, sys))$non_burnable)
      }, logical(1))]
      no_model <- sum(is.na(loads$fbfm))

      notes <- c(
        sprintf(
          "Means over %d scans (%s); each scan's own loadings are submitted.",
          m$n,
          point_in_time_label(input$fuel_agg, input$fuel_date)
        ),
        if (landfire) {
          paste(
            "Each scan's standard LANDFIRE fuel model loads and depth; the measured",
            "depths and counts above are not used."
          )
        } else {
          c(
            fallback_note(m, "model", "No count for %s, so the fuel model × depth is used."),
            fallback_note(m, "count", "No fuel model for %s, so the count is used."),
            fallback_note(m, "none", "No count or fuel model for %s, so it is 0."),
            grass_note(m)
          )
        },
        if (no_model > 0) {
          sprintf(
            "%d of %d scans have no LANDFIRE fuel model; pick an override in the sidebar.",
            no_model, nrow(loads)
          )
        },
        if (!landfire && is_litter_model(active_fuel_model())) {
          "Litter is the fuel bed under timber litter models, so it is not added separately."
        }
      )
      tagList(
        lapply(notes, function(n) div(class = "imn-fnote", n)),
        if (length(non_burnable) > 0) {
          div(
            class = "imn-sim-warn", tags$b("Non-burnable model "),
            paste(non_burnable, collapse = ", "),
            ". It carries no fuel; rothRmel will return zero spread for those scans."
          )
        }
      )
    })

    # ---- Submit fuel loadings to the rothRmel tab --------------------------
    # Sends the per-scan loadings (with their means, used for any scan the
    # table doesn't hold) plus the canopy values to shared session state. The
    # rothRmel tab picks it up when its fuel source is set to "Fuel tool values".
    observeEvent(input$submit_fuels, {
      landfire <- identical(input$fuel_source, "landfire")
      loads <- scan_loads()

      if (nrow(loads) == 0) {
        showNotification("Load scans before submitting fuel loadings.",
          type = "warning", duration = 6
        )
        return()
      }
      if (landfire && all(is.na(loads$fbfm))) {
        showNotification(
          "No LANDFIRE fuel model resolved - pick one before submitting.",
          type = "warning", duration = 6
        )
        return()
      }

      # the means stand in for any scan rothRmel meets that the table doesn't
      # hold; the label reports the sidebar's point in time
      m <- mean_fuel_loading(loads)
      selected <- select_scans(loads, input$fuel_agg, input$fuel_date)
      point_in_time <- point_in_time_label(input$fuel_agg, input$fuel_date)
      fm <- active_fuel_model()
      bed <- list(
        scans = loads,
        load_tonsac = m$load_tonsac,
        depth_ft = m$depth_ft,
        mx_dead_pct = if (is.na(m$mx_dead_pct)) NULL else m$mx_dead_pct,
        sav = if (landfire && !is.null(fm)) fuel_model_bed(fm)$sav,
        sources = c(m$sources, depth = m$depth_source, mx = m$mx_source),
        source = if (landfire) "landfire" else "modeled",
        system = if (!landfire) {
          "Modeled / user defined"
        } else if (identical(input$fbfm_system, "FBFM13")) {
          "Anderson 13"
        } else {
          "Scott & Burgan 40"
        },
        label = sprintf(
          "%s, mean %s t/ac (%s)",
          if (landfire) "LANDFIRE fuel models" else "Per-scan loadings",
          fmt_num(sum(mean_fuel_loading(selected)$load_tonsac), 2), point_in_time
        ),
        non_burnable = FALSE
      )

      # canopy values from the canopy card travel with the bed
      cc <- num_input("cf_cc")
      bed$cbh_m <- num_input("cf_cbh")
      # the canopy card shows LF_CBD in its stored form (kg/m^3 x 100);
      # fire_behavior expects kg/m^3, so scale on the way out
      cbd_raw <- num_input("cf_cbd")
      bed$cbd <- if (is.na(cbd_raw)) NA_real_ else cbd_raw/100
      bed$canopy_cover_pct <- cc
      bed$stand_height_m <- num_input("cf_maxth")
      bed$aggregation <- sprintf("%d scans, each with its own loadings", nrow(loads))
      # the LCP's surface fuels follow the sidebar's point in time; LANDFIRE
      # derived loadings are the standard models, so they leave the LCP as is
      bed$point_in_time <- point_in_time
      bed$fbfm_system <- if (identical(input$fbfm_system, "FBFM13")) "FBFM13" else "FBFM40"
      bed$surface_scans <- if (!landfire) selected
      bed$submitted_at <- Sys.time()

      no_depth <- sum(is.na(loads$depth_ft) | loads$depth_ft <= 0)
      if (no_depth > 0) {
        showNotification(
          sprintf(
            "%d scans have no fuel bed depth - rothRmel cannot spread fire for them.",
            no_depth
          ),
          type = "warning", duration = 6
        )
      }

      session$userData$fuel_tool_values(bed)
      showNotification(
        sprintf("Submitted to rothRmel: %s (%s).", bed$label, bed$aggregation),
        type = "message", duration = 5
      )
    })

    output$submit_status <- renderUI({
      b <- session$userData$fuel_tool_values()
      if (is.null(b)) {
        return(div(
          class = "imn-fnote",
          "Nothing submitted yet. rothRmel will use scan-level fuels."
        ))
      }
      div(
        class = "imn-okbox",
        tags$b("Submitted. "),
        sprintf(
          "%s · %s · %s", b$label, b$system,
          format(b$submitted_at, "%H:%M:%S")
        )
      )
    })

    # ---- AOI draw map ----
    aoi_polygon <- reactiveVal(NULL)

    map <- card_mapLeaflet$server("aoi_map",
                                  fit2pts =  session$userData$scan_selection,
                                  col_names = list(lat = "Latitude", lng = "Longitude"))
    proxy_map <- map$proxy

    # Center the AOI map on the selected plots when metrics load
    observeEvent(session$userData$metrics(), {
      m <- fuel_scans()
      if (nrow(m) == 0) {
        return()
      }
    })
    update_dwnld_scan_points(session, proxy_map, col_names = list(lat = "Latitude", lng = "Longitude"))
    update_point_labels(map$input,
                        proxy_map,
                        session$userData$scan_selection(),
                        # this is the ID used by the leaflet (app/view/card_mapLeaflet)
                        map_id = "map",
                        col_names = list(lat = "Latitude", lng = "Longitude", label = "plot"))

    # Capture drawn/edited features and store as an sf polygon in session state.
    store_aoi_feature <- function(feat) {
      if (is.null(feat)) {
        aoi_polygon(NULL)
        return(invisible())
      }

      coords <- feat$geometry$coordinates[[1]]
      ring <- do.call(rbind, lapply(coords, function(p) c(p[[1]], p[[2]])))
      if (!identical(ring[1, ], ring[nrow(ring), ])) ring <- rbind(ring, ring[1, ])

      poly <- st_sf(
        geometry = st_sfc(st_polygon(list(ring)), crs = 4326)
      )
      aoi_polygon(poly)

      area_ha <- as.numeric(st_area(st_transform(poly, 5070)))/1e4
      showNotification(
        sprintf("AOI stored (%d vertices, %.1f ha).", nrow(ring) - 1, area_ha),
        type = "message", duration = 4
      )
    }

    observeEvent(map$input$map_draw_new_feature, {
      store_aoi_feature(map$input$map_draw_new_feature)
    })
    observeEvent(map$input$map_draw_edited_features, {
      f <- map$input$map_draw_edited_features
      if (!is.null(f$features) && length(f$features) > 0) {
        store_aoi_feature(f$features[[length(f$features)]])
      }
    })
    observeEvent(map$input$map_draw_deleted_features, {
      aoi_polygon(NULL)
      showNotification("AOI cleared.", type = "message", duration = 3)
    })

    # ---- LCP export ----
    # LANDFIRE layers for a buffered box around the selected plots (widened to
    # any AOI drawn on the map), with the LANDFIRE canopy cover, stand height
    # and base height corrected toward the scans' values (or those submitted from the canopy
    # card) and the lidar canopy metrics burned into bands 5-7 (see
    # app/logic/lcp.R).
    # LANDFIRE needs a contact email, collected by the app-wide email prompt.
    # The build runs in a separate R process (mirai) so the LANDFIRE download
    # doesn't block the session; the result is a .zip with the .lcp and .prj,
    # plus the same landscape as a GeoTIFF (the layout IFTDSS takes). The
    # dialog then offers either file, or both in one .zip.
    lcp_file <- reactiveVal(NULL)

    lcp_task <- ExtendedTask$new(function(metrics, plots, email, zip_path, name, aoi, cbh_m,
                                          cover_pct, height_m, tif_path, surface_scans,
                                          surface_system, surface_label) {
      mirai(
        {
          # the worker starts without the project's .Rprofile, so point it at
          # the app's (renv) library and box path explicitly
          .libPaths(lib_paths)
          options(box.path = project_dir)
          box::use(app/logic/lcp[build_flammap_lcp], )
          build_flammap_lcp(
            metrics, plots,
            email = email, zip_path = zip_path, name = name, aoi = aoi, cbh_m = cbh_m,
            cover_pct = cover_pct, height_m = height_m, tif_path = tif_path,
            surface_scans = surface_scans, surface_system = surface_system,
            surface_label = surface_label,
            progress = function(msg) NULL
          )
        },
        lib_paths = .libPaths(), project_dir = getwd(),
        metrics = metrics, plots = plots, email = email, zip_path = zip_path, name = name,
        aoi = aoi, cbh_m = cbh_m, cover_pct = cover_pct, height_m = height_m,
        tif_path = tif_path, surface_scans = surface_scans, surface_system = surface_system,
        surface_label = surface_label
      )
    })

    start_lcp_build <- function(email) {
      name <- paste0("intelimon_", format(Sys.Date(), "%Y%m%d"))
      lcp_task$invoke(
        session$userData$metrics(),
        session$userData$scan_selection(),
        email = email,
        zip_path = tempfile(fileext = ".zip"),
        name = name,
        aoi = aoi_polygon(),
        # CBH, canopy cover and stand height submitted from the canopy card, if any
        cbh_m = session$userData$fuel_tool_values()$cbh_m,
        cover_pct = session$userData$fuel_tool_values()$canopy_cover_pct,
        height_m = session$userData$fuel_tool_values()$stand_height_m,
        # IFTDSS rejects file names with a "." besides the extension's
        tif_path = file.path(tempfile("iftdss_"), paste0(name, ".tif")),
        # modeled surface fuel loadings for the point in time, if submitted
        surface_scans = session$userData$fuel_tool_values()$surface_scans,
        surface_system = session$userData$fuel_tool_values()$fbfm_system,
        surface_label = session$userData$fuel_tool_values()$point_in_time
      )
      showNotification(
        paste(
          "Building the landscape in the background. LANDFIRE can take a few minutes;",
          "the app stays usable."
        ),
        id = session$ns("lcp_building"), type = "message", duration = NULL, closeButton = FALSE
      )
    }

    request_lcp_build <- function() {
      if (lcp_task$status() == "running") {
        showNotification("A landscape is already being built.", type = "warning")
        return()
      }
      if (nrow(session$userData$metrics()) == 0) {
        showNotification("Load scans before building a landscape.", type = "warning")
        return()
      }
      session$userData$request_email(
        start_lcp_build,
        reason = "LANDFIRE requires a contact email to build the landscape file."
      )
    }

    observeEvent(input$btn_fuel_raster, request_lcp_build())

    observeEvent(lcp_task$status(), ignoreInit = TRUE, {
      status <- lcp_task$status()
      if (status == "running") {
        return()
      }
      removeNotification(session$ns("lcp_building"))

      if (status == "error") {
        msg <- tryCatch(lcp_task$result(), error = conditionMessage)
        showNotification(paste("Landscape build failed:", msg), type = "error", duration = NULL)
        return()
      }
      zip_path <- lcp_task$result()
      lcp_file(zip_path)
      showModal(modalDialog(
        title = "Fuel rasters ready",
        p("Landscape built from LANDFIRE with lidar canopy cover, stand height and",
          "canopy base height at the selected plots. The LCP .zip holds the .lcp and its",
          ".prj for FlamMap (and an .fmd of custom fuel models when surface fuels were",
          "scaled). The GeoTIFF carries the same landscape with LANDFIRE's standard fuel",
          "models; it uploads to IFTDSS as a custom landscape. Save either, or both in",
          "one .zip."),
        p(describe_surface_normalization(attr(zip_path, "surface_fuels"))),
        lapply(attr(zip_path, "canopy_corrections"), function(x) p(describe_canopy_correction(x))),
        p(describe_crown_check(attr(zip_path, "crown_check"))),
        p(describe_iftdss_tif(attr(zip_path, "iftdss_tif"))),
        footer = tagList(
          modalButton("Close"),
          downloadButton(session$ns("lcp_download"), "Save LCP (.zip)", class = "btn-secondary"),
          downloadButton(session$ns("tif_download"), "Save GeoTIFF (.tif)", class = "btn-secondary"),
          downloadButton(session$ns("both_download"), "Save both (.zip)", class = "btn-primary")
        ),
        easyClose = TRUE
      ))
    })

    output$lcp_download <- downloadHandler(
      filename = function() paste0("intelimon_", format(Sys.Date(), "%Y%m%d"), "_lcp.zip"),
      content = function(file) file.copy(lcp_file(), file, overwrite = TRUE)
    )

    output$tif_download <- downloadHandler(
      filename = function() paste0("intelimon_", format(Sys.Date(), "%Y%m%d"), "_landscape.tif"),
      content = function(file) file.copy(attr(lcp_file(), "iftdss_tif"), file, overwrite = TRUE)
    )

    output$both_download <- downloadHandler(
      filename = function() paste0("intelimon_", format(Sys.Date(), "%Y%m%d"), "_fuel_rasters.zip"),
      content = function(file) {
        bundle_fuel_rasters(lcp_file(), attr(lcp_file(), "iftdss_tif"), file)
      }
    )
  })
}
