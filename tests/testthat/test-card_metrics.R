box::use(
  data.table[data.table],
  ggplot2[ggplot_build],
  shiny[reactive, reactiveVal, testServer],
  testthat[describe, expect_equal, expect_true, it],
)

box::use(
  app/view/card_metrics[server],
)

# Two plots scanned in 2021, 2023 and 2025, with a treatment in 2022 that falls
# between the first two time steps.
scans <- data.table(
  site = rep(c("S1", "S2"), each = 3),
  plot = rep(c("P1", "P2"), each = 3),
  date = as.Date(rep(c("2021-06-01", "2023-06-01", "2025-06-01"), 2)),
  MDBH = c(10, 12, 14, 20, 21, 25)
)
treatments <- data.table(TreatmentDate = as.Date("2022-06-01"))

card_args <- function(plot_type) {
  list(
    session = NULL,
    data_dt = reactive(scans),
    metric_col = reactive("MDBH"),
    errorbars_on = reactive("on"),
    treatlines_on = reactive("on"),
    plot_type = reactive(plot_type),
    data_type = reactive("raw")
  )
}

has_vline <- function(p) {
  any(vapply(ggplot_build(p)$plot$layers, function(l) inherits(l$geom, "GeomVline"), logical(1)))
}

describe("card_metrics server", {
  it("passes the session's treatment dates to the plot builder", {
    testServer(server, args = card_args("timeseries"), {
      session$userData$trtmt_dates <- reactiveVal(treatments)
      expect_equal(data_state()$trtmt_dates, treatments)
    })
  })

  for (plot_type in c("timeseries", "individual", "boxplot", "bar")) {
    it(paste("draws treatment lines on the", plot_type, "plot"), {
      testServer(server, args = card_args(plot_type), {
        session$userData$trtmt_dates <- reactiveVal(treatments)
        expect_true(has_vline(plt_fn()))
        expect_true(has_vline(plt_fn(light = TRUE)))
      })
    })
  }
})
