box::use(
  data.table[data.table],
  testthat[describe, expect_equal, it],
)

box::use(
  app/logic/manage_timesteps,
)

scans <- data.table(
  site = c("A", "A", "A", "B", "A"),
  plot = c("1", "1", "2", "1", "1"),
  date = as.Date(c("2024-05-01", "2024-05-02", "2024-05-10", "2024-08-01", "2025-05-01"))
)

describe("scan_groups", {
  it("starts a new group on a repeat visit, a 30-day gap or a treatment", {
    # A/1 is rescanned the next day (repeat visit), B/1 comes after an 83-day gap
    expect_equal(manage_timesteps$scan_groups(scans, as.Date(character())), c(1, 2, 2, 3, 4))
    # a treatment between the 2024-05-02 and 2024-05-10 scans splits the second group
    expect_equal(manage_timesteps$scan_groups(scans, as.Date("2024-05-05")), c(1, 2, 3, 4, 5))
  })
})

describe("assign_time_steps", {
  metrics <- data.table(scans, v = 1:5)
  none <- data.table(TreatmentDate = as.Date(character()))

  it("uses the Scan grouping set on the scan selection", {
    set <- data.table(scans, ScanGroup = c(1L, 1L, 1L, 2L, 2L))
    out <- manage_timesteps$assign_time_steps(metrics, "v", none, scan_groups = set)
    expect_equal(out[order(value), grp], c(1, 1, 1, 2, 2))
  })

  it("falls back to the three rules for scans without one", {
    set <- data.table(scans, ScanGroup = c(7L, NA, NA, NA, NA))
    out <- manage_timesteps$assign_time_steps(metrics, "v", none, scan_groups = set)
    expect_equal(out[order(value), grp], c(7, 2, 2, 3, 4))
  })
})
