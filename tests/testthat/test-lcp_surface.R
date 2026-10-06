box::use(
  data.table[data.table],
  terra,
  testthat[describe, expect_equal, expect_match, expect_null, expect_true, it],
)

box::use(
  app/logic/lcp_surface,
)

# SH4 (144): 0.85 / 1.15 / 0.20 / 0 / 2.55 t/ac, 3.0 ft deep
# TL3 (183): 0.50 / 2.20 / 2.80 / 0 / 0 t/ac, 0.3 ft deep
sh4_scan <- function(d1, d10, d100, woody, depth_ft) {
  data.table(fbfm = "SH4", d1 = d1, d10 = d10, d100 = d100, herb = 0, woody = woody,
             depth_ft = depth_ft)
}
scans <- rbind(
  sh4_scan(0.17, 0.575, 0.40, 1.275, 1.5),
  sh4_scan(0.17, 0.575, 0.40, 1.275, 1.5)
)

describe("surface_fuel_ratios", {
  ratios <- lcp_surface$surface_fuel_ratios(scans)

  it("divides the submitted loadings by the standard model's, class by class", {
    r <- unlist(as.data.frame(ratios$by_model)[1, c("d10", "woody", "depth")])
    expect_equal(unname(r), c(0.5, 0.5, 0.5))
    expect_equal(ratios$by_model$n, 2)
    expect_equal(ratios$n, 2)
  })

  it("holds each ratio between 20% and 200% of the standard model", {
    # 1-hr 0.17 / 0.85 = 0.20 sits on the floor; 100-hr 0.40 / 0.20 = 2 on the cap
    low_high <- rbind(sh4_scan(0.01, 0.575, 1.0, 1.275, 1.5))
    r <- lcp_surface$surface_fuel_ratios(low_high)$pooled
    expect_equal(r[["d1"]], 0.2)
    expect_equal(r[["d100"]], 2)
  })

  it("leaves a class the standard models don't carry unscaled (NA)", {
    expect_true(is.na(ratios$pooled[["herb"]]))
  })

  it("ignores non-burnable scans and returns NULL without burnable ones", {
    nb <- data.table(fbfm = "NB9", d1 = 1, d10 = 1, d100 = 1, herb = 0, woody = 0, depth_ft = 1)
    expect_equal(lcp_surface$surface_fuel_ratios(rbind(scans, nb))$n, 2)
    expect_null(lcp_surface$surface_fuel_ratios(nb))
  })
})

describe("custom_fuel_models", {
  ratios <- lcp_surface$surface_fuel_ratios(scans)
  models <- lcp_surface$custom_fuel_models(c(183, 144, 144), ratios)

  it("twins each base model with a custom number from 14 up", {
    expect_equal(models$base_code, c("SH4", "TL3"))
    expect_equal(models$custom_number, c(14L, 15L))
  })

  it("scales a sampled model by its own ratios and keeps its other parameters", {
    sh4 <- models[1]
    expect_equal(sh4$ratio_source, "plots")
    expect_equal(sh4$woody, 2.55 * 0.5)
    expect_equal(sh4$depth_ft, 1.5)
    expect_equal(sh4$herb, 0)
    expect_equal(sh4$mx_dead_pct, 30)
  })

  it("applies the pooled ratios to a model no scan sits on", {
    tl3 <- models[2]
    expect_equal(tl3$ratio_source, "pooled")
    expect_equal(tl3$d100, 2.8 * 2) # pooled 100-hr ratio, at the cap
    expect_equal(tl3$depth_ft, 0.3 * 0.5)
  })

  it("pools every model when the scans used Anderson 13 codes", {
    fm5 <- lcp_surface$surface_fuel_ratios(data.table(
      fbfm = "FM5", d1 = 0.5, d10 = 0.25, d100 = 0, herb = 0, woody = 1, depth_ft = 1
    ), system = "FBFM13")
    expect_equal(lcp_surface$custom_fuel_models(144, fm5)$ratio_source, "pooled")
  })
})

describe("write_fmd", {
  it("writes an English custom fuel model file, one model per line", {
    models <- lcp_surface$custom_fuel_models(144, lcp_surface$surface_fuel_ratios(scans))
    lines <- readLines(lcp_surface$write_fmd(models, tempfile(fileext = ".fmd")))
    expect_equal(lines[1], "ENGLISH")
    expect_equal(
      lines[2],
      "14 0.1700 0.5750 0.4000 0.0000 1.2750 STATIC 2000 1800 1600 1.5000 30 8000 8000 IntELiMon_SH4"
    )
  })
})

describe("normalize_surface_fuels", {
  # 3 x 3 landscape: SH4 everywhere but one TL3 cell and one non-burnable cell
  make_stack <- function() {
    r <- terra$rast(nrows = 3, ncols = 3, xmin = 0, xmax = 90, ymin = 0, ymax = 90,
                    crs = "EPSG:5070", nlyrs = 8)
    fuel <- c(144, 144, 183, 144, 98, 144, 144, 144, 144)
    r <- terra$setValues(r, cbind(2000, 10, 180, fuel, 40, 150, 20, 10))
    names(r) <- c("elevation", "slope", "aspect", "fuel", "canopy_cover", "stand_height",
                  "canopy_base", "canopy_bulk")
    r
  }

  it("swaps burnable cells for their custom twins and leaves non-burnable ones", {
    out <- lcp_surface$normalize_surface_fuels(make_stack(), scans, label = "most recent per plot")
    expect_equal(terra$values(out$stack[["fuel"]], mat = FALSE), c(14, 14, 15, 14, 98, 14, 14, 14, 14))
    expect_equal(out$info$n_cells, 8)
    expect_equal(terra$values(out$stack[["elevation"]], mat = FALSE), rep(2000, 9))
  })

  it("returns NULL without usable scans", {
    expect_null(lcp_surface$normalize_surface_fuels(make_stack(), scans[0]))
  })

  it("describes the custom models and their ratios", {
    out <- lcp_surface$normalize_surface_fuels(make_stack(), scans, label = "most recent per plot")
    text <- lcp_surface$describe_surface_normalization(out$info)
    expect_match(text, "8 burnable cells in the landscape use 2 custom fuel models")
    expect_match(text, "SH4 → 14 (plots: 1-hr ×0.20", fixed = TRUE)
    expect_match(text, "TL3 → 15 (pooled", fixed = TRUE)
    expect_match(lcp_surface$describe_surface_normalization(NULL), "standard fuel models kept")
  })
})
