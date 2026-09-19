# ---------------------------------------------------------------------------
# Shared metric plot renderer. Used by the Direct outputs, Predictive models
# and rothRmel tabs, so it lives in the logic layer. `treatment_dates` is
# passed in explicitly.
#
# Four plot modes (chosen from the dropdown at the top of each tab's sidebar):
#   "timeseries" - aggregated mean +/- sd per time step, connected line
#   "individual" - one colored line/point series per site/plot, legend at side
#   "boxplot"    - box & whisker per time step (distribution across plots),
#                  time on the X axis
#   "bar"        - mean per time step as bars, time on the X axis
#
# Every mode plots either the raw metric values or percent change from each
# site/plot's own first scan, chosen with the "Data type" dropdown in each
# tab's sidebar (see percent_change_series() in app/logic/series.R).
#
# Plots render with a transparent background and light text so they sit on the
# Aurora Glass cards; see aurora_theme(). Data points are enlarged diamonds,
# treatment lines are thick coral verticals.
#
# NOTE: shiny::validate / shiny::need are called with an explicit shiny::
# prefix. jsonlite also exports validate(); the explicit namespace guarantees
# Shiny's version is used regardless of attach order.
# ---------------------------------------------------------------------------

box::use(
  data.table[fwrite, setnames],
  gplt = ggplot2,
  grid[unit],
  shiny,
  stats[approx],
)

box::use(
  app/logic/manage_timesteps[aggregate_time_steps, assign_time_steps,
                             describe_time_steps, percent_change_series],
)

# Derived metrics: dropdown key -> the metrics column it is computed from
# and the transform applied to it
DERIVED_METRICS <- list(
  gapFraction = list(source = "canopyCover", transform = function(x) 1 - x)
)

# Two palettes for the same plots. SCREEN is the Aurora Glass palette (kept in
# sync with app/static/styles.css): light ink on a transparent ground, made to
# sit on the dark glass cards. EXPORT is its light-ground counterpart, used for
# the SVG/PNG downloads - those land on a white page where the screen palette's
# pale cyan/cream would be invisible, so every colour is darkened to read on
# white. `metric_series_plot(light = TRUE)` selects it.
SCREEN_PAL <- list(
  accent     = "#8ff0e2",
  treat      = "#ff6b7d",
  point      = "#ffe9c9",
  txt        = "#eaf1ff",
  txt_dim    = "#aeb9d6",
  boxfill    = "#ffffff26",
  grid_major = "#ffffff2e",
  grid_minor = "#ffffff18",
  axis_text  = "#e6edff",
  axis_title = "#d3ddf5",
  title      = "#ffffff",
  bg         = "transparent",
  stroke     = "#0a0a0a"
)

EXPORT_PAL <- list(
  accent     = "#0b7285",
  treat      = "#c92a2a",
  point      = "#f59f00",
  txt        = "#1a1a1a",
  txt_dim    = "#495057",
  boxfill    = "#00000010",
  grid_major = "#00000026",
  grid_minor = "#00000014",
  axis_text  = "#212529",
  axis_title = "#343a40",
  title      = "#000000",
  bg         = "white",
  stroke     = "#1a1a1a"
)

TREAT_LW <- 1.4
POINT_SZ <- 3.4
DIAMOND  <- 23

# Transparent, light-on-dark theme so ggplot output blends into the glass card.
# Pair with renderPlot(..., bg = "transparent") in the view modules.
# Plot font. R's default device sans renders thin and jagged at small sizes on
# some systems; a condensed/humanist face reads better in narrow card axes.
# The first entry that actually exists on the machine is used - unavailable
# families silently fall back to "sans", so this is safe to leave as-is.
# Change this one string to restyle every axis in the app. Any family the
# graphics device cannot find is substituted automatically, so an unavailable
# name degrades to the device default rather than erroring.
PLOT_FONT <- "sans"

#' Axis label formatter: keeps only the decimals the data actually needs.
#' A near-flat series (e.g. 141.73 -> 141.81) otherwise prints six-character
#' labels at every break and crowds a narrow axis.
#' @export
axis_fmt <- function(x) {
  fin <- x[is.finite(x)]
  if (length(fin) == 0) return(format(x))
  rng <- diff(range(fin))
  step <- if (length(fin) > 1) min(diff(sort(unique(fin)))) else rng
  digits <- if (!is.finite(step) || step <= 0) 0 else
    max(0, min(2, ceiling(-log10(step))))
  out <- formatC(x, format = "f", digits = digits, big.mark = ",")
  trimws(out)
}

#' Continuous y scale used by every card: few breaks, tidy labels.
#' @export
y_scale <- function() {
  gplt$scale_y_continuous(n.breaks = 5, labels = axis_fmt,
                          expand = gplt$expansion(mult = 0.08))
}

aurora_theme <- function(pal = SCREEN_PAL) {
  gplt$theme_minimal(base_size = 13, base_family = PLOT_FONT) +
    gplt$theme(
      plot.background   = gplt$element_rect(fill = pal$bg, color = NA),
      panel.background  = gplt$element_rect(fill = pal$bg, color = NA),
      legend.background = gplt$element_rect(fill = pal$bg, color = NA),
      legend.key        = gplt$element_rect(fill = pal$bg, color = NA),
      panel.grid.major  = gplt$element_line(color = pal$grid_major, linewidth = 0.4),
      panel.grid.minor  = gplt$element_line(color = pal$grid_minor, linewidth = 0.3),
      text              = gplt$element_text(color = pal$txt, family = PLOT_FONT,
                                            face = "plain"),
      axis.text         = gplt$element_text(color = pal$axis_text, size = 10.5,
                                            face = "plain", lineheight = 0.9),
      axis.text.y       = gplt$element_text(margin = gplt$margin(r = 4), hjust = 1),
      axis.text.x       = gplt$element_text(margin = gplt$margin(t = 3)),
      axis.title        = gplt$element_text(color = pal$axis_title, size = 11.5),
      axis.title.y      = gplt$element_text(margin = gplt$margin(r = 6), angle = 90),
      axis.title.x      = gplt$element_text(margin = gplt$margin(t = 5)),
      plot.title        = gplt$element_text(color = pal$title, face = "bold",
                                            size = 13.5, hjust = 0.5,
                                            margin = gplt$margin(b = 7)),
      plot.margin       = gplt$margin(t = 6, r = 10, b = 4, l = 4),
      legend.text       = gplt$element_text(color = pal$axis_text, size = 9.5),
      legend.title      = gplt$element_text(color = pal$axis_title, size = 10)
    )
}

# Add a chronological time-step factor (labelled by the step's mean date).
.add_step_factor <- function(long) {
  long[, "gdate" := mean(date), by = grp]
  labs_chr <- format(long$gdate, "%Y-%m-%d")
  long[, grp_lab := factor(labs_chr,
                           levels = unique(labs_chr[order(long$gdate)]))]
  long
}

# Interpolate treatment dates onto a discrete (factor) time axis.
.treat_positions <- function(dates_sorted, tvec) {
  if (length(tvec) == 0 || length(dates_sorted) == 0) return(numeric())
  idx  <- seq_along(dates_sorted)
  xpos <- approx(as.numeric(dates_sorted), idx,
                 xout = as.numeric(tvec), rule = 1)$y
  xpos[!is.na(xpos)]
}

# Per-scan table carried on every plot for the CSV download. Always the RAW
# observations (one row per scan, as the "inshiny$dividual" mode plots them) rather
# than whatever the current mode happens to aggregate to - the mean/sd of a
# time series can be recomputed from these rows, but not the reverse. The
# value column is named for the metric so the file says what it holds.
.export_table <- function(long, y_label) {
  if (nrow(long) == 0) return(long)
  out <- long[, list(site, plot, date, time_step = grp, value)]
  setnames(out, "value", y_label)
  out[]
}

# Shared front half of every card: resolve the metric (including the derived
# ones), check the data is usable, build the per-scan long rows and apply the
# percent-change transform. The plot and the Statistics table both start here,
# so they can never disagree about what they are describing.
#
# Returns list(raw, y_label, axis_label, pct). `y_label` names the metric for
# the card title and CSV column; `axis_label` is what the y axis says, which
# in percent mode drops the metric name - the title already carries it, and
# the narrow cards clip a doubled-up label.
#' @export
.series_prep <- function(metric, y_label, data_dt, treat_dates,
                         data_type = "raw") {
  pct <- identical(data_type, "percent")
  if (pct) y_label <- paste0(y_label, " (% change)")

  if (metric %in% names(DERIVED_METRICS)) {
    source_col <- DERIVED_METRICS[[metric]]$source
    transform  <- DERIVED_METRICS[[metric]]$transform
  } else {
    source_col <- metric
    transform  <- identity
  }

  shiny$validate(
    shiny$need(nrow(data_dt) > 0,
               "No data loaded - press Get Data on the Selection Map tab."),
    shiny$need(source_col %in% names(data_dt),
               paste0("Metric '", source_col, "' not found in the data table."))
  )

  raw <- assign_time_steps(data_dt, source_col, treat_dates, transform)
  if (pct) raw <- percent_change_series(raw)

  list(raw = raw, y_label = y_label, pct = pct,
       axis_label = if (pct) "% change from first scan" else y_label)
}

#' Build a metric plot for one metric column of `data_dt`.
#'
#' The returned ggplot carries the raw per-scan rows behind it as the
#' "imn_raw" attribute; `register_plot_download()` writes that as the CSV.
#'
#' @param mode "timeseries" | "individual" | "boxplot" | "bar"
#' @param data_type "raw" plots the metric's own units; "percent" plots
#'   percent change from each site/plot's first scan. The axis, title and CSV
#'   column all pick up the "(% change)" suffix, and a dashed zero line marks
#'   the baseline.
#' @param light TRUE swaps the on-screen Aurora palette for the light-ground
#'   EXPORT palette used by the SVG/PNG downloads.
#' @export
metric_series_plot <- function(data_state, plt_options, light = FALSE) {
  metric <- data_state$metric
  y_label <- data_state$label
  data_dt <- data_state$data_dt
  treat_dates <- data_state$trtmt_dates
  data_type <- data_state$data_type

  errorbars_on <- plt_options$errorbars
  treatlines_on <- plt_options$treatlines
  mode <- plt_options$plot_type

  pal <- if (isTRUE(light)) EXPORT_PAL else SCREEN_PAL
  prep <- .series_prep(metric, y_label, data_dt, treat_dates, data_type)
  raw        <- prep$raw
  y_label    <- prep$y_label
  axis_label <- prep$axis_label
  pct        <- prep$pct
  export_dt  <- .export_table(raw, y_label)

  tvec <- treat_dates$TreatmentDate
  show_treat <- treatlines_on == "on" && length(tvec) > 0

  # ---- Inshiny$dividual plot time series --------------------------------------
  plt <- if (mode == "individual") {
    long <- raw
    shiny$validate(shiny$need(nrow(long) > 0, "No valid values for this metric in the loaded scans."))

    dr <- as.numeric(diff(range(long$date)))
    jw <- max(1, dr / 120)

    p <- gplt$ggplot(long, gplt$aes(x = date, y = value,
                                    color = label, group = label))
    if (show_treat) {
      p <- p + gplt$geom_vline(xintercept = tvec, color = pal$treat,
                               linetype = "solid", linewidth = TREAT_LW)
    }
    p +
      gplt$geom_line(linewidth = 0.7, na.rm = TRUE) +
      gplt$geom_point(shape = DIAMOND, size = POINT_SZ, stroke = 0.5,
                      color = pal$stroke, gplt$aes(fill = label),
                      position = gplt$position_jitter(width = jw, height = 0, seed = 42),
                      na.rm = TRUE) +
      gplt$scale_x_date(expand = gplt$expansion(mult = 0.05)) +
      y_scale() +
      gplt$labs(x = "Scan date", y = axis_label, title = y_label,
                color = "Site / Plot", fill = "Site / Plot") +
      aurora_theme(pal) +
      gplt$theme(legend.position = "right", legend.key.size = unit(0.9, "lines"))

    # ---- Box & whisker per time step (time on X) --------------------------
  } else if (mode == "boxplot") {
    long <- raw
    shiny$validate(shiny$need(nrow(long) > 0, "No valid values for this metric in the loaded scans."))
    .add_step_factor(long)

    p <- gplt$ggplot(long, gplt$aes(x = grp_lab, y = value))
    if (show_treat) {
      xpos <- .treat_positions(sort(unique(long$gdate)), tvec)
      if (length(xpos) > 0) {
        p <- p + gplt$geom_vline(xintercept = xpos, color = pal$treat,
                                 linetype = "solid", linewidth = TREAT_LW)
      }
    }
    p +
      gplt$geom_boxplot(fill = pal$boxfill, color = pal$txt_dim, width = 0.6,
                        outlier.shape = NA, na.rm = TRUE) +
      gplt$geom_point(shape = DIAMOND, size = POINT_SZ - 0.9, stroke = 0.4,
                      color = pal$stroke, fill = pal$point,
                      position = gplt$position_jitter(width = 0.12, height = 0, seed = 42),
                      na.rm = TRUE) +
      y_scale() +
      gplt$labs(x = "Scan date (time step)", y = axis_label, title = y_label) +
      aurora_theme(pal) +
      gplt$theme(axis.text.x = gplt$element_text(angle = 35, hjust = 1))

    # ---- Bar: mean per time step (time on X) ------------------------------
  } else if (mode == "bar") {
    smry <- aggregate_time_steps(raw)
    shiny$validate(shiny$need(nrow(smry) > 0, "No valid values for this metric in the loaded scans."))
    labs_chr <- format(smry$t, "%Y-%m-%d")
    smry[, lab := factor(labs_chr, levels = unique(labs_chr[order(smry$t)]))]

    p <- gplt$ggplot(smry, gplt$aes(x = lab, y = mean))
    if (show_treat) {
      xpos <- .treat_positions(sort(smry$t), tvec)
      if (length(xpos) > 0) {
        p <- p + gplt$geom_vline(xintercept = xpos, color = pal$treat,
                                 linetype = "solid", linewidth = TREAT_LW)
      }
    }
    p <- p + gplt$geom_col(fill = pal$accent, width = 0.7, alpha = 0.85)
    if (errorbars_on == "on") {
      p <- p + gplt$geom_errorbar(gplt$aes(ymin = mean - sd, ymax = mean + sd),
                                  width = 0.3, color = pal$txt_dim, na.rm = TRUE)
    }
    p +
      y_scale() +
      gplt$labs(x = "Scan date (time step)", y = axis_label, title = y_label) +
      aurora_theme(pal) +
      gplt$theme(axis.text.x = gplt$element_text(angle = 35, hjust = 1))

    # ---- Time series (default) --------------------------------------------
  } else {
    smry <- aggregate_time_steps(raw)
    shiny$validate(shiny$need(nrow(smry) > 0, "No valid values for this metric in the loaded scans."))

    p <- gplt$ggplot(smry, gplt$aes(x = t, y = mean))
    if (show_treat) {
      p <- p + gplt$geom_vline(xintercept = tvec, color = pal$treat,
                               linetype = "solid", linewidth = TREAT_LW)
    }
    p <- p + gplt$geom_line(color = pal$accent, linewidth = 0.9)
    if (errorbars_on == "on") {
      p <- p + gplt$geom_errorbar(gplt$aes(ymin = mean - sd, ymax = mean + sd),
                                  width = 5, color = pal$txt_dim, na.rm = TRUE)
    }
    p +
      gplt$geom_point(shape = DIAMOND, size = POINT_SZ, stroke = 0.6,
                      color = pal$stroke, fill = pal$point, na.rm = TRUE) +
      gplt$scale_x_date(limits = range(smry$t), expand = gplt$expansion(mult = 0.05)) +
      y_scale() +
      gplt$labs(x = "Scan date", y = axis_label, title = y_label) +
      aurora_theme(pal)
  }

  # Percent-change cards get a zero rule: the baseline every series starts at.
  if (pct) {
    plt <- plt + gplt$geom_hline(yintercept = 0, color = pal$txt_dim,
                                 linetype = "dashed", linewidth = 0.4)
  }

  attr(plt, "imn_raw") <- export_dt
  plt
}

# Decimal places for a set of statistics: enough to separate the values
# without printing noise. Driven by the magnitude of the largest one, so every
# column of the table lines up on the same precision.
.stat_digits <- function(x) {
  m <- suppressWarnings(max(abs(x[is.finite(x)])))
  if (!is.finite(m) || m == 0) return(2L)
  as.integer(max(0, min(3, 3 - floor(log10(m)))))
}

.fmt_stat <- function(x, digits) {
  ifelse(is.na(x), "—",
         formatC(x, format = "f", digits = digits, big.mark = ","))
}

#' Per-time-step descriptive statistics for one metric card, formatted for the
#' Statistics view. Same metric resolution, same time steps and the same
#' percent-change transform the plot uses (see `.series_prep()`), so the table
#' always describes exactly what the Graph view is drawing.
#'
#' Returns a data.frame of formatted character columns with the metric name
#' carried on the "imn_label" attribute; `register_plot_stats()` renders it.
#' @export
metric_series_stats <- function(data_state) {

  metric <- data_state$metric
  y_label <- data_state$label
  data_dt <- data_state$data_dt
  treat_dates <- data_state$trtmt_dates
  data_type <- data_state$data_type

  prep <- .series_prep(metric, y_label, data_dt, treat_dates, data_type)

  smry <- describe_time_steps(prep$raw)
  shiny$validate(shiny$need(nrow(smry) > 0, "No valid values for this metric in the loaded scans."))

  d <- .stat_digits(unlist(smry[, list(min, max, mean, median, mode, sd)]))
  out <- data.frame(
    `Time step` = format(smry$date, "%Y-%m-%d"),
    n           = as.character(smry$n),
    Min         = .fmt_stat(smry$min, d),
    Max         = .fmt_stat(smry$max, d),
    Mean        = .fmt_stat(smry$mean, d),
    Median      = .fmt_stat(smry$median, d),
    Mode        = .fmt_stat(smry$mode, d),
    SD          = .fmt_stat(smry$sd, d),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  attr(out, "imn_label") <- prep$y_label
  out
}

#' Wrap a `metric_series_plot()` card with a "Download" menu in its lower-right
#' corner (CSV of the underlying data, or an SVG/PNG of the rendered plot).
#' The menu is hidden until the card is hovered - see .imn-plot-dl in
#' app/static/styles.css, which also moves bslib's full-screen expand button
#' to the opposite corner. Pair with `register_plot_download()` in the module
#' server.
#' @param id is a name space passed from the calling ui. Exp: plotting$plot_card_ui(ns('treeStat'))
#' @export
plot_card_ui <- function(id, height = "100%") {
  id_view <- paste0(id, "_view")
  shiny$div(
    class = "imn-plot-wrap",
    # Graph / Statistics toggle, upper left. Hidden until the card is hovered
    # (styles.css keeps it visible whenever Statistics is the active view, so
    # there is always a way back to the plot).
    shiny$div(
      class = "imn-card-view",
      shiny$radioButtons(id_view, label = NULL, inline = TRUE,
                         choices = list("Graph" = "graph", "Statistics" = "stats"),
                         selected = "graph")
    ),
    shiny$conditionalPanel(
      condition = sprintf("input['%s'] == 'graph'", id_view),
      style = "height:100%;",
      shiny$plotOutput(id, height = height)
    ),
    shiny$conditionalPanel(
      condition = sprintf("input['%s'] == 'stats'", id_view),
      style = "height:100%;",
      shiny$div(class = "imn-stats", shiny$uiOutput(paste0(id, "_stats")))
    ),
    shiny$div(
      class = "dropdown imn-plot-dl",
      shiny$tags$button(
        class = "btn btn-sm dropdown-toggle", type = "button",
        `data-bs-toggle` = "dropdown", `aria-expanded` = "false",
        "Download"
      ),
      shiny$tags$ul(
        class = "dropdown-menu dropdown-menu-end",
        shiny$tags$li(shiny$downloadLink(paste0(id, "_dl_csv"), "CSV data",
                                         class = "dropdown-item")),
        shiny$tags$li(shiny$downloadLink(paste0(id, "_dl_svg"), "SVG image",
                                         class = "dropdown-item")),
        shiny$tags$li(shiny$downloadLink(paste0(id, "_dl_png"), "PNG image",
                                         class = "dropdown-item"))
      )
    )
  )
}

#' Render the Statistics view for one card. `stats_fn` is a function of no
#' arguments returning `metric_series_stats()` output.
#' @export
render_plot_stats <- function(output, id, df_r) {
  output[[paste0(id, "_stats")]] <- shiny$renderUI({
    df <- df_r()
    lab <- attr(df, "imn_label")

    shiny$tags$div(
      shiny$tags$div(class = "imn-stats-title", lab),
      shiny$tags$table(
        class = "imn-stats-table",
        shiny$tags$thead(shiny$tags$tr(lapply(names(df), shiny$tags$th))),
        shiny$tags$tbody(lapply(seq_len(nrow(df)), function(i) {
          shiny$tags$tr(lapply(seq_along(df), function(j) {
            shiny$tags$td(class = if (j == 1) "lab" else "num", df[i, j])
          }))
        }))
      ),
      shiny$tags$div(
        class = "imn-stats-note",
        "One row per time step (see Help). Mode is the most frequent value at ",
        "3 significant figures, and reads — when no value repeats; SD is ",
        "— for a step holding a single scan."
      )
    )
  })
}

#' Register the three download handlers behind `plot_card_ui()`'s menu.
#'
#' `plot_fn` is a function of one argument, `light`, returning the ggplot from
#' `metric_series_plot()`. The image handlers call it with `light = TRUE` so
#' the download is rebuilt on the light-ground EXPORT palette - the on-screen
#' Aurora colours are near-invisible on the white page an SVG/PNG lands on.
#' The CSV comes from the plot's "imn_raw" attribute: the raw per-scan rows,
#' regardless of which mode is on screen.
#' @export
register_plot_download <- function(output, id, plot_fn, filename_prefix) {
  output[[paste0(id, "_dl_csv")]] <- shiny$downloadHandler(
    filename = function() paste0(filename_prefix, "_", Sys.Date(), ".csv"),
    content  = function(file) fwrite(attr(plot_fn(), "imn_raw"), file)
  )
  output[[paste0(id, "_dl_svg")]] <- shiny$downloadHandler(
    filename = function() paste0(filename_prefix, "_", Sys.Date(), ".svg"),
    content  = function(file) {
      gplt$ggsave(file, plot = plot_fn(light = TRUE), device = "svg",
                  width = 9, height = 5.5, bg = "white")
    }
  )
  output[[paste0(id, "_dl_png")]] <- shiny$downloadHandler(
    filename = function() paste0(filename_prefix, "_", Sys.Date(), ".png"),
    content  = function(file) {
      gplt$ggsave(file, plot = plot_fn(light = TRUE), device = "png",
                  width = 9, height = 5.5, dpi = 200, bg = "white")
    }
  )

  # These links live inside a collapsed Bootstrap dropdown, so Shiny sees them
  # as hidden and suspends them - the download URL never reaches the client and
  # every item renders permanently disabled. Opening the menu does not trigger
  # Shiny's visibility recalculation (that fires for tabs, not dropdowns), so
  # the suspension has to be turned off outright.
  for (suffix in c("_dl_csv", "_dl_svg", "_dl_png")) {
    shiny$outputOptions(output, paste0(id, suffix), suspendWhenHidden = FALSE)
  }
}
