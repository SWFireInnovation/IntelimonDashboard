# ---------------------------------------------------------------------------
# Time-series construction and treatment-date parsing.
# Pure functions on data.tables; no Shiny.
# ---------------------------------------------------------------------------

box::use(
  data.table[copy, data.table,  setorder],
  stats[median, sd],
)

#' Parse a comma-separated string of YYYYMMDD dates; returns list(ok, bad).
parse_treatment_dates <- function(txt) {
  parts <- trimws(unlist(strsplit(txt, ",")))
  parts <- parts[nzchar(parts)]
  if (length(parts) == 0) return(list(ok = character(), bad = character()))

  valid <- grepl("^\\d{8}$", parts) & !is.na(as.Date(parts, format = "%Y%m%d"))
  list(ok = parts[valid], bad = parts[!valid])
}

#' Assign each scan to a time-step group for one metric column, returning the
#' LONG per-scan rows (not aggregated). This is the shared basis for all three
#' plot modes.
#'
#' Scans are clustered into time steps by walking the unique scan dates in
#' order. A new time step starts at a date when any of:
#'   1. a treatment date falls between the previous date and this one
#'      (highest priority - treatments always split a step),
#'   2. any site/plot combo scanned on this date was already scanned in the
#'      current step (a repeat visit signals a new sampling campaign;
#'      all scans on that date move to the new step together), or
#'   3. the gap from the previous scan date exceeds 30 days.
#' Plots appearing only once ("odd plots out") stay lumped with the step that
#' was open when they were scanned. `transform` is applied to the raw values
#' (e.g. gap fraction = 1 - canopyCover).
#'
#' Returns a data.table: site_name | plot | combo | label | scan_date | value
#' | grp. `combo` (site||plot) is the internal key used for repeat-visit
#' detection and per-plot grouping; `label` ("site / plot") is for legends.
assign_time_steps <- function(metrics_dt, metric_col, treat_dates,
                              transform = identity) {
  df <- data.table(
    site = as.character(metrics_dt$site),
    plot      = as.character(metrics_dt$plot),
    date = metrics_dt$date,
    value     = transform(
      suppressWarnings(as.numeric(metrics_dt[[metric_col]]))
    )
  )
  df[, combo := paste(site, plot, sep = "||")]
  df[, label := paste(site, plot, sep = " / ")]
  df <- df[!is.na(date) & !is.na(value)]
  if (nrow(df) == 0) return(df)
  setorder(df, date)

  tvec <- sort(treat_dates$TreatmentDate)
  tvec <- tvec[!is.na(tvec)]

  # Walk unique dates in order, assigning each date to a time-step group
  dates    <- sort(unique(df$date))
  date_grp <- integer(length(dates))
  seen     <- character()   # site/plot combos already in the current step
  g        <- 1L

  for (k in seq_along(dates)) {
    combos_today <- unique(df[date == dates[k], combo])

    if (k > 1) {
      treat_between <- length(tvec) > 0 &&
        any(tvec > dates[k - 1] & tvec <= dates[k])
      repeat_visit  <- any(combos_today %in% seen)
      gap_days      <- as.numeric(dates[k] - dates[k - 1])

      if (treat_between || repeat_visit || gap_days > 30) {
        g    <- g + 1L
        seen <- character()
      }
    }

    date_grp[k] <- g
    seen <- union(seen, combos_today)
  }

  df[, grp := date_grp[match(date, dates)]]
  df[]
}

#' Rewrite assign_time_steps() values as percent change from each site/plot's
#' OWN baseline - its earliest scan in the loaded set. Every series therefore
#' starts at 0% and the cards read as change since the first scan rather than
#' absolute units, which lets plots on different scales be compared directly.
#'
#' Baselines are per site/plot rather than a single pooled first time step:
#' plots are not all scanned on the same dates, and a pooled baseline would
#' fold between-plot differences into what should be a within-plot change.
#' Combos whose baseline is missing or zero are dropped - percent change from
#' zero is undefined. The divisor is abs(baseline) so the sign of the change
#' survives a negative baseline.
#'
#' Takes and returns the long table from assign_time_steps() (same columns),
#' so it slots in ahead of aggregate_time_steps() or straight into the
#' per-observation plot modes.
percent_change_series <- function(long) {
  if (nrow(long) == 0) return(long)

  df <- copy(long)
  setorder(df, combo, scan_date)
  df[, base := value[1L], by = combo]
  df <- df[is.finite(base) & base != 0]
  if (nrow(df) == 0) return(df)

  df[, value := (value - base) / abs(base) * 100]
  df[, base := NULL]
  setorder(df, date)
  df[]
}

#' Aggregate assign_time_steps() output to one row per time step:
#' t (mean date), mean, sd, n. Used by the "time series" and "bar" modes.
aggregate_time_steps <- function(df) {
  if (nrow(df) == 0) return(df)

  df[, .(
    t    = mean(date),
    mean = mean(value),
    sd   = sd(value),      # NA when a step holds a single scan
    n    = .N
  ), by = grp][order(t)]
}

# Most frequent value, at 3 significant figures. Lidar metrics are continuous
# measurements that essentially never repeat to full precision, so an exact
# mode is undefined; rounding first answers the question people actually mean
# ("what value did this group cluster on?"). NA when nothing repeats even at
# that precision - reported as a dash rather than a misleading first value.
.modal_value <- function(x) {
  v <- x[is.finite(x)]
  if (length(v) == 0) return(NA_real_)
  r <- signif(v, 3)
  u <- unique(r)
  cnt <- tabulate(match(r, u))
  if (max(cnt) < 2) return(NA_real_)
  u[which.max(cnt)]          # ties resolve to the first-occurring value
}

#' Descriptive statistics per time step, for the Statistics view on the plot
#' cards. Takes the long table from assign_time_steps() (optionally already
#' run through percent_change_series(), in which case the statistics describe
#' percent change) and returns one row per time step:
#'
#'   date | n | min | max | mean | median | mode | sd
#'
#' `date` is the step's mean scan date, matching the x positions the time
#' series and bar modes plot. `sd` is NA for a step holding a single scan.
describe_time_steps <- function(long) {
  if (nrow(long) == 0) return(data.table())

  long[, .(
    date   = mean(date),
    n      = .N,
    min    = min(value),
    max    = max(value),
    mean   = mean(value),
    median = median(value),
    mode   = .modal_value(value),
    sd     = sd(value)
  ), by = grp][order(date)]
}

#' assign_time_steps() + aggregate_time_steps() in one call, on raw values.
build_metric_series <- function(metrics_dt, metric_col, treat_dates,
                                transform = identity) {
  aggregate_time_steps(
    assign_time_steps(metrics_dt, metric_col, treat_dates, transform)
  )
}
