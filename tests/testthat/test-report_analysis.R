box::use(
  data.table[data.table],
  testthat[describe, expect_equal, expect_length, expect_match, expect_null, expect_true, it],
)

box::use(
  app/logic/report_analysis,
)

impl <- attr(report_analysis, "namespace")

# Per-scan rows shaped like assign_time_steps() output: three plots scanned
# before (step 1) and after (step 2) a treatment on 03/01/2024, with midstory
# volume falling in every plot.
series <- function() {
  data.table(
    site = "A", plot = rep(c("1", "2", "3"), 2),
    combo = rep(c("A||1", "A||2", "A||3"), 2),
    date = as.Date(rep(c("2024-01-10", "2024-06-10"), each = 3)),
    value = c(10, 12, 14, 6, 7, 8),
    grp = rep(1:2, each = 3)
  )
}

describe("describe_series", {
  it("summarizes coverage, overall change and change across the treatment", {
    d <- report_analysis$describe_series(series(), "Midstory volume", FALSE,
                                         as.Date("2024-03-01"), "mMSvol")
    expect_match(d$summary, "six scans at three plots in two time steps")
    expect_match(d$summary, "12.0 in the first time step and 7.00 in the last")
    expect_match(d$summary, "a decrease of 5.00 \\(41.7%\\)")
    expect_match(d$summary, "the three plots scanned before and after decreased by 5.00")
    expect_match(d$implication, "^Midstory volume \\(3-9 m\\)")
    expect_match(d$implication, "Across the treatment on 03/01/2024, it decreased. A decrease")
    expect_match(d$implication, "reduced ladder fuels")
  })

  it("says so when no plot was scanned in every time step", {
    long <- series()
    long$combo <- paste0("A||", 1:6)
    d <- report_analysis$describe_series(long, "Midstory volume", FALSE)
    expect_true(any(grepl("None of the six plots was scanned in every time step", d$cautions)))
  })

  it("flags small time steps and plots missing from some steps", {
    long <- series()[-6]
    d <- report_analysis$describe_series(long, "Midstory volume", FALSE, as.Date("2024-03-01"))
    expect_true(any(grepl("fewer than three scans", d$cautions)))
    expect_true(any(grepl("Only two of three plots were scanned in every time step", d$cautions)))
  })

  it("flags a treatment with no scans on one side", {
    d <- report_analysis$describe_series(series(), "Midstory volume", FALSE,
                                         as.Date("2025-01-01"))
    expect_true(any(grepl("No scans were collected after the treatment on 01/01/2025",
                          d$cautions)))
  })

  it("describes percent change in percentage points and calls small changes stable", {
    long <- series()
    long$value <- c(0, 0, 0, 1, 2, 3)
    d <- report_analysis$describe_series(long, "Basal area (% change)", TRUE,
                                         metric = "Basalarea")
    expect_match(d$summary, "percent change from each plot's first scan")
    expect_match(d$summary, "an increase of 2.00 percentage points")
    expect_match(d$implication, "Over the period monitored, it changed little")
  })

  it("describes many scans in one time step as a snapshot", {
    long <- series()[grp == 1]
    d <- report_analysis$describe_series(long, "Something new", FALSE, as.Date("2024-03-01"))
    expect_length(d$cautions, 1)
    expect_match(d$cautions, "All three scans at three plots fall in one time step (01/10/2024)",
                 fixed = TRUE)
    expect_match(d$cautions, "snapshot of conditions")
    expect_match(d$cautions, "Change over time and treatment effects cannot be assessed")
    expect_match(d$cautions, "pre-treatment baseline")
    expect_null(d$implication)
  })

  it("gives a single scan its own notice", {
    long <- series()[1]
    d <- report_analysis$describe_series(long, "Basal area", FALSE, as.Date("2024-03-01"))
    expect_length(d$cautions, 1)
    expect_match(d$cautions, "Basal area is based on a single scan (A / 1, 01/10/2024)",
                 fixed = TRUE)
  })

})

describe("metric_context", {
  it("matches model outputs by words in their label", {
    expect_match(report_analysis$metric_context("Fernmod", "Fern cover (%)")$what, "^Cover")
    expect_match(report_analysis$metric_context("MDDmod", "Mean duff depth (cm)")$what, "depths")
    expect_null(report_analysis$metric_context("zzz", "Unrelated"))
  })
})

scans_fixture <- function() {
  metrics <- data.frame(
    site = "A", plot = c("1", "2", "3", "1", "2"),
    date = as.Date(c("2024-01-10", "2024-01-10", "2024-01-11", "2024-06-10", "2024-06-10"))
  )
  scans <- data.frame(
    site = metrics$site, plot = metrics$plot, date = metrics$date,
    Unit = c("North", "North", "My Unit", "North", "North"), Agency = "USFS"
  )
  list(metrics = metrics, scans = scans)
}

describe("scan_context", {
  it("describes scans, units and treatments, and tabulates plots and time steps", {
    f <- scans_fixture()
    ctx <- report_analysis$scan_context(f$metrics, f$scans, as.Date("2024-03-01"))
    expect_match(ctx$text, "five scans at three plots in one site")
    expect_match(ctx$text, "grouped into two time steps")
    expect_match(ctx$text, "provided by USFS")
    # the placeholder "My Unit" is not a management unit
    expect_match(ctx$text, "one management unit: North \\(two plots\\)")
    expect_match(ctx$treatments[1], "One treatment of unspecified type took place")
    expect_match(ctx$treatments[1], "A treatment was carried out on 03/01/2024\\.")
    expect_equal(ctx$plots$Unit, c("North", "North", ""))
    expect_equal(ctx$steps$Treatment, c("Before 03/01/2024", "After 03/01/2024"))
    expect_equal(ctx$steps$Dates[1], "01/10/2024 to 01/11/2024")
    expect_equal(ctx$treatment_table$Treatment, "Not given")
  })

  it("describes each treatment by type, timing and the plots scanned around it", {
    f <- scans_fixture()
    ctx <- report_analysis$scan_context(
      f$metrics, f$scans, as.Date(c("2024-03-01", "2024-08-01")),
      c("Prescribed fire", "Thinning, Piling and burning")
    )
    expect_match(ctx$treatments[1], paste(
      "Two treatments took place during the reporting period: one prescribed fire and one",
      "combined treatment\\."
    ))
    expect_match(ctx$treatments[1], paste(
      "A prescribed fire was carried out on 03/01/2024\\.",
      "All three plots had pre-treatment scans, most recently on 01/11/2024 \\(50 days",
      "before\\), and two were scanned after it, first on 06/10/2024 \\(101 days after\\)\\.",
      "Two plots were scanned both before and after it \\(North\\)"
    ))
    expect_match(ctx$treatments[1], paste(
      "The stand was thinned and fuels were piled and burned on 08/01/2024\\.",
      "No plots were scanned after it"
    ))
    # one paragraph, with no definitions of the treatment types
    expect_length(ctx$treatments, 1)
    expect_equal(ctx$steps$Treatment, c(
      "Before prescribed fire on 03/01/2024", "After prescribed fire on 03/01/2024"
    ))
    expect_equal(ctx$treatment_table$Treatment, c("Prescribed fire", "Thinning, Piling and burning"))
    expect_equal(ctx$treatment_table$`Plots scanned before and after`, c(2L, 0L))
  })

  it("spells out counts below ten and counts that start a sentence", {
    impl <- attr(report_analysis, "namespace")
    expect_equal(impl$plural(c(1, 3, 12), "plot"), c("one plot", "three plots", "12 plots"))
    expect_equal(impl$num_start(c(3, 12, 45)), c("Three", "Twelve", "Forty-five"))
    expect_equal(impl$days_text(c(1)), "1 day")
  })

  it("names two treatments of one type in the overview", {
    f <- scans_fixture()
    ctx <- report_analysis$scan_context(
      f$metrics, f$scans, as.Date(c("2024-03-01", "2024-08-01")), c("Herbicide", "Herbicide")
    )
    expect_match(ctx$treatments, "^Two herbicide applications took place during the reporting period\\.")
    expect_match(ctx$treatments, "Herbicide was applied on 03/01/2024\\.")
  })

  it("says what was done for each treatment type", {
    impl <- attr(report_analysis, "namespace")
    expect_equal(impl$treatment_action("Herbicide", as.Date("2025-05-15")),
                 "Herbicide was applied on 05/15/2025.")
    expect_equal(impl$treatment_action("Grazing, Planting and seeding", as.Date("2025-05-15")),
                 paste("Livestock grazed the area and plants were established by planting",
                       "or seeding on 05/15/2025."))
  })

  it("says when no treatments were entered", {
    f <- scans_fixture()
    ctx <- report_analysis$scan_context(f$metrics, f$scans, as.Date(character()))
    expect_match(ctx$treatments, "No treatment dates were entered")
    expect_null(ctx$treatment_table)
  })

  it("lists several management units", {
    f <- scans_fixture()
    f$scans$Unit <- c("North", "North", "South", "North", "North")
    ctx <- report_analysis$scan_context(f$metrics, f$scans, as.Date(character()))
    expect_match(ctx$text, "two management units: North \\(two plots\\) and South \\(one plot\\)")
  })

  it("uses the Scan grouping set on the Set Treatments tab", {
    f <- scans_fixture()
    f$scans$ScanGroup <- c(1L, 1L, 2L, 3L, 3L)
    ctx <- report_analysis$scan_context(f$metrics, f$scans, as.Date(character()))
    expect_match(ctx$text, "grouped into three time steps")
    expect_equal(ctx$steps$Scans, c(2, 1, 2))
  })

  it("returns NULL with no scans", {
    expect_null(report_analysis$scan_context(data.frame(), NULL, as.Date(character())))
  })
})

describe("design_checks", {
  it("flags single-scan plots, small and unbalanced steps and unpaired treatments", {
    f <- scans_fixture()
    checks <- report_analysis$design_checks(f$metrics, f$scans, as.Date("2024-03-01"))
    expect_true(any(grepl("One of three plots has a single scan", checks)))
    expect_true(any(grepl("fewer than three scans", checks)))
    expect_true(any(grepl("Two of three plots were scanned both before and after", checks)))
  })

  it("reports one time step as a snapshot instead of listing each plot", {
    metrics <- data.frame(
      site = "A", plot = c("1", "2", "3"),
      date = as.Date(c("2024-06-10", "2024-06-11", "2024-06-11"))
    )
    checks <- report_analysis$design_checks(metrics, NULL, as.Date("2024-03-01"))
    expect_length(checks, 1)
    expect_match(checks, "All three scans at three plots fall in one time step (06/10/2024 to 06/11/2024)",
                 fixed = TRUE)
    expect_match(checks, "with no pre-treatment scans to compare against")
  })

  it("reports a single loaded scan", {
    metrics <- data.frame(site = "A", plot = "1", date = as.Date("2024-06-10"))
    checks <- report_analysis$design_checks(metrics, NULL, as.Date(character()))
    expect_equal(length(checks), 1)
    expect_match(checks, "Only one scan is loaded (A / 1, 06/10/2024)", fixed = TRUE)
  })

  it("is empty for a balanced, paired design", {
    metrics <- data.frame(
      site = "A", plot = rep(c("1", "2", "3"), 2),
      date = as.Date(rep(c("2024-01-10", "2024-06-10"), each = 3))
    )
    expect_length(report_analysis$design_checks(metrics, NULL, as.Date("2024-03-01")), 0)
  })
})

describe("fmt_num", {
  it("keeps precision proportional to size", {
    expect_equal(impl$fmt_num(c(1234.4, 12.34, 1.234)), c("1,234", "12.3", "1.23"))
  })
})
