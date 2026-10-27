box::use(
  data.table[data.table],
  testthat[describe, expect_equal, it],
)

box::use(
  app/logic/manage_data,
)

describe("remeasurement_numbers", {
  it("counts each plot's visits from 0, however close together", {
    scans <- data.table(
      site = c("A", "A", "A", "B", "A"),
      plot = c("1", "1", "2", "1", "1"),
      date = as.Date(c("2024-05-02", "2024-05-01", "2024-05-10", "2024-08-01", "2025-05-01"))
    )
    expect_equal(manage_data$remeasurement_numbers(scans), c(1L, 0L, 0L, 0L, 2L))
  })

  it("gives scans of a plot on the same date the same number", {
    scans <- data.table(site = "A", plot = "1", date = as.Date(c("2024-05-01", "2024-05-01")))
    expect_equal(manage_data$remeasurement_numbers(scans), c(0L, 0L))
  })
})

sel <- data.table(
  site = "A", plot = c("1", "2", "3"),
  date = as.Date(c("2024-01-01", "2024-01-01", "2024-02-01")),
  scanner_id = 1L, Unit = c("North", "North", "South")
)
metrics <- data.table(sel[1:2, .(site, plot, date, scanner_id)], Basalarea = c(10, 20))

describe("keep_downloaded", {
  it("puts back downloaded scans dropped from the selection", {
    res <- manage_data$keep_downloaded(sel[0], sel, metrics)
    expect_equal(sort(res$selection$plot), c("1", "2"))
    # their unit and other details come back with them
    expect_equal(res$selection$Unit, c("North", "North"))
    expect_equal(nrow(res$kept), 2L)
  })

  it("lets scans that were not downloaded go", {
    res <- manage_data$keep_downloaded(sel[1:2], sel, metrics)
    expect_equal(res$selection$plot, c("1", "2"))
    expect_equal(nrow(res$kept), 0L)
  })

  it("changes nothing when nothing is downloaded", {
    res <- manage_data$keep_downloaded(sel[0], sel, data.table())
    expect_equal(nrow(res$selection), 0L)
  })
})

describe("drop_scans", {
  it("removes the given scans and leaves tables without a scan key alone", {
    keys <- sel[2, .(site, plot, date, scanner_id)]
    expect_equal(manage_data$drop_scans(metrics, keys)$plot, "1")
    other <- data.table(x = 1:3)
    expect_equal(manage_data$drop_scans(other, keys), other)
  })
})

describe("get_display_col()", {
  labels <- c(Forbsmod = "Forb cover (%)", Shrubmod = "Shrub cover (%)")

  it("names each column by its stylized label", {
    expect_equal(
      manage_data$get_display_col(c("Shrubmod", "Forbsmod"), labels),
      c("Shrub cover (%)" = "Shrubmod", "Forb cover (%)" = "Forbsmod")
    )
  })

  it("falls back to the column's own name when it has no label", {
    expect_equal(
      manage_data$get_display_col(c("EastMeanCBH", "Forbsmod"), labels),
      c(EastMeanCBH = "EastMeanCBH", "Forb cover (%)" = "Forbsmod")
    )
  })
})
