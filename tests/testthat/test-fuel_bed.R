box::use(
  data.table[data.table],
  testthat[describe, expect_equal, expect_identical, expect_null, it],
)

box::use(
  app/logic/fuel[BROWN_CLASSES, brown_class_load],
  app/logic/fuel_bed,
  app/logic/fuel_models[depth_scaled_loads, fuel_model_lookup],
)

tl3 <- fuel_model_lookup("TL3", "FBFM40") # 0.3 ft deep
counts <- c(d1 = 34, d10 = 12, d100 = 3)
prefer_counts <- c(d1 = "count", d10 = "count", d100 = "count")

describe("default_fuel_source", {
  it("is modeled when the depth or any 1-100 hour model has data", {
    expect_equal(fuel_bed$default_fuel_source(c("MFBDmod", "CBH")), "modeled")
    expect_equal(fuel_bed$default_fuel_source("hunhrmod"), "modeled")
  })

  it("is landfire when none of them do", {
    expect_equal(fuel_bed$default_fuel_source(c("CBH", "thohrmod")), "landfire")
    expect_equal(fuel_bed$default_fuel_source(character(0)), "landfire")
  })
})

describe("assemble_fuel_bed", {
  it("uses the counts for dead loads and the scaled model for live loads", {
    bed <- fuel_bed$assemble_fuel_bed(tl3, 6, counts, prefer_counts)
    expect_equal(bed$load_tonsac[["d10"]], brown_class_load(12, BROWN_CLASSES$tenhr))
    expect_equal(bed$load_tonsac[["herb"]], depth_scaled_loads(tl3, 6)[["herb"]])
    expect_equal(bed$sources[["d1"]], "Time lag count")
    expect_equal(bed$sources[["woody"]], "Fuel model × depth")
    expect_equal(bed$depth_ft, 6 / 30.48)
    expect_equal(bed$depth_source, "Measured depth")
    expect_equal(bed$mx_dead_pct, 20)
    expect_equal(bed$fallback, character(0))
  })

  it("scales the model to the measured depth when the model is preferred", {
    bed <- fuel_bed$assemble_fuel_bed(tl3, 6, counts, c(d1 = "model", d10 = "count"))
    expect_equal(bed$load_tonsac[["d1"]], depth_scaled_loads(tl3, 6)[["d1"]])
    expect_equal(bed$sources[["d100"]], "Time lag count")
  })

  it("falls back to the model for a missing count", {
    bed <- fuel_bed$assemble_fuel_bed(tl3, 6, c(d1 = NA, d10 = 12, d100 = 3), prefer_counts)
    expect_equal(bed$sources[["d1"]], "Fuel model × depth")
    expect_equal(bed$fallback, c(d1 = "model"))
  })

  it("falls back to the model's own depth when the depth is missing", {
    bed <- fuel_bed$assemble_fuel_bed(tl3, NA, counts, prefer_counts)
    expect_equal(bed$depth_ft, 0.3)
    expect_equal(bed$depth_source, "Fuel model depth")
    expect_equal(bed$load_tonsac[["herb"]], 0)
  })

  it("keeps the counts and leaves Mx to rothRmel without a fuel model", {
    bed <- fuel_bed$assemble_fuel_bed(NULL, 6, counts, c(d1 = "model"))
    expect_equal(bed$sources[["d1"]], "Time lag count")
    expect_equal(bed$fallback, c(d1 = "count"))
    expect_equal(bed$sources[["herb"]], "No fuel model")
    expect_null(bed$mx_dead_pct)
    expect_equal(bed$mx_source, "rothRmel sidebar")
  })

  it("gives the model's standard bed with no measurements", {
    bed <- fuel_bed$assemble_fuel_bed(tl3, NA, c(d1 = NA), c(d1 = "model"))
    expect_equal(unname(bed$load_tonsac), c(0.5, 2.2, 2.8, 0, 0))
  })

  it("reports a class with neither a count nor a fuel model", {
    bed <- fuel_bed$assemble_fuel_bed(NULL, 6, c(d1 = NA, d10 = 12, d100 = 3), prefer_counts)
    expect_equal(bed$fallback, c(d1 = "none"))
    expect_equal(bed$sources[["d1"]], "No data")
  })
})

# two scans of one plot: the second has no 1-hour count and no depth
scans <- data.table(
  site = "S", plot = "1", date = as.Date(c("2022-01-01", "2023-01-01")), scanner_id = 1,
  MFBDmod = c(6, NA), onehrmod = c(34, NA), tenhrmod = c(12, 10), hunhrmod = c(3, 2),
  LF_FBFM40 = c("TL3", "GR1")
)
fm_from_scan <- function(row) fuel_model_lookup(row$LF_FBFM40, "FBFM40")

describe("merge_scan_models", {
  it("joins the model columns on the scan key, keeping the metrics' on a clash", {
    metrics <- data.table(site = "S", plot = "1", date = as.Date("2022-01-01"), scanner_id = 1,
                          CBH = 4, shared = "metrics")
    models <- data.table(site = "S", plot = "1", date = as.Date("2022-01-01"), scanner_id = 1,
                         MFBDmod = 6, shared = "models")
    out <- fuel_bed$merge_scan_models(metrics, models)
    expect_equal(out$MFBDmod, 6)
    expect_equal(out$shared, "metrics")
    expect_equal(names(models)[6], "shared")
  })
})

describe("scan_fuel_loads", {
  it("computes each scan from its own measurements and fuel model", {
    loads <- fuel_bed$scan_fuel_loads(scans, fm_from_scan, prefer_counts)
    expect_equal(nrow(loads), 2)
    expect_equal(loads$d10, vapply(c(12, 10), brown_class_load, numeric(1), BROWN_CLASSES$tenhr))
    expect_equal(loads$fbfm, c("TL3", "GR1"))
    expect_equal(loads$depth_ft, c(6 / 30.48, 0.4))
    expect_equal(loads$src_d1, c("Time lag count", "Fuel model × depth"))
    expect_equal(loads$fallback_d1, c(NA, "model"))
    expect_equal(loads$date, scans$date)
  })

  it("applies an edited value to every scan", {
    loads <- fuel_bed$scan_fuel_loads(scans, fm_from_scan, prefer_counts, list(depth_cm = 9))
    expect_equal(loads$depth_ft, rep(9 / 30.48, 2))
  })

  it("uses each scan's standard fuel model in LANDFIRE mode", {
    loads <- fuel_bed$scan_fuel_loads(scans, fm_from_scan, prefer_counts, landfire = TRUE)
    expect_equal(loads$d1, c(0.5, 0.1))
    expect_equal(loads$src_herb, rep("Standard load", 2))
    expect_equal(loads$sav_d1, c(2000, 2200))
  })
})

describe("mean_fuel_loading", {
  loads <- fuel_bed$scan_fuel_loads(scans, fm_from_scan, prefer_counts)
  mean_load <- fuel_bed$mean_fuel_loading(loads)

  it("averages the scans and summarises mixed sources", {
    expect_equal(mean_load$n, 2)
    expect_equal(mean_load$load_tonsac[["d10"]], mean(loads$d10))
    expect_equal(mean_load$sources[["d1"]], "Fuel model × depth (1), Time lag count (1)")
    expect_equal(mean_load$sources[["d10"]], "Time lag count")
    expect_equal(as.integer(mean_load$fallback$d1[["model"]]), 1)
  })

  it("reports no data without scans", {
    empty <- fuel_bed$mean_fuel_loading(data.table())
    expect_equal(empty$n, 0)
    expect_equal(empty$sources[["d1"]], "No data")
    expect_identical(unname(is.na(empty$load_tonsac)), rep(TRUE, 5))
  })
})

describe("bed_for_scan", {
  loads <- fuel_bed$scan_fuel_loads(scans, fm_from_scan, prefer_counts)
  bed <- list(scans = loads, load_tonsac = c(d1 = 9), depth_ft = 1)

  it("returns the scan's own loadings", {
    one <- fuel_bed$bed_for_scan(bed, as.list(scans[2]))
    expect_equal(one$load_tonsac[["d10"]], loads$d10[2])
    expect_equal(one$depth_ft, 0.4)
    expect_equal(one$mx_dead_pct, 15)
    expect_null(one$sav)
  })

  it("falls back to the submitted means for a scan it doesn't hold", {
    other <- list(site = "S", plot = "2", date = as.Date("2022-01-01"), scanner_id = 1)
    expect_equal(fuel_bed$bed_for_scan(bed, other)$depth_ft, 1)
    expect_null(fuel_bed$bed_for_scan(NULL, other))
  })
})

describe("select_scans", {
  dt <- data.table(
    site = "S", plot = c("1", "1", "1", "2"),
    date = as.Date(c("2021-07-01", "2023-08-01", "2025-07-01", "2022-01-01"))
  )

  it("keeps each plot's most recent scan", {
    expect_equal(fuel_bed$select_scans(dt, "recent")$date, as.Date(c("2025-07-01", "2022-01-01")))
  })

  it("keeps every scan for the mean of all scans", {
    expect_equal(nrow(fuel_bed$select_scans(dt, "all")), 4)
  })

  it("keeps each plot's scan nearest the date, the earlier one on a tie", {
    near <- fuel_bed$select_scans(dt, "date", as.Date("2023-01-01"))
    expect_equal(near$date, as.Date(c("2023-08-01", "2022-01-01")))
    pair <- data.table(site = "S", plot = "1", date = as.Date(c("2021-07-01", "2021-07-11")))
    tie <- fuel_bed$select_scans(pair, "date", as.Date("2021-07-06"))
    expect_equal(tie$date, as.Date("2021-07-01"))
  })

  it("falls back to the most recent scan without a date", {
    expect_equal(nrow(fuel_bed$select_scans(dt, "date", NULL)), 2)
  })

  it("labels the point in time", {
    expect_equal(fuel_bed$point_in_time_label("date", "2023-08-25"), "scans nearest 2023-08-25")
    expect_equal(fuel_bed$point_in_time_label("all"), "mean of all scans")
    expect_equal(fuel_bed$point_in_time_label("date", NULL), "most recent per plot")
  })
})

describe("assemble_fuel_bed with the auto source", {
  gr1 <- fuel_model_lookup("GR1", "FBFM40")
  auto <- c(d1 = "auto", d10 = "auto", d100 = "auto")

  it("takes the fuel model over a grass model's near-zero count", {
    bed <- fuel_bed$assemble_fuel_bed(gr1, 60, c(d1 = 2, d10 = NA, d100 = NA), auto)
    expect_equal(bed$load_tonsac[["d1"]], depth_scaled_loads(gr1, 60)[["d1"]])
    expect_equal(bed$grass_model, c("d1", "d10", "d100"))
    expect_equal(bed$fallback, character(0))
  })

  it("keeps a grass model's count once it carries real load", {
    bed <- fuel_bed$assemble_fuel_bed(gr1, 60, c(d1 = 200, d10 = NA, d100 = NA), auto)
    expect_equal(bed$sources[["d1"]], "Time lag count")
    expect_equal(bed$grass_model, c("d10", "d100"))
  })

  it("keeps the count on other models, however small", {
    bed <- fuel_bed$assemble_fuel_bed(tl3, 6, c(d1 = 1, d10 = 12, d100 = 3), auto)
    expect_equal(bed$sources[["d1"]], "Time lag count")
    expect_equal(bed$grass_model, character(0))
  })

  it("keeps a near-zero count when the count is chosen explicitly", {
    bed <- fuel_bed$assemble_fuel_bed(gr1, 60, c(d1 = 0, d10 = NA, d100 = NA), prefer_counts)
    expect_equal(bed$load_tonsac[["d1"]], 0)
    expect_equal(bed$sources[["d1"]], "Time lag count")
  })

  it("records the switches and the dynamic flag per scan", {
    grass <- data.table(site = "S", plot = c("1", "2"), date = as.Date("2024-11-21"),
                        scanner_id = 2, MFBDmod = 60, onehrmod = c(0, 200), LF_FBFM40 = "GR1")
    loads <- fuel_bed$scan_fuel_loads(grass, fm_from_scan, auto)
    expect_equal(loads$grass_d1, c(TRUE, FALSE))
    expect_equal(loads$dynamic, c(TRUE, TRUE))
    expect_equal(fuel_bed$mean_fuel_loading(loads)$grass_model[["d1"]], 1L)
  })
})
