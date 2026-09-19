box::use(
  data.table[data.table],
  shiny[isolate, reactiveVal, testServer],
  testthat[describe, expect_equal, expect_false, expect_match, expect_named, expect_true, it],
)

box::use(
  app/logic/forestry[
    crown_ratio,
    mark_removals,
    plot_area_m2,
    scaling_area_m2,
    stand_metrics
  ],
  app/logic/fvs[build_keyfile, build_treeinit, thin_keyword],
  app/view/tab_forestry[server],
)

# One acre in square metres, so per-acre values are easy to check by hand.
ACRE_M2 <- 4046.856

# A tree inventory shaped like the API response: every field is a string and an
# unnamed row index arrives as V1; identifying columns use this app's naming.
api_trees <- function() {
  n <- 12
  data.table(
    V1 = as.character(seq_len(n)),
    TreeID = as.character(seq_len(n)),
    X = as.character(seq(-10, 10, length.out = n)),
    Y = as.character(seq(8, -8, length.out = n)),
    H = as.character(seq(8, 25, length.out = n)),
    DBH = as.character(seq(4, 20, length.out = n)),
    BasalA = as.character(0.005454 * seq(4, 20, length.out = n) ^ 2),
    site = "S1",
    plot = "P1",
    date = as.Date("2023-08-10"),
    scanner_id = 1L
  )
}

api_metrics <- function() {
  data.table(
    site = "S1", plot = "P1", date = as.Date("2023-08-10"), scanner_id = 1L,
    nonocarea = 500L, CBH = 4.2
  )
}

describe("forestry logic", {
  it("scales by nonocarea and falls back to the full plot area", {
    expect_equal(plot_area_m2(15), pi * 225)
    expect_equal(scaling_area_m2(500, 15, "nonoc"), 500)
    expect_equal(scaling_area_m2(500, 15, "full"), pi * 225)
    expect_equal(scaling_area_m2(NA, 15, "nonoc"), pi * 225)
    expect_equal(scaling_area_m2(5000, 15, "nonoc"), pi * 225)
  })

  it("computes per-acre stand metrics", {
    trees <- data.table(DBH = c(10, 10), H = c(20, 22))
    m <- stand_metrics(trees, ACRE_M2)
    expect_equal(m$tpa, 2, tolerance = 1e-6)
    expect_equal(m$ba_ac, 2 * 0.5454, tolerance = 1e-6)
    expect_equal(m$qmd_in, 10)
    expect_equal(m$ef_tpa, 1, tolerance = 1e-6)
  })

  it("thins from below down to the residual basal area target", {
    trees <- data.table(DBH = c(4, 8, 12, 16, 20), H = 15, X = 0, Y = 0)
    rm <- mark_removals(trees, ACRE_M2, "below", target_ba_ac = 3.6)
    expect_equal(rm, c(TRUE, TRUE, TRUE, FALSE, FALSE))
    kept <- stand_metrics(trees[!rm], ACRE_M2)
    expect_true(kept$ba_ac <= 3.6)
  })

  it("derives crown ratio from height and canopy base height", {
    expect_equal(crown_ratio(c(20, 10, 3), 5), c(0.75, 0.5, NA))
  })
})

describe("FVS export", {
  it("builds a treelist in FVS units", {
    trees <- data.table(TreeID = 1:2, DBH = c(10.04, 12), H = c(10, 20), cr = c(0.5, NA))
    tr <- build_treeinit(trees, "S1_P1", ef_tpa = 8.1)
    expect_equal(tr$Ht, c(33, 66))
    expect_equal(tr$DBH, c(10, 12))
    expect_equal(tr$CrRatio, c(50, NA))
    expect_equal(tr$TreeCount, c(8.1, 8.1))
  })

  it("writes the prescription and FFE blocks into the keyword file", {
    thin <- thin_keyword("below", 80, NULL, 2023)
    key <- build_keyfile("S1_P1", 2023, 0.12, "SN", "LP", 70, thinning = thin, ffe = TRUE)
    expect_true(any(grepl("^ThinBBA\\s+2023\\s+80$", key)))
    expect_true("FMIn" %in% key)
    expect_equal(key[length(key)], "Stop")
  })
})

describe("tab_forestry server", {
  it("builds the stand, prescription and FVS export for a loaded scan", {
    testServer(server, {
      session$userData$metrics <- reactiveVal(api_metrics())
      session$userData$tree_inv <- api_trees()
      session$setInputs(
        mode = "plot", radius = 15, scaleby = "nonoc", sprule = "random",
        sp_code_1 = "LP", sp_pct_1 = 60, sp_code_2 = "SA", sp_pct_2 = 25,
        sp_code_3 = "WO", sp_pct_3 = 15,
        method = "below", target_ba = 40, spacing_ft = 14,
        variant = "SN", site_index = 70, num_cycles = 5, time_int = 10,
        slope_pct = 0, aspect_deg = 0, ffe = TRUE, use_cr = TRUE, thin_key = TRUE,
        colorby = "species"
      )

      expect_equal(nrow(scan_keys()), 1)
      expect_equal(scale_area(), 500)

      stems <- stems_marked()
      expect_equal(nrow(stems), 12)
      expect_true(all(stems$species %in% c("LP", "SA", "WO")))
      expect_true(any(stems$rm))
      expect_true(mets_after()$ba_ac <= 40)
      expect_equal(stems$cr[1], (8 - 4.2) / 8)

      expect_match(output$stem_count, "12 stems")
      expect_true(nchar(output$stem_map$src) > 0)

      f <- fvs_bits()
      expect_equal(f$sid, "S1_P1")
      expect_equal(nrow(f$tree), sum(!stems$rm))
      expect_named(f$tree, c(
        "Stand_ID", "StandPlot_ID", "Tree_ID", "TreeCount", "History", "Species",
        "DBH", "DG", "Ht", "HtG", "CrRatio"
      ))
      expect_true(any(grepl("^InvYear\\s+2023$", f$key)))
      expect_true(any(grepl("^ThinBBA", f$key)))
      expect_match(output$fvs_preview, "FVS_TreeInit")
    })
  })

  it("simulates an AOI stem map from the pooled inventory", {
    testServer(server, {
      session$userData$metrics <- reactiveVal(api_metrics())
      session$userData$tree_inv <- api_trees()
      session$setInputs(
        mode = "aoi", gsource = "all", radius = 15, aoi_w = 100, aoi_h = 100,
        override_fit = FALSE, pattern = "random", clump = 9
      )
      expect_equal(fitted_params()$n, 12)
      expect_equal(fitted_params()$density_tph, 12 / (500 * 1e-4))
      expect_true(nrow(sim_stems()) > 0)
      expect_true(nchar(output$stem_map$src) > 0)
    })
  })

  it("starts empty and picks up data once Get Data has run", {
    testServer(server, {
      session$userData$metrics <- reactiveVal(data.table())
      session$userData$tree_inv <- data.table()
      session$setInputs(mode = "plot", radius = 15, scaleby = "nonoc", method = "none")
      expect_equal(nrow(scan_keys()), 0)
      expect_equal(output$stem_count, "No stems")

      # Same order as tab_selectionMap's Get Data observer: metrics, then trees,
      # both before reactives re-run
      session$userData$metrics(api_metrics())
      session$userData$tree_inv <- api_trees()
      session$flushReact()
      expect_equal(nrow(scan_keys()), 1)
      expect_equal(output$stem_count, "12 stems · 0 marked")
    })
  })
})
