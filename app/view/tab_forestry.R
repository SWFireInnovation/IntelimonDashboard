# app/view/tab_forestry.R
# ---------------------------------------------------------------------------
# Forestry exports tab. Combines three workflows over one shared stem map:
#   * inventory   - occlusion-corrected stand metrics for the shown scan
#   * prescription- mark stems for removal, see the residual stand
#   * FVS export  - build a treelist + keyword file from the marked stand
# plus a generative mode that simulates a stem map across a landscape AOI.
#
# Per-area values divide by nonocarea (occlusion-corrected) by default; the
# full plot area is available only as a comparison.
#
# Ported from the standalone IntELiMon DST's Forestry tool tab.
# Dynamic input ids built inside renderUI are namespaced with session$ns.
# ---------------------------------------------------------------------------
box::use(
  bslib[card_body, card_header, nav_panel],
  data.table[copy, data.table, fwrite, rbindlist],
  grDevices[dev.off, png],
  graphics[arrows, barplot, box, legend, lines, mtext, par, plot, points],
  gridlayout[grid_card, grid_container, grid_place],
  shiny[...],
  svglite[svglite],
  utils[capture.output, head],
)

box::use(
  app/logic/constants[COLNAME2LABEL],
  app/logic/forestry[
    assign_species,
    crown_ratio,
    detection_shortfall,
    fit_weibull,
    mark_removals,
    plot_area_m2,
    scaling_area_m2,
    simulate_stems,
    stand_metrics
  ],
  app/logic/fvs[build_keyfile, build_standinit, build_treeinit, thin_keyword],
  app/logic/report[report_item],
  app/view/card_points2pano,
  app/view/report_store[add_to_report, file_thumbnail],
)

# Rows of `tbl` belonging to the scan identified by one-row table `key`.
scan_rows <- function(tbl, key) {
  tbl$site == key$site & tbl$plot == key$plot &
    tbl$date == key$date & tbl$scanner_id == key$scanner_id
}

# Label of the unoccluded area metric, used wherever the tab names it.
UNOCC_LABEL <- COLNAME2LABEL[["nonocarea"]]

SPECIES_COLS <- c("#8ff0e2", "#ffd29b", "#a78bfa", "#7ec8ff", "#ff9f6b", "#9ae66e")

#' @export
ui <- function(id) {
  ns <- NS(id)
  nav_panel(
    title = "Forestry exports",
    grid_container(
      layout = c(
        "IntELiMonDSS stemArea rightCol",
        "IntELiMonDSS stemArea pano"
      ),
      row_sizes = c("1fr", "1fr"),
      col_sizes = c("300px", "1.1fr", "0.9fr"),
      gap_size = "9px",

      # ---------------- sidebar ----------------
      grid_card(
        area = "IntELiMonDSS",
        card_header("Forestry"),
        card_body(
          style = "overflow-y:auto;",
          selectInput(ns("mode"), "Mode",
            choices = list(
              "Plot inventory" = "plot",
              "Generative AOI map" = "aoi"
            ),
            selected = "plot", width = "100%"
          ),
          conditionalPanel(
            condition = sprintf("input['%s'] == 'plot'", ns("mode")),
            tags$strong("Scan"),
            uiOutput(ns("scan_nav")),
            tags$hr(style = "margin:5px 0;"),
            tags$strong("Scan geometry"),
            numericInput(ns("radius"), "Plot radius (m)",
              value = 15,
              min = 1, max = 60, step = 0.5
            ),
            uiOutput(ns("area_readout")),
            radioButtons(ns("scaleby"), "Scale per-area values by",
              choiceNames = list(paste(UNOCC_LABEL, "(corrected)"), "Full plot area"),
              choiceValues = list("nonoc", "full"),
              selected = "nonoc", width = "100%"
            ),
            tags$hr(style = "margin:5px 0;"),
            tags$strong("Species mix"),
            uiOutput(ns("species_rows")),
            uiOutput(ns("species_total")),
            actionButton(ns("add_species"), "+ Add species", width = "100%"),
            selectInput(ns("sprule"), "Assignment rule",
              choices = list(
                "Random (ratio only)" = "random",
                "By size class" = "size",
                "Spatially clustered" = "cluster"
              ),
              selected = "random", width = "100%"
            ),
            tags$hr(style = "margin:5px 0;"),
            tags$strong("Prescription"),
            selectInput(ns("method"), "Method",
              choices = list(
                "None - inventory only" = "none",
                "Thin from below" = "below",
                "Thin from above" = "above",
                "By species" = "species",
                "Spacing / crop-tree" = "spacing"
              ),
              selected = "none", width = "100%"
            ),
            sliderInput(ns("target_ba"), "Residual BA (ft2/ac)",
              min = 10, max = 200, value = 80, step = 5, width = "100%"
            ),
            uiOutput(ns("rmsp_ui")),
            numericInput(ns("spacing_ft"), "Minimum spacing (ft)",
              value = 14,
              min = 2, max = 60, step = 1
            ),
            tags$hr(style = "margin:5px 0;"),
            tags$strong("FVS"),
            selectInput(ns("variant"), "Variant",
              choices = c("SN", "CS", "AK", "CR", "PN", "NE", "SO"),
              selected = "SN", width = "100%"
            ),
            numericInput(ns("site_index"), "Site index",
              value = 70,
              min = 10, max = 200, step = 1
            ),
            numericInput(ns("num_cycles"), "Cycles", value = 5, min = 1, max = 40),
            numericInput(ns("time_int"), "Cycle length (yr)",
              value = 10,
              min = 1, max = 20
            ),
            numericInput(ns("slope_pct"), "Slope (%)", value = 0, min = 0, max = 200),
            numericInput(ns("aspect_deg"), "Aspect (deg)", value = 0, min = 0, max = 360),
            checkboxInput(ns("ffe"), "FFE-FVS (fire & fuels)", value = TRUE),
            checkboxInput(ns("use_cr"), "Use lidar crown ratio", value = TRUE),
            checkboxInput(ns("thin_key"), "Write prescription as keyword", value = TRUE),
            downloadButton(ns("dl_treeinit"), "FVS_TreeInit (CSV)",
              class = "btn-block", style = "width:100%;"
            ),
            downloadButton(ns("dl_standinit"), "FVS_StandInit (CSV)",
              class = "btn-block", style = "width:100%;"
            ),
            downloadButton(ns("dl_key"), "Keyword file (.key)",
              class = "btn-block", style = "width:100%;"
            ),
            downloadButton(ns("dl_stems"), "Stem list (CSV)",
              class = "btn-block", style = "width:100%;"
            )
          ),
          conditionalPanel(
            condition = sprintf("input['%s'] == 'aoi'", ns("mode")),
            tags$strong("Source"),
            selectInput(ns("gsource"), NULL,
              choices = list(
                "Active scan only" = "active",
                "All loaded scans (pooled)" = "all"
              ),
              selected = "all", width = "100%"
            ),
            tags$hr(style = "margin:5px 0;"),
            tags$strong("Area of interest"),
            numericInput(ns("aoi_w"), "Width (m)", value = 400, min = 20, max = 5000),
            numericInput(ns("aoi_h"), "Height (m)", value = 300, min = 20, max = 5000),
            uiOutput(ns("aoi_readout")),
            tags$hr(style = "margin:5px 0;"),
            tags$strong("Fitted structure"),
            uiOutput(ns("fit_readout")),
            checkboxInput(ns("override_fit"), "Override fitted values", value = FALSE),
            conditionalPanel(
              condition = sprintf("input['%s']", ns("override_fit")),
              numericInput(ns("g_density"), "Density (stems/ha)",
                value = 600,
                min = 10, max = 5000, step = 10
              ),
              numericInput(ns("g_shape"), "Weibull shape",
                value = 2.2,
                min = 0.5, max = 12, step = 0.1
              ),
              numericInput(ns("g_scale"), "Weibull scale (in)",
                value = 9.5,
                min = 1, max = 60, step = 0.5
              )
            ),
            selectInput(ns("pattern"), "Spatial pattern",
              choices = list(
                "Clustered" = "cluster",
                "Random" = "random",
                "Regular / plantation" = "regular"
              ),
              selected = "cluster", width = "100%"
            ),
            sliderInput(ns("clump"), "Clumping strength",
              min = 2, max = 25,
              value = 9, step = 1, width = "100%"
            ),
            actionButton(ns("reroll"), "Re-roll simulation", width = "100%"),
            tags$div(
              class = "imn-sim-warn",
              tags$b("Simulated, not measured."),
              " Plot-scale structure is extrapolated across the AOI. Validate ",
              "generated canopy cover against independent ALS/LANDFIRE before use."
            ),
            downloadButton(ns("dl_sim"), "Generated stems (CSV)",
              class = "btn-block", style = "width:100%;"
            ),
            downloadButton(ns("dl_sim_stands"), "FVS stands (CSV)",
              class = "btn-block", style = "width:100%;"
            )
          )
        )
      ),

      # ---------------- stem map ----------------
      grid_card(
        area = "stemArea",
        card_header(
          class = "d-flex justify-content-between align-items-center",
          span("Stem map"),
          div(
            class = "d-flex align-items-center gap-2",
            radioButtons(ns("colorby"), NULL,
              choices = list(
                "Species" = "species", "DBH" = "dbh",
                "Crown ratio" = "cr"
              ),
              selected = "species", inline = TRUE
            ),
            span(class = "pano-info", textOutput(ns("stem_count"), inline = TRUE)),
            report_button(ns("rep_stem"), "Add report data: the stem map as shown")
          )
        ),
        card_body(plotOutput(ns("stem_map"), height = "100%"))
      ),

      # ---------------- right column ----------------
      # top: metrics, species, stocking, size bias and FVS tabs; expandable,
      # with report and download controls for the tab showing
      grid_card(
        area = "rightCol",
        full_screen = TRUE,
        card_body(
          class = "imn-forest-right",
          style = "padding:0; position:relative;",
          div(
            class = "imn-forest-add d-flex align-items-center justify-content-end gap-1",
            report_button(ns("rep_right"), "Add report data: the tab showing on this card"),
            div(
              class = "dropdown",
              tags$button(
                class = "btn btn-sm dropdown-toggle imn-card-add", type = "button",
                `data-bs-toggle` = "dropdown", `aria-expanded` = "false",
                title = "Download the tab showing on this card",
                HTML("&#x2913;"), " Download"
              ),
              tags$ul(
                class = "dropdown-menu dropdown-menu-end",
                tags$li(downloadLink(ns("dl_right_csv"), "CSV data", class = "dropdown-item")),
                # images only for the chart tabs
                conditionalPanel(
                  condition = sprintf("['Stocking', 'Size bias'].includes(input['%s'])",
                                      ns("rtabs")),
                  tags$li(downloadLink(ns("dl_right_svg"), "SVG image", class = "dropdown-item")),
                  tags$li(downloadLink(ns("dl_right_png"), "PNG image", class = "dropdown-item"))
                )
              )
            )
          ),
          tabsetPanel(
            id = ns("rtabs"), type = "pills",
            tabPanel(
              "Metrics",
              div(
                class = "imn-fscroll",
                uiOutput(ns("metrics_cards")),
                tableOutput(ns("occ_table")),
                uiOutput(ns("verdict"))
              )
            ),
            tabPanel("Species", div(class = "imn-fscroll", tableOutput(ns("species_table")))),
            tabPanel("Stocking", div(
              class = "imn-fchart", plotOutput(ns("stocking"), height = "100%")
            )),
            tabPanel("Size bias", div(
              class = "imn-fchart", plotOutput(ns("bias"), height = "100%"),
              tags$p(
                class = "imn-fnote",
                paste(
                  "Detection probability falls with stem size, so the",
                  "smallest classes stay under-counted even after the",
                  "unoccluded area correction. Indicative only - not applied",
                  "to the metrics above."
                )
              )
            )),
            tabPanel("FVS", div(class = "imn-fscroll", verbatimTextOutput(ns("fvs_preview"))))
          )
        )
      ),

      # bottom: Points2Pano view of the selected plots
      grid_place(
        area = "pano",
        card_points2pano$ui(ns("panoViewer"))
      )
    )
  )
}

# Chart colours on the dark glass cards, and on the white page of a report.
FOREST_SCREEN <- list(
  fg = "#eaf1ff", axis = "#cdd6ee", main = "#ffffff", faint = "#ffffff55",
  line = "#ffffffaa", mid = "#ffffff77", box = "#ffffff44", ring = "#8ff0e299",
  dots = "#8ff0e2bb"
)
# Downloads and the report get a white background; on screen it stays transparent.
FOREST_PAPER <- list(
  bg = "white", fg = "#1a1a1a", axis = "#343a40", main = "#000000", faint = "#00000055",
  line = "#000000aa", mid = "#00000077", box = "#00000044", ring = "#0b7285cc",
  dots = "#0b7285bb"
)

# "+ Report data" button for the Forestry cards.
report_button <- function(id, title) {
  actionButton(id, "+ Report data", class = "btn-sm imn-add-report imn-card-add", title = title)
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    tree_inventory <- reactive({
      session$userData$metrics()
      session$userData$tree_inv
    })

    scan_idx <- reactiveVal(1L)
    sim_seed <- reactiveVal(7L)
    n_species <- reactiveVal(3L)

    DEFAULT_SP <- list(list("LP", 60), list("SA", 25), list("WO", 15))

    # ---- scans available (populated inventories) --------------------------
    scan_keys <- reactive({
      ti <- tree_inventory()
      if (nrow(ti) == 0) {
        return(data.table())
      }
      unique(ti[, list(site, plot, date, scanner_id)])
    })

    observeEvent(tree_inventory(), {
      scan_idx(1L)
    })

    current_scan <- reactive({
      sk <- scan_keys()
      if (nrow(sk) == 0) {
        return(NULL)
      }
      sk[min(scan_idx(), nrow(sk))]
    })

    output$scan_nav <- renderUI({
      sk <- scan_keys()
      if (nrow(sk) == 0) {
        return(div(
          class = "imn-fnote",
          "No tree inventories loaded - press Get Data on the Selection Map tab."
        ))
      }
      cs <- current_scan()
      div(
        class = "d-flex align-items-center gap-2",
        actionButton(ns("prev_scan"), "\u25C0", class = "btn-sm"),
        div(
          class = "pano-info", style = "flex:1; text-align:center;",
          sprintf(
            "%s / %s  %s", cs$site, cs$plot,
            format(as.Date(cs$date, "%Y%m%d"), "%Y-%m-%d")
          )
        ),
        actionButton(ns("next_scan"), "\u25B6", class = "btn-sm")
      )
    })

    observeEvent(input$prev_scan, {
      n <- nrow(scan_keys())
      if (n == 0) {
        return()
      }
      scan_idx(if (scan_idx() <= 1) n else scan_idx() - 1L)
    })
    observeEvent(input$next_scan, {
      n <- nrow(scan_keys())
      if (n == 0) {
        return()
      }
      scan_idx(if (scan_idx() >= n) 1L else scan_idx() + 1L)
    })

    # ---- stems for the current scan ---------------------------------------
    scan_trees <- reactive({
      cs <- current_scan()
      ti <- tree_inventory()
      if (is.null(cs) || nrow(ti) == 0) {
        return(data.table())
      }
      t <- ti[scan_rows(ti, cs)]
      if (nrow(t) == 0) {
        return(data.table())
      }
      t <- copy(t)
      # crown ratio from the scan's canopy base height when available
      m <- scan_metrics_row()
      cbh <- if (!is.null(m) && "CBH" %in% names(m)) {
        suppressWarnings(as.numeric(m$CBH[1]))
      } else {
        NA_real_
      }
      t[, cr := crown_ratio(H, cbh)]
      t
    })

    scan_metrics_row <- reactive({
      cs <- current_scan()
      mt <- session$userData$metrics()
      if (is.null(cs) || nrow(mt) == 0) {
        return(NULL)
      }
      r <- mt[scan_rows(mt, cs)]
      if (nrow(r) == 0) NULL else r
    })

    # nonocarea for the current scan (m2), from the metrics response
    nonoc_area <- reactive({
      m <- scan_metrics_row()
      if (is.null(m)) {
        return(NA_real_)
      }
      hit <- intersect(
        c("nonocarea", "nonocArea", "NonOcArea", "non_oc_area"),
        names(m)
      )
      if (length(hit) == 0) {
        return(NA_real_)
      }
      suppressWarnings(as.numeric(m[[hit[1]]][1]))
    })

    scale_area <- reactive({
      scaling_area_m2(nonoc_area(), input$radius, input$scaleby)
    })

    output$area_readout <- renderUI({
      full <- plot_area_m2(input$radius)
      no <- nonoc_area()
      frac <- if (is.na(no)) NA else no/full * 100
      div(
        class = "imn-fread",
        div(tags$span("Maximum area"), tags$b(sprintf("%.1f m\u00B2", full))),
        div(
          tags$span(UNOCC_LABEL),
          tags$b(if (is.na(no)) "not reported" else sprintf("%.1f m\u00B2", no))
        ),
        div(
          tags$span("Visible"),
          tags$b(if (is.na(frac)) "\u2014" else sprintf("%.1f%%", frac))
        )
      )
    })

    # ---- species mix ------------------------------------------------------
    output$species_rows <- renderUI({
      k <- n_species()
      lapply(seq_len(k), function(i) {
        d <- if (i <= length(DEFAULT_SP)) DEFAULT_SP[[i]] else list("", 0)
        div(
          class = "imn-sprow",
          span(
            class = "imn-swatch",
            style = paste0("background:", SPECIES_COLS[(i - 1) %% 6 + 1])
          ),
          textInput(ns(paste0("sp_code_", i)), NULL,
            value = d[[1]],
            placeholder = "code"
          ),
          numericInput(ns(paste0("sp_pct_", i)), NULL,
            value = d[[2]],
            min = 0, max = 100, step = 5
          )
        )
      })
    })

    observeEvent(input$add_species, {
      if (n_species() < 6) n_species(n_species() + 1L)
    })

    species_tbl <- reactive({
      k <- n_species()
      rows <- lapply(seq_len(k), function(i) {
        code <- input[[paste0("sp_code_", i)]]
        pct <- input[[paste0("sp_pct_", i)]]
        if (is.null(code) || is.null(pct)) {
          return(NULL)
        }
        data.table(
          code = toupper(trimws(code)),
          pct = suppressWarnings(as.numeric(pct)),
          col = SPECIES_COLS[(i - 1) %% 6 + 1]
        )
      })
      out <- rbindlist(Filter(Negate(is.null), rows), use.names = TRUE)
      if (nrow(out) == 0) {
        return(out)
      }
      out[nzchar(code) & !is.na(pct) & pct > 0]
    })

    output$species_total <- renderUI({
      sp <- species_tbl()
      tot <- if (nrow(sp) == 0) 0 else sum(sp$pct)
      div(
        class = paste("imn-sptot", if (abs(tot - 100) > 0.01) "bad" else ""),
        tags$span("Total"), tags$b(sprintf("%.0f%%", tot))
      )
    })

    output$rmsp_ui <- renderUI({
      sp <- species_tbl()
      if (nrow(sp) == 0 || !identical(input$method, "species")) {
        return(NULL)
      }
      selectInput(ns("remove_species"), "Remove species",
        choices = sp$code, width = "100%"
      )
    })

    # ---- stems + species + prescription -----------------------------------
    stems_marked <- reactive({
      t <- scan_trees()
      if (nrow(t) == 0) {
        return(t)
      }
      t <- copy(t)
      sp <- species_tbl()
      t[, species := if (nrow(sp) > 0) {
        assign_species(t, sp, input$sprule)
      } else {
        NA_character_
      }]
      t[, rm := mark_removals(
        t, scale_area(), input$method,
        input$target_ba, input$remove_species,
        input$spacing_ft
      )]
      t
    })

    mets_before <- reactive({
      t <- stems_marked()
      if (nrow(t) == 0) {
        return(NULL)
      }
      stand_metrics(t, scale_area())
    })
    mets_after <- reactive({
      t <- stems_marked()
      if (nrow(t) == 0) {
        return(NULL)
      }
      k <- t[rm == FALSE]
      if (nrow(k) == 0) {
        return(NULL)
      }
      stand_metrics(k, scale_area())
    })

    output$stem_count <- renderText({
      t <- stems_marked()
      if (nrow(t) == 0) {
        return("No stems")
      }
      sprintf("%d stems \u00B7 %d marked", nrow(t), sum(t$rm))
    })

    # ---- generative AOI ---------------------------------------------------
    pooled_stems <- reactive({
      if (identical(input$gsource, "active")) {
        return(scan_trees())
      }
      tree_inventory()
    })

    fitted_params <- reactive({
      t <- pooled_stems()
      if (nrow(t) == 0) {
        return(NULL)
      }
      d <- suppressWarnings(as.numeric(t$DBH))
      w <- fit_weibull(d)
      # occlusion-corrected density: pool each scan by its own nonocarea
      mt <- session$userData$metrics()
      keys <- unique(t[, list(site, plot, date, scanner_id)])
      tot_area <- 0
      tot_n <- 0
      for (i in seq_len(nrow(keys))) {
        k <- keys[i]
        n_i <- nrow(t[scan_rows(t, k)])
        a_i <- NA_real_
        if (nrow(mt) > 0) {
          r <- mt[scan_rows(mt, k)]
          hit <- intersect(c("nonocarea", "nonocArea", "NonOcArea"), names(r))
          if (nrow(r) > 0 && length(hit) > 0) {
            a_i <- suppressWarnings(as.numeric(r[[hit[1]]][1]))
          }
        }
        if (is.na(a_i) || a_i <= 0) a_i <- plot_area_m2(input$radius)
        tot_area <- tot_area + a_i
        tot_n <- tot_n + n_i
      }
      tot_area_ha <- tot_area * 1e-4
      dens_tph <- if (tot_area > 0) tot_n/tot_area_ha else NA_real_
      list(
        shape = w$shape, scale = w$scale, density_tph = dens_tph,
        n = nrow(t), area = tot_area
      )
    })

    output$fit_readout <- renderUI({
      f <- fitted_params()
      if (is.null(f)) {
        return(div(class = "imn-fnote", "No stems loaded."))
      }
      div(
        class = "imn-fread",
        div(tags$span("Source stems"), tags$b(format(f$n, big.mark = ","))),
        div(tags$span("Density"), tags$b(sprintf("%.0f /ha", f$density_tph))),
        div(tags$span("Weibull k"), tags$b(sprintf("%.2f", f$shape))),
        div(tags$span("Weibull \u03BB"), tags$b(sprintf("%.1f in", f$scale)))
      )
    })

    output$aoi_readout <- renderUI({
      a <- (input$aoi_w * input$aoi_h)/1e4
      div(
        class = "imn-fread",
        div(tags$span("AOI"), tags$b(sprintf(
          "%.2f ha \u00B7 %.2f ac",
          a, a * 2.471054
        )))
      )
    })

    observeEvent(input$reroll, {
      sim_seed(sim_seed() + 1L)
    })

    sim_stems <- reactive({
      f <- fitted_params()
      if (is.null(f)) {
        return(data.table())
      }
      dens <- if (isTRUE(input$override_fit)) input$g_density else f$density_tph
      shape <- if (isTRUE(input$override_fit)) input$g_shape else f$shape
      scale <- if (isTRUE(input$override_fit)) input$g_scale else f$scale
      if (is.na(dens) || dens <= 0) {
        return(data.table())
      }
      simulate_stems(input$aoi_w, input$aoi_h, dens, shape, scale,
        input$pattern, input$clump,
        strata = NULL,
        seed = sim_seed()
      )
    })

    # ---- stem map ---------------------------------------------------------
    draw_stem_map <- function(pal) {
      if (identical(input$mode, "aoi")) {
        s <- sim_stems()
        validate(need(
          nrow(s) > 0,
          "No stems to simulate - load tree inventories on the Selection Map tab."
        ))
        op <- par(
          bg = pal$bg %||% NA, mar = c(4, 4, 2, 1), fg = pal$fg,
          col.axis = pal$axis, col.lab = pal$axis, col.main = pal$main
        )
        on.exit(par(op), add = TRUE)
        plot(s$x, s$y,
          asp = 1, pch = 16,
          cex = pmax(0.25, s$DBH/max(s$DBH) * 1.1),
          col = pal$dots,
          xlab = "Easting (m)", ylab = "Northing (m)",
          main = sprintf(
            "Simulated stem map \u2014 %s stems over %.2f ha",
            format(nrow(s), big.mark = ","),
            input$aoi_w * input$aoi_h/1e4
          )
        )
        box(col = pal$box)
        mtext("SIMULATED \u2014 not measured",
          side = 3, adj = 1, cex = 0.8,
          col = "#ff6b7d"
        )
        return(invisible())
      }

      t <- stems_marked()
      validate(need(
        nrow(t) > 0,
        "No tree inventory for this scan - press Get Data on the Selection Map tab."
      ))

      x <- suppressWarnings(as.numeric(t$X))
      y <- suppressWarnings(as.numeric(t$Y))
      d <- suppressWarnings(as.numeric(t$DBH))
      lim <- input$radius

      cols <- if (identical(input$colorby, "species")) {
        sp <- species_tbl()
        m <- match(t$species, sp$code)
        ifelse(is.na(m), "#7c8aa0", sp$col[m])
      } else if (identical(input$colorby, "dbh")) {
        SPECIES_COLS[pmin(6, pmax(1, ceiling(d/max(d, na.rm = TRUE) * 6)))]
      } else {
        cr <- suppressWarnings(as.numeric(t$cr))
        cr[is.na(cr)] <- 0.3
        SPECIES_COLS[pmin(6, pmax(1, ceiling(cr * 6)))]
      }

      op <- par(
        bg = pal$bg %||% NA, mar = c(4, 4, 2, 1), fg = pal$fg,
        col.axis = pal$axis, col.lab = pal$axis, col.main = pal$main
      )
      on.exit(par(op), add = TRUE)

      plot(NA,
        xlim = c(-lim, lim), ylim = c(-lim, lim), asp = 1,
        xlab = "X (m)", ylab = "Y (m)",
        main = sprintf(
          "Stem map \u2014 scaled by %s",
          if (identical(input$scaleby, "nonoc")) {
            "unoccluded area"
          } else {
            "full plot area"
          }
        )
      )
      # plot boundary + visible-fraction ring
      th <- seq(0, 2 * pi, length.out = 200)
      lines(lim * cos(th), lim * sin(th), col = pal$faint, lty = 2)
      no <- nonoc_area()
      if (!is.na(no) && no > 0) {
        r_eq <- sqrt(no/pi)
        lines(r_eq * cos(th), r_eq * sin(th), col = pal$ring, lwd = 2)
      }
      points(0, 0, pch = 3, col = "#ffd29b", cex = 1.2)

      keep <- !t$rm
      points(x[keep], y[keep],
        pch = 16, col = cols[keep],
        cex = pmax(0.5, d[keep]/max(d, na.rm = TRUE) * 2.2)
      )
      if (any(t$rm)) {
        points(x[!keep], y[!keep],
          pch = 1, col = cols[!keep],
          cex = pmax(0.5, d[!keep]/max(d, na.rm = TRUE) * 2.2)
        )
        points(x[!keep], y[!keep], pch = 4, col = "#ff6b7d", cex = 1.1)
      }
      box(col = pal$box)
    }
    output$stem_map <- renderPlot(draw_stem_map(FOREST_SCREEN), bg = "transparent", res = 110)

    # ---- metric cards -----------------------------------------------------
    output$metrics_cards <- renderUI({
      b <- mets_before()
      if (is.null(b)) {
        return(div(class = "imn-fnote", "No stems loaded."))
      }
      a <- mets_after()
      shown <- if (is.null(a)) b else a
      mk <- function(k, v, u, cls = "") {
        div(
          class = paste("imn-met", cls),
          div(class = "k", k), div(class = "v", v), div(class = "u", u)
        )
      }
      div(
        class = "imn-mets",
        mk("Density", sprintf("%.0f", shown$tpa), "trees/ac"),
        mk("Basal area", sprintf("%.1f", shown$ba_ac), "ft\u00B2/ac"),
        mk("QMD", sprintf("%.1f", shown$qmd_in), "in", "alt"),
        mk("SDI", sprintf("%.0f", shown$sdi), "Reineke", "warn"),
        mk("Rel. density", sprintf("%.1f", shown$rd), "Curtis"),
        mk(
          "Mean CR",
          if (is.na(shown$cr_mean)) "\u2014" else sprintf("%.0f", shown$cr_mean * 100),
          "%", "alt"
        )
      )
    })

    occ_df <- reactive({
      t <- stems_marked()
      if (nrow(t) == 0) {
        return(NULL)
      }
      full_a <- plot_area_m2(input$radius)
      no <- nonoc_area()
      if (is.na(no) || no <= 0) no <- full_a
      mf <- stand_metrics(t, full_a)
      mc <- stand_metrics(t, no)
      pd <- function(a, b) sprintf("%+.1f%%", (b - a)/a * 100)
      out <- data.frame(
        Metric = c(
          "Trees/ac", "Basal area (ft2/ac)", "SDI",
          "QMD (in)", "FVS TreeCount"
        ),
        `Full area` = c(
          sprintf("%.0f", mf$tpa), sprintf("%.1f", mf$ba_ac),
          sprintf("%.0f", mf$sdi), sprintf("%.1f", mf$qmd_in),
          sprintf("%.2f", mf$ef_tpa)
        ),
        unocc = c(
          sprintf("%.0f", mc$tpa), sprintf("%.1f", mc$ba_ac),
          sprintf("%.0f", mc$sdi), sprintf("%.1f", mc$qmd_in),
          sprintf("%.2f", mc$ef_tpa)
        ),
        Delta = c(
          pd(mf$tpa, mc$tpa), pd(mf$ba_ac, mc$ba_ac),
          pd(mf$sdi, mc$sdi), "unaffected", pd(mf$ef_tpa, mc$ef_tpa)
        ),
        check.names = FALSE
      )
      names(out)[names(out) == "unocc"] <- UNOCC_LABEL
      out
    })
    output$occ_table <- renderTable(occ_df(), striped = FALSE, spacing = "xs", width = "100%")

    verdict_text <- reactive({
      b <- mets_before()
      if (is.null(b)) {
        return(NULL)
      }
      a <- mets_after()
      full_a <- plot_area_m2(input$radius)
      no <- nonoc_area()
      vis <- if (is.na(no) || no <= 0) NA else no/full_a * 100

      occ_txt <- if (is.na(vis)) {
        paste(
          UNOCC_LABEL, "was not reported for this scan, so per-area values",
          "fall back to the full plot area and may be understated."
        )
      } else {
        sprintf(
          paste(
            "%.0f%% of the plot was visible. Using the full %.0f m\u00B2",
            "would understate density and basal area by %.0f%%;",
            "QMD is a size ratio and is unaffected."
          ),
          vis, full_a, 100 - vis
        )
      }

      pct <- if (is.null(a)) NA else a$sdi/450 * 100
      rx_txt <- if (identical(input$method, "none")) {
        "Inventory only - choose a prescription to mark stems."
      } else if (is.na(pct)) {
        "All stems removed."
      } else {
        sprintf(
          "Residual SDI %.0f%% of maximum. %s", pct,
          if (pct < 35) {
            "Below full stocking - understory response likely."
          } else if (pct < 55) {
            "Managed zone: full occupancy without imminent self-thinning."
          } else {
            "Above the onset of self-thinning - competition mortality likely."
          }
        )
      }
      list(occlusion = occ_txt, prescription = rx_txt)
    })

    output$verdict <- renderUI({
      v <- verdict_text()
      if (is.null(v)) {
        return(NULL)
      }
      tagList(
        div(class = "imn-okbox", tags$b("Occlusion. "), v$occlusion),
        div(class = "imn-okbox", tags$b("Prescription. "), v$prescription)
      )
    })

    species_df <- reactive({
      t <- stems_marked()
      sp <- species_tbl()
      if (nrow(t) == 0 || nrow(sp) == 0) {
        return(NULL)
      }
      rows <- lapply(sp$code, function(cd) {
        g <- t[species == cd]
        if (nrow(g) == 0) {
          return(data.frame(
            Species = cd, Trees = 0L, `% stems` = "0%",
            `BA ft2/ac` = "-", `QMD in` = "-", Removed = 0L,
            check.names = FALSE
          ))
        }
        m <- stand_metrics(g, scale_area())
        data.frame(
          Species = cd, Trees = nrow(g),
          `% stems` = sprintf("%.0f%%", nrow(g)/nrow(t) * 100),
          `BA ft2/ac` = sprintf("%.1f", m$ba_ac),
          `QMD in` = sprintf("%.1f", m$qmd_in),
          Removed = sum(g$rm), check.names = FALSE
        )
      })
      do.call(rbind, rows)
    })
    output$species_table <- renderTable(species_df(), striped = FALSE, spacing = "xs",
                                        width = "100%")

    draw_stocking <- function(pal) {
      b <- mets_before()
      validate(need(!is.null(b), "No stems loaded."))
      a <- mets_after()
      op <- par(
        bg = pal$bg %||% NA, mar = c(4, 4, 2, 1), fg = pal$fg,
        col.axis = pal$axis, col.lab = pal$axis, col.main = pal$main
      )
      on.exit(par(op), add = TRUE)
      qs <- seq(2, 26, by = 0.4)
      plot(NA,
        xlim = c(2, 26), ylim = c(0, 700), xlab = "QMD (in)",
        ylab = "Trees per acre", main = "Stocking (density - QMD)"
      )
      qmd_term <- (qs/10) ^ 1.605
      for (i in seq_along(c(450, 250, 160))) {
        sdi <- c(450, 250, 160)[i]
        lines(qs, sdi/qmd_term,
          col = c(pal$line, pal$mid, pal$faint)[i],
          lty = if (i == 1) 1 else 2
        )
      }
      points(b$qmd_in, b$tpa, pch = 21, bg = "#ffd29b", col = "#0a0f1f", cex = 2)
      if (!is.null(a) && any(stems_marked()$rm)) {
        arrows(b$qmd_in, b$tpa, a$qmd_in, a$tpa, length = 0.08, col = pal$mid)
        points(a$qmd_in, a$tpa, pch = 21, bg = "#8ff0e2", col = "#0a0f1f", cex = 2)
      }
      legend("topright",
        bty = "n", text.col = pal$axis,
        legend = c("SDI 450 (max)", "55%", "35%", "before", "after"),
        lty = c(1, 2, 2, NA, NA), pch = c(NA, NA, NA, 21, 21),
        pt.bg = c(NA, NA, NA, "#ffd29b", "#8ff0e2"),
        col = c(pal$line, pal$mid, pal$faint, "#0a0f1f", "#0a0f1f")
      )
    }
    # res 90: the chart tabs share half the right column with Points2Pano
    output$stocking <- renderPlot(draw_stocking(FOREST_SCREEN), bg = "transparent", res = 90)

    draw_bias <- function(pal) {
      t <- stems_marked()
      validate(need(nrow(t) > 0, "No stems loaded."))
      full_a <- plot_area_m2(input$radius)
      no <- nonoc_area()
      vf <- if (is.na(no) || no <= 0) 1 else no/full_a
      sh <- detection_shortfall(suppressWarnings(as.numeric(t$DBH)), vf)
      validate(need(nrow(sh) > 0, "No diameters available."))
      op <- par(
        bg = pal$bg %||% NA, mar = c(4, 4, 2, 1), fg = pal$fg,
        col.axis = pal$axis, col.lab = pal$axis, col.main = pal$main
      )
      on.exit(par(op), add = TRUE)
      m <- rbind(sh$detected, sh$missing)
      # headroom above the tallest bar keeps the legend clear of the bars
      barplot(m,
        names.arg = sh$cls, col = c("#8ff0e2", "#ff6b7d88"),
        border = NA, xlab = "DBH class (in)", ylab = "Stems",
        main = "Detected vs inferred missing",
        ylim = c(0, max(colSums(m), 1) * 1.6), cex.main = 1
      )
      # one row across the top, in the headroom above the bars
      legend("top",
        bty = "n", text.col = pal$axis, horiz = TRUE, cex = 0.85,
        pch = 15, pt.cex = 1.6, col = c("#8ff0e2", "#ff6b7d88"),
        legend = c("detected", "inferred missing")
      )
    }
    output$bias <- renderPlot(draw_bias(FOREST_SCREEN), bg = "transparent", res = 90)

    # ---- Add to report ----------------------------------------------------
    # The stem map and the right-hand card's open tab go into the report as
    # shown, with the scan and the settings behind them. Charts are redrawn on
    # the white-page palette.
    forestry_context <- function() {
      cs <- current_scan()
      list(
        Scan = if (is.null(cs)) NULL else sprintf("%s plot %s, %s", cs$site, cs$plot, cs$date),
        `Plot radius` = sprintf("%s m", input$radius),
        `Per-area values` = if (identical(input$scaleby, "nonoc")) UNOCC_LABEL else
          "full plot area",
        Prescription = switch(input$method,
          none = "None (inventory only)", below = "Thin from below", above = "Thin from above",
          species = "By species", spacing = "Spacing / crop-tree", input$method
        ),
        `Residual BA target` = if (!identical(input$method, "none")) {
          sprintf("%s ft2/ac", input$target_ba)
        }
      )
    }
    # Draw one chart to a PNG on the white-page palette; NULL if it can't be drawn.
    chart_file <- function(draw, width = 1500, height = 1200) {
      path <- tempfile("forestry_", fileext = ".png")
      png(path, width = width, height = height, res = 200, bg = "white", type = "cairo")
      ok <- tryCatch({
        draw(FOREST_PAPER)
        TRUE
      }, error = function(e) FALSE)
      dev.off()
      if (ok) path else NULL
    }
    add_chart <- function(draw, title, extra = list(), methods = character(), ...) {
      path <- chart_file(draw, ...)
      if (is.null(path)) {
        showNotification("Nothing to add yet: load tree inventories first.", type = "warning")
        return()
      }
      add_to_report(session, report_item(
        "image", title, "Forestry exports", settings = c(forestry_context(), extra),
        image = path, group = "Forestry", thumb = file_thumbnail(path),
        methods = methods
      ))
    }
    add_forest_table <- function(tbl, title, analysis = NULL, methods = character()) {
      if (is.null(tbl) || nrow(tbl) == 0) {
        showNotification("Nothing to add yet: load tree inventories first.", type = "warning")
        return()
      }
      add_to_report(session, report_item(
        "table", title, "Forestry exports", settings = forestry_context(), table = tbl,
        analysis = analysis, group = "Forestry",
        methods = methods
      ))
    }

    observeEvent(input$rep_stem, {
      if (identical(input$mode, "aoi")) {
        add_chart(draw_stem_map, "Simulated stem map", list(Mode = "Generative AOI map"),
                  methods = "generative")
      } else {
        add_chart(draw_stem_map, "Stem map",
                  list(`Coloured by` = switch(input$colorby, species = "Species", dbh = "DBH",
                                              cr = "Crown ratio")),
                  methods = c("occlusion", if (identical(input$colorby, "species")) {
                    "species_assignment"
                  }),
                  width = 1400, height = 1400)
      }
    })

    # Stand metrics as shown on the Metrics tab (NULL before inventories load).
    metrics_table <- function() {
      b <- mets_before()
      a <- mets_after()
      if (is.null(b)) return(NULL)
      row <- function(m) {
        c(sprintf("%.0f", m$tpa), sprintf("%.1f", m$ba_ac), sprintf("%.1f", m$qmd_in),
          sprintf("%.0f", m$sdi), sprintf("%.1f", m$rd),
          if (is.na(m$cr_mean)) "\u2014" else sprintf("%.0f", m$cr_mean * 100))
      }
      tbl <- data.frame(
        Metric = c("Density (trees/ac)", "Basal area (ft2/ac)", "QMD (in)",
                   "SDI (Reineke)", "Relative density (Curtis)", "Mean crown ratio (%)"),
        Inventory = row(b), check.names = FALSE, stringsAsFactors = FALSE
      )
      if (!identical(input$method, "none")) {
        tbl$`After prescription` <- if (is.null(a)) "\u2014" else row(a)
      }
      tbl
    }

    # The data behind the tab showing on the right card, for its CSV download.
    right_tab_data <- function(tab) {
      switch(tab,
        Metrics = metrics_table(),
        Species = species_df(),
        Stocking = {
          b <- mets_before()
          a <- mets_after()
          if (is.null(b)) return(NULL)
          stands <- if (!is.null(a) && any(stems_marked()$rm)) list(b, a) else list(b)
          data.frame(
            Stand = c("Inventory", "After prescription")[seq_along(stands)],
            `Trees per acre` = vapply(stands, function(m) m$tpa, 1),
            `QMD (in)` = vapply(stands, function(m) m$qmd_in, 1),
            `SDI (Reineke)` = vapply(stands, function(m) m$sdi, 1),
            check.names = FALSE
          )
        },
        `Size bias` = {
          t <- stems_marked()
          if (nrow(t) == 0) return(NULL)
          no <- nonoc_area()
          full_a <- plot_area_m2(input$radius)
          vf <- if (is.na(no) || no <= 0) 1 else no / full_a
          sh <- detection_shortfall(suppressWarnings(as.numeric(t$DBH)), vf)
          data.frame(`DBH class (in)` = sh$cls, Detected = sh$detected,
                     `Inferred missing` = sh$missing, check.names = FALSE)
        },
        FVS = fvs_report_table()
      )
    }

    # Download name: tab and scan, e.g. "forestry_size_bias_CASDU_0003_2025-01-24".
    right_file <- function(ext) {
      cs <- current_scan()
      scan <- if (is.null(cs)) "" else paste0("_", cs$site, "_", cs$plot, "_", cs$date)
      paste0("forestry_", gsub(" ", "_", tolower(input$rtabs)), scan, ".", ext)
    }

    output$dl_right_csv <- downloadHandler(
      filename = function() right_file("csv"),
      content = function(file) {
        tbl <- right_tab_data(input$rtabs)
        if (is.null(tbl)) tbl <- data.frame(note = "No data loaded")
        fwrite(tbl, file)
      }
    )
    right_chart_file <- function(file, device) {
      draw <- switch(input$rtabs, Stocking = draw_stocking, `Size bias` = draw_bias)
      device(file)
      on.exit(dev.off())
      draw(FOREST_PAPER)
    }
    output$dl_right_svg <- downloadHandler(
      filename = function() right_file("svg"),
      content = function(file) {
        right_chart_file(file, function(f) svglite(f, width = 9, height = 5.5, bg = "white"))
      }
    )
    output$dl_right_png <- downloadHandler(
      filename = function() right_file("png"),
      content = function(file) {
        right_chart_file(file, function(f) {
          png(f, width = 9, height = 5.5, units = "in", res = 200, bg = "white")
        })
      }
    )
    # the links sit in a collapsed dropdown, which Shiny treats as hidden;
    # keep them live so the download URLs reach the page
    for (dl in c("dl_right_csv", "dl_right_svg", "dl_right_png")) {
      outputOptions(output, dl, suspendWhenHidden = FALSE)
    }

    # Points2Pano viewer under the right card, linked to the scan shown: the
    # viewer follows the scan picked in the left panel, and stepping the
    # viewer to a scan with a tree inventory shows that scan here too
    pano <- card_points2pano$server("panoViewer", session, follow = current_scan)
    observeEvent(pano$current(), {
      p <- pano$current()
      sk <- scan_keys()
      if (is.null(p) || nrow(sk) == 0) return()
      at <- match(card_points2pano$scan_id(p$site, p$plot, p$date, p$scanner_id),
                  card_points2pano$scan_id(sk$site, sk$plot, sk$date, sk$scanner_id))
      if (!is.na(at) && at != scan_idx()) scan_idx(at)
    }, ignoreInit = TRUE)

    observeEvent(input$rep_right, {
      switch(input$rtabs,
        Metrics = {
          tbl <- metrics_table()
          if (is.null(tbl)) {
            showNotification("Nothing to add yet: load tree inventories first.",
                             type = "warning")
            return()
          }
          v <- verdict_text()
          add_forest_table(tbl, "Stand metrics", list(
            summary = paste(v$occlusion, v$prescription), cautions = character(),
            implication = NULL
          ), methods = c("occlusion", "stand_density"))
          add_forest_table(occ_df(), "Occlusion correction",
                           methods = c("occlusion", "stand_density"))
        },
        Species = add_forest_table(species_df(), "Species composition",
                                   methods = c("occlusion", "species_assignment")),
        Stocking = add_chart(draw_stocking, "Stocking (density and QMD)",
                             methods = c("occlusion", "stand_density")),
        `Size bias` = add_chart(draw_bias, "Size bias: detected and inferred missing stems",
                                methods = c("occlusion", "size_bias")),
        FVS = add_forest_table(fvs_report_table(), "FVS export",
                               methods = c("fvs", "species_assignment",
                                           if (isTRUE(input$ffe)) "ffe"))
      )
    })

    # ---- FVS preview + downloads ------------------------------------------
    fvs_bits <- reactive({
      cs <- current_scan()
      t <- stems_marked()
      if (is.null(cs) || nrow(t) == 0) {
        return(NULL)
      }
      keep <- t[rm == FALSE]
      if (nrow(keep) == 0) keep <- t[0]
      sid <- sprintf("%s_%s", cs$site, cs$plot)
      m <- stand_metrics(if (nrow(keep) > 0) keep else t, scale_area())
      yr <- as.integer(substr(cs$date, 1, 4))

      tr <- build_treeinit(keep, sid, m$ef_tpa, isTRUE(input$use_cr))
      st <- build_standinit(
        sid, yr, m$area_ac, input$variant,
        (species_tbl()$code %||% "LP")[1], input$site_index,
        input$slope_pct, input$aspect_deg
      )
      thin <- if (isTRUE(input$thin_key) && !identical(input$method, "none")) {
        thin_keyword(input$method, input$target_ba, input$remove_species, yr)
      } else {
        NULL
      }
      ky <- build_keyfile(
        sid, yr, m$area_ac, input$variant,
        (species_tbl()$code %||% "LP")[1], input$site_index,
        input$num_cycles, input$time_int,
        input$slope_pct, input$aspect_deg,
        thin, isTRUE(input$ffe), isTRUE(input$use_cr)
      )
      list(tree = tr, stand = st, key = ky, sid = sid)
    })

    # The FVS export settings as a report table: what was written and how.
    fvs_report_table <- function() {
      f <- fvs_bits()
      if (is.null(f)) {
        return(NULL)
      }
      yes_no <- function(x) if (isTRUE(x)) "Yes" else "No"
      data.frame(
        Setting = c("Stand", "Variant", "Site species", "Site index", "Cycles",
                    "Cycle length (yr)", "Slope (%)", "Aspect (deg)", "Tree records",
                    "FFE-FVS (fire & fuels)", "Lidar crown ratio", "Prescription as keyword"),
        Value = c(f$sid, input$variant, (species_tbl()$code %||% "LP")[1],
                  as.character(input$site_index), as.character(input$num_cycles),
                  as.character(input$time_int), as.character(input$slope_pct),
                  as.character(input$aspect_deg), as.character(nrow(f$tree)),
                  yes_no(input$ffe), yes_no(input$use_cr),
                  yes_no(input$thin_key && !identical(input$method, "none"))),
        check.names = FALSE, stringsAsFactors = FALSE
      )
    }

    output$fvs_preview <- renderText({
      f <- fvs_bits()
      if (is.null(f)) {
        return("No stems loaded.")
      }
      hdr <- capture.output(print(head(as.data.frame(f$tree), 12),
        row.names = FALSE
      ))
      paste(c(
        "---- FVS_TreeInit (first 12 of ",
        nrow(f$tree), " records) ----\n", hdr,
        "\n\n---- keyword file ----\n", f$key
      ), collapse = "\n")
    })

    output$dl_treeinit <- downloadHandler(
      filename = function() paste0(fvs_bits()$sid, "_FVS_TreeInit.csv"),
      content = function(file) fwrite(fvs_bits()$tree, file)
    )
    output$dl_standinit <- downloadHandler(
      filename = function() paste0(fvs_bits()$sid, "_FVS_StandInit.csv"),
      content = function(file) fwrite(fvs_bits()$stand, file)
    )
    output$dl_key <- downloadHandler(
      filename = function() paste0(fvs_bits()$sid, ".key"),
      content = function(file) writeLines(fvs_bits()$key, file)
    )
    output$dl_stems <- downloadHandler(
      filename = function() paste0(fvs_bits()$sid, "_stems.csv"),
      content = function(file) fwrite(stems_marked(), file)
    )
    output$dl_sim <- downloadHandler(
      filename = function() "IntELiMon_simulated_stems.csv",
      content = function(file) {
        s <- copy(sim_stems())
        s[, note := "SIMULATED - not measured"] # nolint: unused_declared_object_linter.
        fwrite(s, file)
      }
    )
    output$dl_sim_stands <- downloadHandler(
      filename = function() "IntELiMon_simulated_FVS_stands.csv",
      content = function(file) {
        s <- sim_stems()
        if (nrow(s) == 0) {
          return(fwrite(data.table(), file))
        }
        area_ac <- input$aoi_w * input$aoi_h/1e4 * 2.471054
        m <- stand_metrics(s, input$aoi_w * input$aoi_h)
        fwrite(data.table(
          Stand_ID = "AOI_SIM_1", Variant = input$variant,
          Inv_Year = as.integer(format(Sys.Date(), "%Y")),
          Inv_Plot_Size = round(area_ac, 4),
          Site_Species = (species_tbl()$code %||% "LP")[1],
          Site_Index = input$site_index,
          Trees = nrow(s), BA_ft2_ac = round(m$ba_ac, 1),
          QMD_in = round(m$qmd_in, 1),
          Note = "SIMULATED - not measured"
        ), file)
      }
    )
  })
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a # nolint: object_name_linter.
