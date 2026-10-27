# ---------------------------------------------------------------------------
# Automated text for the report builder. Pure functions, no Shiny.
#
# * describe_series(): the analysis printed under each figure or table - what
#   the data cover, how the mean moved over time and across treatments, and
#   cautions about the sample behind it - plus an interpretation of what the
#   change implies for that metric (METRIC_CONTEXT).
# * scan_context(): the "Scans, plots and treatments" section - which plots,
#   dates, time steps, management units and treatments the report draws on.
# * design_checks(): the "Sample size and design" section - small samples and
#   lopsided designs across the whole set of loaded scans.
#
# All of them work on the same per-scan rows and time steps the cards plot
# (assign_time_steps() in app/logic/manage_timesteps.R), so the text always
# describes what the figures show.
# ---------------------------------------------------------------------------

box::use(
  data.table[as.data.table, data.table, uniqueN],
  stats[na.omit, sd],
)

box::use(
  app/logic/constants[TREATMENT_ACTIONS, TREATMENT_NOUNS],
  app/logic/manage_timesteps[assign_time_steps],
)

#' Fewest scans in a time step before its mean is flagged as uncertain.
#' @export
MIN_SCANS <- 3L

#' Fewest plots (overall, or per management unit) before it is flagged.
#' @export
MIN_PLOTS <- 3L

# A change smaller than this is described as "little change": a fraction of
# the starting mean for values, or percentage points for percent change.
LITTLE_RELATIVE <- 0.05
LITTLE_POINTS <- 5

# What each metric measures and what an increase or decrease implies. Keys are
# metric columns; KEYWORD_CONTEXT covers model outputs by words in their label.
METRIC_CONTEXT <- list(
  mGCvol = list(
    what = paste(
      "Ground cover volume (0-1 m) reflects surface vegetation and fine fuels near the ground."
    ),
    up = paste(
      "An increase points to more surface fuel and vegetation regrowth, which can raise surface",
      "fire intensity."
    ),
    down = paste(
      "A decrease points to consumption or removal of surface vegetation, as expected after",
      "prescribed fire, and lower surface fuel loads."
    )
  ),
  mUSvol = list(
    what = paste(
      "Understory volume (1-3 m) reflects the shrub and sapling layer, an important ladder fuel."
    ),
    up = paste(
      "An increase points to growth of shrubs and saplings and greater vertical fuel continuity."
    ),
    down = "A decrease points to a reduction of shrub and sapling ladder fuels."
  ),
  mMSvol = list(
    what = paste(
      "Midstory volume (3-9 m) reflects vegetation that can carry fire from the surface into the",
      "canopy."
    ),
    up = "An increase points to midstory regrowth and increasing ladder fuel continuity.",
    down = paste(
      "A decrease points to reduced ladder fuels and a lower chance of fire moving into the",
      "canopy."
    )
  ),
  mOSvol = list(
    what = "Overstory volume (above 9 m) reflects the main forest canopy.",
    up = "An increase points to canopy growth or closure.",
    down = "A decrease points to canopy loss, for example from thinning, crown scorch or mortality."
  ),
  Basalarea = list(
    what = "Basal area measures stand density as the cross-sectional area of tree stems.",
    up = "An increase points to tree growth or ingrowth adding to stand density.",
    down = paste(
      "A decrease points to tree removal or mortality, as expected after thinning or severe",
      "fire."
    )
  ),
  MDBH = list(
    what = "Mean DBH describes the average tree diameter.",
    up = "An increase is typical when small trees are removed or the remaining trees grow.",
    down = "A decrease points to ingrowth of small trees or the loss of large trees."
  ),
  StemsPacre = list(
    what = "Stems per acre measures tree density.",
    up = "An increase points to regeneration or ingrowth.",
    down = "A decrease points to thinning or mortality."
  ),
  TreesN = list(
    what = "The number of trees counts the stems detected in each plot.",
    up = "An increase points to regeneration or ingrowth.",
    down = "A decrease points to thinning or mortality."
  ),
  MeanTH = list(
    what = "Mean tree height describes the average height of the trees.",
    up = "An increase points to growth or the removal of shorter trees.",
    down = "A decrease points to the loss of tall trees or ingrowth of short trees."
  ),
  MaxTH = list(
    what = "Maximum tree height is the height of the tallest tree in each plot.",
    up = "An increase reflects growth of the tallest trees.",
    down = "A decrease points to the loss of the tallest trees."
  ),
  CBH = list(
    what = "Canopy base height is the height at which canopy fuels begin.",
    up = "A higher canopy base makes it less likely that a surface fire will ignite the crowns.",
    down = "A lower canopy base makes it more likely that a surface fire will ignite the crowns."
  ),
  canopyCover = list(
    what = "Canopy cover is the share of the sky obscured by the canopy.",
    up = "An increase points to a denser canopy, more shading and greater crown fuel continuity.",
    down = "A decrease points to a more open canopy and lower crown fuel continuity."
  ),
  gapFraction = list(
    what = "Gap fraction is the share of open sky (1 - canopy cover).",
    up = "An increase points to a more open canopy and lower crown fuel continuity.",
    down = "A decrease points to canopy closure and greater crown fuel continuity."
  ),
  LAI = list(
    what = "Leaf area index measures the amount of foliage.",
    up = "An increase points to more foliage.",
    down = "A decrease points to foliage loss, for example from scorch, defoliation or removal."
  ),
  OLAI = list(
    what = "Overstory LAI measures foliage above 9 m.",
    up = "An increase points to more canopy foliage.",
    down = "A decrease points to loss of canopy foliage, for example from crown scorch or thinning."
  ),
  MLAI = list(
    what = "Midstory LAI measures foliage between 3 and 9 m, part of the ladder fuel layer.",
    up = "An increase points to more midstory foliage and ladder fuel.",
    down = "A decrease points to reduced midstory foliage and ladder fuel."
  ),
  ULAI = list(
    what = "Understory LAI measures foliage between 1 and 3 m.",
    up = "An increase points to more shrub and sapling foliage.",
    down = "A decrease points to reduced shrub and sapling foliage."
  ),
  ros_ch_hr = list(
    what = "Surface rate of spread is how fast a surface fire is expected to move.",
    up = "An increase means faster expected surface fire spread.",
    down = "A decrease means slower expected surface fire spread."
  ),
  fli_kw_m = list(
    what = "Fireline intensity is the expected heat release along the flaming front.",
    up = "An increase means more intense surface fire that is harder to control.",
    down = "A decrease means less intense surface fire that is easier to control."
  ),
  flame_ft = list(
    what = "Flame length is the expected length of the surface fire flames.",
    up = paste(
      "Longer flames mean more intense fire and a greater chance of scorching or igniting the",
      "canopy."
    ),
    down = paste(
      "Shorter flames mean less intense fire and a lower chance of scorching or igniting the",
      "canopy."
    )
  ),
  rxn_int = list(
    what = "Reaction intensity is the rate of heat release per unit area of the flaming zone.",
    up = "An increase means more energy released by the burning surface fuels.",
    down = "A decrease means less energy released by the burning surface fuels."
  ),
  hpa = list(
    what = "Heat per unit area is the total heat released as the flaming front passes.",
    up = "An increase means more total heat released by the surface fire.",
    down = "A decrease means less total heat released by the surface fire."
  ),
  crown_Io = list(
    what = "Crown-initiation intensity is the fireline intensity needed to ignite the crowns.",
    up = paste(
      "An increase means a more intense surface fire is needed to start a crown fire, a lower",
      "crown fire hazard."
    ),
    down = "A decrease means crown fires start more easily, a higher crown fire hazard."
  ),
  crown_Ro = list(
    what = paste(
      "Critical active-crown spread rate is the spread rate needed to sustain an active crown",
      "fire."
    ),
    up = "An increase means active crown fire is harder to sustain.",
    down = "A decrease means active crown fire is easier to sustain."
  ),
  torching_idx = list(
    what = paste(
      "The torching index is the wind speed at which surface fire is expected to ignite tree",
      "crowns."
    ),
    up = "An increase means torching requires stronger winds, a lower crown fire hazard.",
    down = "A decrease means torching can occur at lower wind speeds, a higher crown fire hazard."
  ),
  crowning_idx = list(
    what = "The crowning index is the wind speed needed to sustain an active crown fire.",
    up = "An increase means active crown fire requires stronger winds, a lower crown fire hazard.",
    down = "A decrease means active crown fire can be sustained at lower wind speeds."
  ),
  fire_type_num = list(
    what = paste(
      "Crown fire type classifies expected fire behavior as surface (0), passive crown (1) or",
      "active crown (2)."
    ),
    up = "An increase means expected fire behavior shifted toward crown fire.",
    down = "A decrease means expected fire behavior shifted toward surface fire."
  )
)
METRIC_CONTEXT$ros_m_min <- METRIC_CONTEXT$ros_ch_hr
METRIC_CONTEXT$flame_m <- METRIC_CONTEXT$flame_ft

# Model outputs (Custom models tab), matched by words in their label.
KEYWORD_CONTEXT <- list(
  "basal area" = METRIC_CONTEXT$Basalarea,
  "depth" = list(
    what = paste(
      "Fuel bed, litter and duff depths describe how much fuel has accumulated on the forest",
      "floor."
    ),
    up = "An increase points to fuel accumulation on the forest floor.",
    down = "A decrease points to consumption by fire or decomposition of forest floor fuels."
  ),
  "fuel count" = list(
    what = "Time-lag fuel counts describe downed woody fuels by size class.",
    up = "An increase points to more downed woody fuel.",
    down = "A decrease points to less downed woody fuel, for example from consumption by fire."
  ),
  "cover" = list(
    what = "Cover describes the share of the plot occupied by this fuel or vegetation type.",
    up = "An increase points to more of this fuel or vegetation type.",
    down = "A decrease points to less of this fuel or vegetation type."
  )
)

#' Context for a metric: its METRIC_CONTEXT entry, else the first
#' KEYWORD_CONTEXT entry whose keyword appears in the label, else NULL.
#' @export
metric_context <- function(metric, label = "") {
  if (!is.null(metric) && !is.null(METRIC_CONTEXT[[metric]])) return(METRIC_CONTEXT[[metric]])
  hit <- Filter(function(k) grepl(k, tolower(label), fixed = TRUE), names(KEYWORD_CONTEXT))
  if (length(hit) > 0) KEYWORD_CONTEXT[[hit[[1]]]] else NULL
}

#' Format a number for prose: precision follows its size.
#' @export
fmt_num <- function(x) {
  digits <- ifelse(abs(x) >= 100, 0, ifelse(abs(x) >= 10, 1, 2))
  vapply(seq_along(x), function(i) {
    formatC(x[i], format = "f", digits = digits[i], big.mark = ",")
  }, character(1))
}

# Dates in report text and tables: MM/DD/YYYY (REPORT_DATE in app/logic/report.R)
fmt_date <- function(d) format(as.Date(d), "%m/%d/%Y")

and_list <- function(x) {
  if (length(x) <= 1) return(paste(x, collapse = ""))
  paste(paste(x[-length(x)], collapse = ", "), "and", x[length(x)])
}

# Counts in report text: numbers below ten are spelled out ("three plots");
# num_start() also spells out a count that starts a sentence ("Twelve plots").
ONES <- c("zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
          "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
          "seventeen", "eighteen", "nineteen")
TENS <- c("", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety")

number_word <- function(n) {
  if (n < 20) return(ONES[n + 1])
  if (n < 100) return(paste0(TENS[n %/% 10 + 1], if (n %% 10 > 0) paste0("-", ONES[n %% 10 + 1])))
  format(n, big.mark = ",")
}

num <- function(n) {
  vapply(n, function(x) {
    if (x >= 0 && x < 10 && x == round(x)) ONES[x + 1] else format(x, big.mark = ",")
  }, character(1))
}

num_start <- function(n) {
  vapply(n, function(x) {
    capitalize(if (x >= 0 && x == round(x)) number_word(x) else format(x, big.mark = ","))
  }, character(1))
}

capitalize <- function(x) paste0(toupper(substring(x, 1, 1)), substring(x, 2))

#' A count and its noun for report text: "three plots", "12 scans", "one site".
#' @export
plural <- function(n, word, words = paste0(word, "s")) paste(num(n), ifelse(n == 1, word, words))

#' One row per time step: dates, scans, plots, mean and SD of `value`.
#' @export
series_steps <- function(long) {
  long <- as.data.table(long)
  long[, list(
    start = min(date), end = max(date), mid = mean(date),
    n = .N, plots = uniqueN(combo), mean = mean(value), sd = sd(value)
  ), by = grp][order(mid)]
}

# Direction of a change, judged against LITTLE_* so noise isn't overstated.
direction <- function(diff, base, pct) {
  little <- if (pct) abs(diff) < LITTLE_POINTS else abs(diff) < LITTLE_RELATIVE * abs(base)
  if (!is.finite(diff) || little) "flat" else if (diff > 0) "up" else "down"
}

# Size of a change: "4.2 percentage points" for percent change, else "1.30
# (12%)" with the change relative to its starting value.
magnitude <- function(diff, base, pct) {
  if (pct) return(paste(fmt_num(abs(diff)), "percentage points"))
  rel <- if (is.finite(base) && base != 0) {
    sprintf(" (%s%%)", fmt_num(abs(diff) / abs(base) * 100))
  } else {
    ""
  }
  paste0(fmt_num(abs(diff)), rel)
}

change_phrase <- function(diff, base, pct) {
  paste(if (diff >= 0) "an increase of" else "a decrease of", magnitude(diff, base, pct))
}

# Within-plot change across a treatment date: each plot's last scan before it
# against its first scan on or after it. NULL when no plot has both.
paired_change <- function(long, tdate) {
  before <- long[date < tdate][order(date), list(b = value[.N]), by = combo]
  after <- long[date >= tdate][order(date), list(a = value[1L]), by = combo]
  both <- merge(before, after, by = "combo")
  if (nrow(both) == 0) return(NULL)
  d <- both$a - both$b
  list(n = nrow(both), mean = mean(d), base = mean(both$b), min = min(d), max = max(d))
}

#' Automated description of one card's data.
#'
#' @param long Per-scan rows from assign_time_steps() (after
#'   percent_change_series() for percent change): site, plot, combo, date,
#'   value, grp.
#' @param label Metric label used in the text.
#' @param pct TRUE when `value` is percent change from each plot's first scan.
#' @param treat_dates Treatment dates (Date).
#' @param metric Metric column, for the interpretation lookup.
#' @return list(summary = paragraph, cautions = character(), implication = text or NULL)
#' @export
describe_series <- function(long, label, pct = FALSE, treat_dates = as.Date(character()),
                            metric = NULL) {
  long <- as.data.table(long)
  if (nrow(long) == 0) {
    return(list(summary = "No values were available for this metric.", cautions = character(),
                implication = NULL))
  }
  steps <- series_steps(long)
  k <- nrow(steps)
  n_plots <- uniqueN(long$combo)
  units <- if (pct) " percent change from each plot's first scan" else ""

  s <- sprintf(
    "%s summarizes %s at %s in %s, from %s to %s.",
    label, plural(nrow(long), "scan"), plural(n_plots, "plot"), plural(k, "time step"),
    fmt_date(min(long$date)), fmt_date(max(long$date))
  )

  overall <- NULL
  if (k > 1) {
    first <- steps$mean[1]
    last <- steps$mean[k]
    overall <- list(diff = last - first, base = first)
    s <- c(s, sprintf(
      "The mean%s was %s in the first time step and %s in the last, %s.",
      units, fmt_num(first), fmt_num(last), change_phrase(last - first, first, pct)
    ))
    if (k > 2) {
      jumps <- diff(steps$mean)
      j <- which.max(abs(jumps))
      s <- c(s, sprintf(
        "The largest change between consecutive time steps was %s, between %s and %s.",
        change_phrase(jumps[j], steps$mean[j], pct),
        fmt_date(steps$mid[j]), fmt_date(steps$mid[j + 1])
      ))
    }
  }

  cautions <- character()
  treat_change <- NULL
  tvec <- sort(as.Date(treat_dates))

  if (nrow(long) == 1) {
    # one scan: nothing to compare, so a single notice replaces the others
    cautions <- sprintf(
      paste(
        "%s is based on a single scan (%s / %s, %s). It describes that plot on that date",
        "only and shows neither variation between plots nor change over time."
      ),
      label, long$site, long$plot, fmt_date(long$date)
    )
  } else if (k == 1) {
    # many scans in one time step: a snapshot, not a change
    cautions <- snapshot_notice(
      "these data", nrow(long), n_plots, min(long$date), max(long$date), tvec
    )
    if (n_plots < MIN_PLOTS) {
      cautions <- c(cautions, sprintf(
        "Only %s contributed, too few to generalize beyond the plots themselves.",
        plural(n_plots, "plot")
      ))
    }
  } else {
    for (t in as.list(tvec)) {
      if (!any(long$date < t) || !any(long$date >= t)) {
        cautions <- c(cautions, sprintf(
          "No scans were collected %s the treatment on %s, so its effect on %s cannot be assessed.",
          if (any(long$date < t)) "after" else "before", fmt_date(t), label
        ))
        next
      }
      pc <- paired_change(long, t)
      if (is.null(pc)) {
        cautions <- c(cautions, sprintf(
          paste(
            "No plot was scanned both before and after the treatment on %s;",
            "the comparison mixes different plots."
          ),
          fmt_date(t)
        ))
        next
      }
      if (is.null(treat_change)) treat_change <- c(pc, list(date = t))
      s <- c(s, sprintf(
        paste(
          "Across the treatment on %s, the %s scanned before and after %s by %s on average",
          "(range %s to %s)."
        ),
        fmt_date(t), plural(pc$n, "plot"), if (pc$mean >= 0) "increased" else "decreased",
        magnitude(pc$mean, pc$base, pct), fmt_num(pc$min), fmt_num(pc$max)
      ))
    }

    small <- steps[n < MIN_SCANS]
    if (nrow(small) > 0) {
      cautions <- c(cautions, sprintf(
        "%s fewer than %s scans (%s), so %s uncertain.",
        if (nrow(small) == 1) "One time step holds" else paste(num_start(nrow(small)), "time steps hold"),
        num(MIN_SCANS), and_list(sprintf("%s: n = %d", fmt_date(small$mid), small$n)),
        if (nrow(small) == 1) "its mean is" else "their means are"
      ))
    }
    if (max(steps$n) >= 2 * min(steps$n)) {
      cautions <- c(cautions, sprintf(
        "Time steps hold uneven numbers of scans (%s to %s), so some steps carry more weight.",
        num(min(steps$n)), num(max(steps$n))
      ))
    }
    in_all <- long[, list(steps = uniqueN(grp)), by = combo][steps == k, .N]
    if (in_all < n_plots) {
      cautions <- c(cautions, paste(
        if (in_all == 0) {
          sprintf("None of the %s was scanned in every time step;", plural(n_plots, "plot"))
        } else {
          sprintf("Only %s of %s %s scanned in every time step;", num(in_all),
                  plural(n_plots, "plot"), if (in_all == 1) "was" else "were")
        },
        "differences between steps partly reflect which plots were scanned."
      ))
    }
    if (n_plots < MIN_PLOTS) {
      cautions <- c(cautions, sprintf(
        "Only %s contributed, too few to generalize beyond the plots themselves.",
        plural(n_plots, "plot")
      ))
    }
  }

  basis <- if (is.null(treat_change)) {
    if (!is.null(overall)) c(overall, list(when = "Over the period monitored"))
  } else {
    list(diff = treat_change$mean, base = treat_change$base,
         when = paste("Across the treatment on", fmt_date(treat_change$date)))
  }
  list(
    summary = paste(s, collapse = " "),
    cautions = cautions,
    implication = implication_text(metric, label, basis, pct)
  )
}

# Interpretation: what the metric measures, which change is being read and
# what its direction implies. `basis` is list(diff, base, when) - the change
# across the first assessable treatment, else from the first to the last time
# step - or NULL when there is no change to read.
implication_text <- function(metric, label, basis, pct) {
  ctx <- metric_context(metric, label)
  if (is.null(ctx)) return(NULL)
  if (is.null(basis)) return(ctx$what)
  switch(direction(basis$diff, basis$base, pct),
    up = paste(ctx$what, paste0(basis$when, ", it increased."), ctx$up),
    down = paste(ctx$what, paste0(basis$when, ", it decreased."), ctx$down),
    flat = paste(ctx$what, paste0(basis$when, ", it changed little,"),
                 "suggesting this attribute was largely unaffected.")
  )
}

# Scans keyed as "site|plot|date" for matching metrics to the scan selection.
scan_key <- function(d) paste(d$site, d$plot, fmt_date(d$date), sep = "|")

#' Time steps of all loaded scans (the grouping the cards use, without a metric):
#' the Scan grouping on the scan selection `scans`, where set.
#' @export
scan_steps <- function(metrics, treat_dates, scans = NULL) {
  m <- as.data.table(metrics)[, list(site, plot, date = as.Date(date))]
  m$one <- 1
  assign_time_steps(m, "one", data.table(TreatmentDate = as.Date(treat_dates)),
                    scan_groups = scans)
}

# Unit name the Selection Map gives every scan until one is assigned on the
# Set Treatments tab; treated as no unit.
DEFAULT_UNIT <- "My Unit"

# Each scan's management unit from the Set Treatments assignments (NA if none).
scan_units <- function(metrics, scans) {
  if (is.null(scans) || nrow(scans) == 0 || !"Unit" %in% names(scans)) {
    return(rep(NA_character_, nrow(metrics)))
  }
  unit <- as.character(scans$Unit)[match(scan_key(metrics), scan_key(scans))]
  unit[!is.na(unit) & (unit == DEFAULT_UNIT | !nzchar(trimws(unit)))] <- NA_character_
  unit
}

# Loaded scans as site, plot, date, unit and combo ("site / plot").
scan_table <- function(metrics, scans) {
  m <- as.data.table(metrics)[, list(
    site = as.character(site), plot = as.character(plot), date = as.Date(date)
  )]
  m[, unit := scan_units(m, scans)]
  m[, combo := paste(site, plot, sep = " / ")]
  m
}

date_range <- function(start, end) {
  ifelse(start == end, fmt_date(start), paste(fmt_date(start), "to", fmt_date(end)))
}

# Treatment dates and types as a table sorted by date: date | type, one row
# per date. `types` lines up with `dates`; missing or blank types are NA.
treatment_table <- function(dates, types = NULL) {
  dates <- as.Date(dates)
  if (length(types) != length(dates)) types <- rep(NA_character_, length(dates))
  types <- as.character(types)
  types[!is.na(types) & !nzchar(trimws(types))] <- NA_character_
  tr <- data.table(date = dates, type = types)[!is.na(date)]
  unique(tr, by = "date")[order(date)]
}

# A treatment's name in a sentence: "prescribed fire", "thinning and piling
# and burning"; "a treatment" when no type was given.
treatment_name <- function(type) {
  if (is.na(type)) return("a treatment")
  and_list(tolower(trimws(strsplit(type, ",")[[1]])))
}

# What was done, as a sentence: "Herbicide was applied on 05/15/2025.",
# "The stand was thinned and fuels were piled and burned on 05/15/2025."
treatment_action <- function(type, date) {
  types <- if (is.na(type)) character() else trimws(strsplit(type, ",")[[1]])
  known <- types %in% names(TREATMENT_ACTIONS)
  actions <- c(unname(TREATMENT_ACTIONS[types[known]]), tolower(types[!known]))
  if (length(actions) == 0) actions <- "a treatment was carried out"
  sprintf("%s on %s.", capitalize(and_list(actions)), fmt_date(date))
}

# Days between a treatment and a scan, in digits: "555 days", "1 day".
days_text <- function(n) {
  n <- as.integer(n)
  paste(format(n, big.mark = ","), if (n == 1) "day" else "days")
}

# One sentence group per treatment: what was done and when, which plots were
# scanned before and after it and how long before and after, and whether its
# effects can be assessed.
treatment_sentences <- function(m, t, type) {
  n_plots <- uniqueN(m$combo)
  before <- m[date < t]
  after <- m[date >= t]
  paired <- intersect(before$combo, after$combo)
  head <- treatment_action(type, t)
  if (nrow(before) == 0 || nrow(after) == 0) {
    return(paste(head, sprintf(
      "No plots were scanned %s it, so its effects cannot be assessed from these data.",
      if (nrow(before) == 0) "before" else "after"
    )))
  }
  n_before <- uniqueN(before$combo)
  n_after <- uniqueN(after$combo)
  pre <- sprintf("most recently on %s (%s before)", fmt_date(max(before$date)),
                 days_text(t - max(before$date)))
  post <- sprintf("first on %s (%s after)", fmt_date(min(after$date)),
                  days_text(min(after$date) - t))
  text <- if (n_plots == 1) {
    sprintf("The plot was scanned before it, %s, and after it, %s.", pre, post)
  } else {
    sprintf(
      "%s had pre-treatment scans, %s, and %s %s scanned after it, %s.",
      if (n_before == n_plots) paste("All", num(n_plots), "plots") else
        paste(num_start(n_before), "of the", num(n_plots), "plots"),
      pre, num(n_after), if (n_after == 1) "was" else "were", post
    )
  }
  text <- paste(head, text)
  if (length(paired) == 0) {
    return(paste(text, "No plot was scanned both before and after it, so its effects",
                 "can only be compared between different plots."))
  }
  units <- sort(unique(na.omit(m[combo %in% paired, unit])))
  who <- if (length(paired) == n_plots) {
    if (n_plots == 1) "The plot was" else paste("All", num(n_plots), "plots were")
  } else {
    paste(num_start(length(paired)), if (length(paired) == 1) "plot was" else "plots were")
  }
  paste(text, sprintf(
    "%s scanned both before and after it%s, giving a direct before-and-after comparison.",
    who, if (length(units) > 0) paste0(" (", and_list(units), ")") else ""
  ))
}

# What the overview calls one or several treatments of a type ("prescribed
# fire" / "prescribed fires"); combined and unspecified treatments get their
# own names.
treatment_noun <- function(type, n) {
  forms <- if (is.na(type)) {
    c("treatment of unspecified type", "treatments of unspecified type")
  } else if (type %in% names(TREATMENT_NOUNS)) {
    TREATMENT_NOUNS[[type]]
  } else if (grepl(",", type)) {
    c("combined treatment", "combined treatments")
  } else {
    paste(tolower(type), c("treatment", "treatments"))
  }
  if (n == 1) forms[1] else forms[2]
}

# The treatment paragraph: how many treatments of each type took place, then
# one passage per treatment.
treatment_paragraphs <- function(m, tr) {
  counts <- tr[, list(n = .N, first = min(date)), by = type][order(first)]
  nouns <- vapply(seq_len(nrow(counts)), function(i) {
    paste(num(counts$n[i]), treatment_noun(counts$type[i], counts$n[i]))
  }, character(1))
  intro <- if (nrow(counts) == 1) {
    sprintf("%s %s took place during the reporting period.", num_start(counts$n),
            treatment_noun(counts$type, counts$n))
  } else {
    sprintf("%s treatments took place during the reporting period: %s.", num_start(nrow(tr)),
            and_list(nouns))
  }
  each <- vapply(seq_len(nrow(tr)), function(i) {
    treatment_sentences(m, tr$date[i], tr$type[i])
  }, character(1))
  paste(c(intro, each), collapse = " ")
}

#' The "Scans, plots and treatments" section.
#' @param metrics Loaded metrics (site, plot, date, ...).
#' @param scans The scan selection with Unit and Agency (Set Treatments).
#' @param treat_dates Treatment dates (Date).
#' @param treat_types What was done on each treatment date (Set Treatments),
#'   lined up with `treat_dates`: NA when not given, several types joined
#'   with commas.
#' @return list(text, treatments, plots, steps, treatment_table) - a paragraph,
#'   the treatment paragraphs and three data.frames (treatment_table is NULL
#'   without treatment dates) - or NULL when no scans are loaded.
#' @export
scan_context <- function(metrics, scans, treat_dates, treat_types = NULL) {
  if (is.null(metrics) || nrow(metrics) == 0) return(NULL)
  m <- scan_table(metrics, scans)
  tr <- treatment_table(treat_dates, treat_types)
  tvec <- tr$date
  steps <- scan_steps(m, tvec, scans)

  units <- m[!is.na(unit), list(plots = uniqueN(combo)), by = unit][order(unit)]
  agencies <- if (!is.null(scans) && "Agency" %in% names(scans)) {
    sort(unique(na.omit(scans$Agency)))
  }

  text <- sprintf(
    "This report draws on %s at %s in %s, collected between %s and %s and grouped into %s.",
    plural(nrow(m), "scan"), plural(uniqueN(m$combo), "plot"), plural(uniqueN(m$site), "site"),
    fmt_date(min(m$date)), fmt_date(max(m$date)), plural(uniqueN(steps$grp), "time step")
  )
  if (length(agencies) > 0) {
    text <- paste(text, sprintf("Data were provided by %s.", and_list(agencies)))
  }
  if (nrow(units) > 0) {
    text <- paste(text, sprintf(
      "Plots are assigned to %s: %s.", plural(nrow(units), "management unit"),
      and_list(sprintf("%s (%s)", units$unit, plural(units$plots, "plot")))
    ))
  }
  treatments <- if (length(tvec) == 0) {
    paste(
      "No treatment dates were entered, so time steps are separated only by repeat visits",
      "and gaps between scans."
    )
  } else {
    treatment_paragraphs(m, tr)
  }

  plots <- m[, list(
    Unit = paste(sort(unique(na.omit(unit))), collapse = ", "),
    Scans = uniqueN(date), `First scan` = fmt_date(min(date)), `Last scan` = fmt_date(max(date))
  ), by = list(Site = site, Plot = plot)][order(Site, Plot)]
  if (all(!nzchar(plots$Unit))) plots$Unit <- NULL

  st <- steps[, list(start = min(date), end = max(date), scans = .N, plots = uniqueN(combo)),
              by = grp][order(start)]
  step_table <- data.frame(
    `Time step` = seq_len(nrow(st)), Dates = date_range(st$start, st$end),
    Scans = st$scans, Plots = st$plots,
    check.names = FALSE, stringsAsFactors = FALSE
  )
  treat_table <- NULL
  if (length(tvec) > 0) {
    # "After prescribed fire on 2025-05-15", or "After 2025-05-15" without a type
    label <- ifelse(is.na(tr$type), fmt_date(tr$date), paste(
      vapply(tr$type, treatment_name, character(1)), "on", fmt_date(tr$date)
    ))
    step_table$Treatment <- vapply(seq_len(nrow(st)), function(i) {
      after <- which(tvec <= st$start[i])
      if (length(after) > 0) paste("After", label[max(after)]) else paste("Before", label[1])
    }, character(1))

    n_before <- function(t) uniqueN(m[date < t, combo])
    n_after <- function(t) uniqueN(m[date >= t, combo])
    n_both <- function(t) length(intersect(m[date < t, combo], m[date >= t, combo]))
    treat_table <- data.frame(
      Date = fmt_date(tr$date),
      Treatment = ifelse(is.na(tr$type), "Not given", tr$type),
      `Plots scanned before` = vapply(as.list(tr$date), n_before, 1L),
      `Plots scanned after` = vapply(as.list(tr$date), n_after, 1L),
      `Plots scanned before and after` = vapply(as.list(tr$date), n_both, 1L),
      check.names = FALSE, stringsAsFactors = FALSE
    )
  }

  list(text = text, treatments = treatments, plots = as.data.frame(plots), steps = step_table,
       treatment_table = treat_table)
}

#' The "Sample size and design" checks across all loaded scans.
#' @return Character vector of findings; empty when nothing is flagged.
#' @export
design_checks <- function(metrics, scans, treat_dates) {
  if (is.null(metrics) || nrow(metrics) == 0) return(character())
  m <- scan_table(metrics, scans)
  tvec <- sort(unique(as.Date(treat_dates)))
  steps <- scan_steps(m, tvec, scans)
  n_plots <- uniqueN(m$combo)
  out <- character()

  if (nrow(m) == 1) {
    return(sprintf(
      paste(
        "Only one scan is loaded (%s, %s). The report describes that plot on that date only;",
        "variation between plots and change over time cannot be assessed."
      ),
      m$combo, fmt_date(m$date)
    ))
  }
  if (uniqueN(steps$grp) == 1) {
    # every scan in one time step: report it as a snapshot rather than
    # listing single-scan plots, small steps and unpaired treatments one by one
    out <- snapshot_notice("this report", nrow(m), n_plots, min(m$date), max(m$date), tvec)
  }

  if (n_plots < MIN_PLOTS) {
    out <- c(out, sprintf(
      "Only %s %s loaded. Results describe these plots and should not be generalized widely.",
      plural(n_plots, "plot"), if (n_plots == 1) "is" else "are"
    ))
  }
  if (uniqueN(steps$grp) > 1) {
    once <- m[, list(scans = uniqueN(date)), by = combo][scans == 1]
    if (nrow(once) > 0) {
      out <- c(out, sprintf(
        "%s of %s %s a single scan and cannot show change over time (%s).",
        num_start(nrow(once)), plural(n_plots, "plot"), if (nrow(once) == 1) "has" else "have",
        and_list(once$combo)
      ))
    }
    st <- steps[, list(mid = mean(date), n = .N), by = grp][order(mid)]
    small <- st[n < MIN_SCANS]
    if (nrow(small) > 0) {
      out <- c(out, sprintf(
        "%s of %s %s fewer than %s scans (%s); means for these steps are uncertain.",
        num_start(nrow(small)), plural(nrow(st), "time step"), if (nrow(small) == 1) "holds" else "hold",
        num(MIN_SCANS), and_list(sprintf("%s: n = %d", fmt_date(small$mid), small$n))
      ))
    }
    if (max(st$n) >= 2 * min(st$n)) {
      out <- c(out, sprintf(
        "Time steps are unbalanced, holding between %s and %s scans.", num(min(st$n)),
        num(max(st$n))
      ))
    }
  }
  units <- m[!is.na(unit), list(plots = uniqueN(combo)), by = unit]
  if (nrow(units) > 1) {
    few <- units[plots < MIN_PLOTS]
    if (nrow(few) > 0) {
      out <- c(out, sprintf(
        "%s fewer than %s plots (%s), too few for a reliable comparison between units.",
        if (nrow(few) == 1) "One management unit has" else
          paste(num_start(nrow(few)), "management units have"),
        num(MIN_PLOTS), and_list(sprintf("%s: %d", few$unit, few$plots))
      ))
    }
    if (max(units$plots) >= 2 * min(units$plots)) {
      out <- c(out, sprintf(
        paste(
          "Management units are unequal in size (%s to %s plots), so pooled results lean",
          "toward the larger units."
        ),
        num(min(units$plots)), num(max(units$plots))
      ))
    }
  }
  if (uniqueN(steps$grp) > 1) {
    for (t in as.list(tvec)) {
      before <- m[date < t, unique(combo)]
      after <- m[date >= t, unique(combo)]
      paired <- length(intersect(before, after))
      if (length(before) == 0 || length(after) == 0) {
        out <- c(out, sprintf(
          "No scans were collected %s the treatment on %s, so its effects cannot be assessed.",
          if (length(before) == 0) "before" else "after", fmt_date(t)
        ))
      } else if (paired < n_plots) {
        out <- c(out, sprintf(
          paste(
            "%s of %s %s scanned both before and after the treatment on %s; only these give",
            "a direct before-and-after comparison."
          ),
          num_start(paired), plural(n_plots, "plot"), if (paired == 1) "was" else "were", fmt_date(t)
        ))
      }
    }
  }
  out
}

# Notice for data that all fall in one time step: a snapshot of conditions,
# where the scans sit relative to any treatments, and a small-sample note.
# `subject` reads mid-sentence, e.g. "these data" or "this report".
snapshot_notice <- function(subject, n_scans, n_plots, start, end, tvec) {
  when <- if (start == end) fmt_date(start) else paste(fmt_date(start), "to", fmt_date(end))
  text <- sprintf(
    paste(
      "All %s at %s fall in one time step (%s), so %s is a snapshot of conditions at that",
      "time. Change over time%s cannot be assessed until the plots are scanned again."
    ),
    plural(n_scans, "scan"), plural(n_plots, "plot"), when, subject,
    if (length(tvec) > 0) " and treatment effects" else ""
  )
  after <- tvec[tvec > end]
  before <- tvec[tvec <= start]
  if (length(after) > 0) {
    text <- paste(text, sprintf(
      "The scans precede the treatment on %s and can serve as its pre-treatment baseline.",
      and_list(fmt_date(after))
    ))
  }
  if (length(before) > 0) {
    text <- paste(text, sprintf(
      "The scans follow the treatment on %s, with no pre-treatment scans to compare against.",
      and_list(fmt_date(before))
    ))
  }
  if (n_scans < MIN_SCANS) {
    text <- paste(text, sprintf("With only %s scans, the mean is uncertain.", num(n_scans)))
  }
  text
}
