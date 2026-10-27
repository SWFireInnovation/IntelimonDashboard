box::use(
  testthat[describe, expect_equal, expect_gt, expect_true, it],
)

box::use(
  app/logic/fire_behavior,
)

impl <- attr(fire_behavior, "namespace")

env <- list(
  wind_mph = 10, waf = 0.3, slope_pct = 0, m1 = 6, m10 = 7, m100 = 8, mx_dead = 25,
  m_herb = 90, m_woody = 90, live_herb_load = 0, live_woody_load = 0, fmc = 100
)
# GR1 at 2 ft deep: 0.5 t/ac 1-hr, 1.5 t/ac live herb
grass_bed <- function(dynamic, d1 = 0.5) {
  list(load_tonsac = c(d1 = d1, d10 = 0, d100 = 0, herb = 1.5, woody = 0),
       depth_ft = 2, mx_dead_pct = 15,
       sav = c(d1 = 2200, d10 = 109, d100 = 30, herb = 2000, woody = 1500),
       dynamic = dynamic)
}
row <- list(CBH = 0, LF_CBD = 0)

describe("herb_cured_fraction", {
  it("cures all the herb at 30% moisture and none from 120%", {
    expect_equal(impl$herb_cured_fraction(30), 1)
    expect_equal(impl$herb_cured_fraction(150), 0)
    expect_equal(impl$herb_cured_fraction(90), 1.333 - 0.999)
  })
})

describe("scan_fire_row", {
  it("spreads faster when a dynamic model cures part of its herb", {
    static <- impl$scan_fire_row(row, c(env, list(bed = grass_bed(FALSE))))
    dynamic <- impl$scan_fire_row(row, c(env, list(bed = grass_bed(TRUE))))
    expect_gt(dynamic$ros_ch_hr, static$ros_ch_hr)
  })

  it("reports no spread, not missing data, for a bed without dead fuel", {
    out <- impl$scan_fire_row(row, c(env, list(bed = grass_bed(FALSE, d1 = 0))))
    expect_equal(c(out$ros_ch_hr, out$fli_kw_m, out$flame_ft, out$fire_type_num), c(0, 0, 0, 0))
    expect_true(is.na(out$torching_idx))
  })

  it("leaves a scan without a fuel bed depth as missing data", {
    bed <- grass_bed(FALSE)
    bed$depth_ft <- NA
    expect_true(is.na(impl$scan_fire_row(row, c(env, list(bed = bed)))$ros_ch_hr))
  })
})

describe("scan_fire_row without canopy", {
  canopy_row <- list(CBH = 1.5, LF_CBD = 5, MaxTH = 12, TreesN = 30, StemsPacre = 40)

  it("rules out crown fire when no trees were measured, leaving the indices missing", {
    for (col in c("MaxTH", "TreesN", "StemsPacre")) {
      no_trees <- canopy_row
      no_trees[[col]] <- 0
      out <- impl$scan_fire_row(no_trees, c(env, list(bed = grass_bed(TRUE))))
      expect_equal(out$fire_type_num, 0)
      expect_true(all(is.na(c(out$crown_Io, out$crown_Ro, out$torching_idx, out$crowning_idx))))
      expect_gt(out$ros_ch_hr, 0)
    }
  })

  it("still computes crown fire where trees were measured", {
    out <- impl$scan_fire_row(canopy_row, c(env, list(bed = grass_bed(TRUE))))
    expect_gt(out$crown_Io, 0)
    expect_equal(out$fire_type_num, 1)
  })
})
