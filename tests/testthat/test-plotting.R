box::use(
  data.table[data.table],
  ggplot2[ggplot_build],
  testthat[describe, expect_equal, expect_null, expect_true, it],
)

box::use(
  app/view/plotting,
)

impl <- attr(plotting, "namespace")

# two plots scanned at the same three dates
scans <- data.table(
  site = rep(c("S1", "S2"), each = 3),
  plot = rep(c("P1", "P2"), each = 3),
  date = as.Date(rep(c("2021-06-01", "2023-06-01", "2025-06-01"), 2)),
  MDBH = c(10, 12, 14, 20, 21, 25)
)

data_state <- list(
  metric = "MDBH", label = "MDBH", data_type = "raw", data_dt = scans,
  trtmt_dates = data.table(TreatmentDate = as.Date(character()))
)

plot_with <- function(errorbars, plot_type = "timeseries") {
  plotting$metric_series_plot(
    data_state, list(errorbars = errorbars, treatlines = "off", plot_type = plot_type)
  )
}

# ymin / ymax of the error bar layer, NULL when the plot has none
errorbar_data <- function(p) {
  built <- ggplot_build(p)
  is_bar <- vapply(built$plot$layers, function(l) inherits(l$geom, "GeomErrorbar"), logical(1))
  if (!any(is_bar)) {
    return(NULL)
  }
  built$data[[which(is_bar)]][, c("ymin", "ymax")]
}

describe("error bars", {
  # per step: means 15, 16.5, 19.5; SDs of (10, 20), (12, 21), (14, 25)
  sds <- c(sd(c(10, 20)), sd(c(12, 21)), sd(c(14, 25)))
  means <- c(15, 16.5, 19.5)

  for (plot_type in c("timeseries", "bar")) {
    it(paste("span +/- 1 SD on the", plot_type, "plot"), {
      bars <- errorbar_data(plot_with("sd", plot_type))
      expect_equal(bars$ymin, means - sds)
      expect_equal(bars$ymax, means + sds)
    })

    it(paste("span +/- 1 SE (SD / sqrt(n)) on the", plot_type, "plot"), {
      bars <- errorbar_data(plot_with("se", plot_type))
      expect_equal(bars$ymax - bars$ymin, 2 * sds / sqrt(2))
    })
  }

  it("are left off when turned off", {
    expect_null(errorbar_data(plot_with("off")))
    expect_null(errorbar_data(plot_with("off", "bar")))
  })

  it("are named in the plot caption", {
    expect_true(grepl("SD", plot_with("sd")$labels$caption))
    expect_true(grepl("SE", plot_with("se", "bar")$labels$caption))
    expect_null(plot_with("off")$labels$caption)
  })

  it("have no width for a single-scan time step", {
    one <- data.table(step = 1, sd = NA_real_, n = 1L)
    expect_true(is.na(impl$.error_halfwidth(one, "se")))
  })
})
