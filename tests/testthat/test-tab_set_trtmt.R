box::use(
  data.table[data.table],
  testthat[describe, expect_equal, it],
)

box::use(
  app/view/tab_set_trtmt,
)

impl <- attr(tab_set_trtmt, "namespace")

describe("table_order", {
  scans <- data.table(
    site = c("B", "A", "A", "A"),
    plot = c("1", "2", "1", "1"),
    date = as.Date(c("2025-01-01", "2025-01-01", "2024-01-01", "2025-06-01")),
    Unit = c("x", "y", "z", "w")
  )

  it("orders scans by plot, site, then newest date first", {
    out <- impl$table_order(scans)
    expect_equal(out$Unit, c("w", "z", "x", "y"))
  })

  it("leaves the scan selection itself unchanged", {
    impl$table_order(scans)[1, Unit := "changed"]
    expect_equal(scans$Unit, c("x", "y", "z", "w"))
  })
})
