box::use(
  sf[st_as_sfc, st_bbox, st_crs],
  stats[sd],
  terra,
  testthat[describe, expect_equal, expect_false, expect_true, it],
)

box::use(
  app/logic/lcp_canopy,
)

# 10 x 10 landscape of 30 m cells in CONUS Albers. LANDFIRE values run by
# column: CBH 10..100 (m x 10) and canopy cover 5..95 (%). The first row has
# no canopy (both 0). Stand height is 200 unless given; make_height_stack()
# runs it by column instead.
origin <- terra$crds(terra$project(
  terra$vect(data.frame(x = -106.5, y = 35.8), geom = c("x", "y"), crs = "EPSG:4326"),
  "EPSG:5070"
))
make_stack <- function(stand_height = 200) {
  r <- terra$rast(
    xmin = origin[1], xmax = origin[1] + 300, ymin = origin[2], ymax = origin[2] + 300,
    resolution = 30, crs = "EPSG:5070", nlyrs = 8
  )
  cbh <- rep(seq(10, 100, by = 10), 10)
  cover <- rep(seq(5, 95, by = 10), 10)
  cbh[1:10] <- 0
  cover[1:10] <- 0
  r <- terra$setValues(r, cbind(2000, 10, 180, 165, cover, stand_height, cbh, 10))
  names(r) <- c(
    "elevation", "slope", "aspect", "fuel", "canopy_cover", "stand_height", "canopy_base", "canopy_bulk"
  )
  r
}

# stand height 100..280 (m x 10) by column, 0 in the first row
make_height_stack <- function() {
  s <- make_stack()
  height <- rep(seq(100, 280, by = 20), 10)
  height[1:10] <- 0
  s[["stand_height"]] <- terra$setValues(s[["stand_height"]], height)
  s
}

# scans at cells (row, col) with values in LCP units
scans <- function(stack, rows, cols, value) {
  cells <- terra$cellFromRowCol(stack, rows, cols)
  ll <- terra$crds(terra$project(terra$vect(terra$xyFromCell(stack, cells), crs = "EPSG:5070"), "EPSG:4326"))
  data.frame(Longitude = ll[, 1], Latitude = ll[, 2], value = value)
}

# the band's values over the cells LANDFIRE gives canopy, before and after
canopy_values <- function(res, stack, band) {
  before <- terra$values(stack[[band]], mat = FALSE)
  after <- terra$values(res$stack[[band]], mat = FALSE)
  list(before = before[before > 0], after = after[before > 0], zero_after = after[before == 0])
}

left_half_aoi <- function(stack) {
  e <- as.vector(terra$ext(stack)) # xmin, xmax, ymin, ymax
  st_as_sfc(st_bbox(c(xmin = e[[1]], ymin = e[[3]], xmax = e[[1]] + 150, ymax = e[[4]]), crs = st_crs(5070)))
}

correct <- function(stack, obs, band, ...) {
  lcp_canopy$correct_landfire_canopy(stack, obs, band = band, ...)
}

describe("correct_landfire_canopy: canopy base height (band 7)", {
  it("rule 1: shifts every canopy cell by the mean difference when scans trend evenly", {
    s <- make_stack()
    # LANDFIRE at these cells is 30, 50, 70; scans are ~1.1 m higher
    res <- correct(s, scans(s, c(3, 5, 7), c(3, 5, 7), c(40, 61, 82)), "canopy_base")
    v <- canopy_values(res, s, "canopy_base")

    expect_equal(res$info$rule, "shift")
    expect_equal(res$info$shift, 1.1, tolerance = 1e-9)
    expect_equal(v$after, round(v$before + 11))
    expect_true(all(v$zero_after == 0))
  })

  it("rule 2: matches mean and SD when the differences do not trend evenly", {
    s <- make_stack()
    res <- correct(s, scans(s, c(3, 5, 7), c(3, 5, 7), c(60, 40, 90)), "canopy_base")
    v <- canopy_values(res, s, "canopy_base")

    expect_equal(res$info$rule, "distribution")
    # mean and SD land on the scans' (60, 40, 90), up to rounding to whole units
    expect_true(abs(mean(v$after) - mean(c(60, 40, 90))) < 0.5)
    expect_true(abs(sd(v$after) - sd(c(60, 40, 90))) < 0.5)
    expect_true(all(v$zero_after == 0))
  })

  it("rule 2: used when a scan lies outside the AOI even if the trend is even", {
    s <- make_stack()
    obs <- scans(s, c(3, 5, 7), c(3, 5, 7), c(40, 61, 82))
    res <- correct(s, obs, "canopy_base", aoi = left_half_aoi(s))

    expect_equal(res$info$rule, "distribution")
    expect_equal(res$info$scans_in_aoi, 2)
    # cells outside the AOI keep their LANDFIRE value
    after <- terra$values(res$stack[["canopy_base"]], mat = FALSE)
    before <- terra$values(s[["canopy_base"]], mat = FALSE)
    outside <- terra$colFromCell(s, seq_along(before)) > 5
    expect_equal(after[outside], before[outside])
  })

  it("rule 3: shifts the LANDFIRE mean onto a single scan", {
    s <- make_stack()
    res <- correct(s, scans(s, 5, 5, 65), "canopy_base")
    v <- canopy_values(res, s, "canopy_base")

    expect_equal(res$info$rule, "single")
    expect_equal(res$info$shift, 1.0)
    expect_equal(v$after, v$before + 10)
  })

  it("never reduces a cell below half its LANDFIRE value", {
    s <- make_stack()
    res <- correct(s, scans(s, 5, 5, 20), "canopy_base") # 3.5 m below the LANDFIRE mean
    v <- canopy_values(res, s, "canopy_base")

    expect_true(all(v$after >= 0.5 * v$before))
    expect_equal(v$after[v$before == 10], rep(5, sum(v$before == 10)))
    expect_true(res$info$cells_floored > 0)
  })

  it("never raises a cell above 90% of its stand height", {
    s <- make_stack(stand_height = 80)
    res <- correct(s, scans(s, 5, 5, 90), "canopy_base")
    v <- canopy_values(res, s, "canopy_base")

    expect_true(all(v$after <= 72))
    expect_true(res$info$cells_capped > 0)
  })

  it("keeps LANDFIRE when there is no scan value", {
    s <- make_stack()
    res <- correct(s, scans(s, 5, 5, NA), "canopy_base")

    expect_equal(res$info$rule, "none")
    expect_equal(terra$values(res$stack), terra$values(s))
  })
})

describe("correct_landfire_canopy: canopy cover (band 5)", {
  it("rule 1: shifts by the mean difference whenever all scans are in the AOI, even or not", {
    s <- make_stack()
    # LANDFIRE at these cells is 25, 45, 65; differences +10, -5, +15 are uneven
    res <- correct(s, scans(s, c(3, 5, 7), c(3, 5, 7), c(35, 40, 80)), "canopy_cover")
    v <- canopy_values(res, s, "canopy_cover")

    expect_equal(res$info$rule, "shift")
    expect_false(res$info$even_trend)
    expect_equal(res$info$shift, 20 / 3, tolerance = 1e-9)
    expect_equal(v$after, pmin(round(v$before + 20 / 3), 100))
    expect_true(all(v$zero_after == 0))
  })

  it("never raises cover above 100%", {
    s <- make_stack()
    res <- correct(s, scans(s, c(3, 5), c(3, 5), c(55, 75)), "canopy_cover") # +30 everywhere
    v <- canopy_values(res, s, "canopy_cover")

    expect_true(all(v$after <= 100))
    expect_equal(res$info$cells_capped, sum(v$before + 30 > 100))
  })

  it("rule 2: redistributes by mean and SD when a scan lies outside the AOI", {
    s <- make_stack()
    obs <- scans(s, c(3, 5, 7), c(3, 5, 7), c(35, 40, 80))
    res <- correct(s, obs, "canopy_cover", aoi = left_half_aoi(s))

    expect_equal(res$info$rule, "distribution")
    expect_equal(res$info$target_mean, mean(c(35, 40, 80)))
    expect_equal(res$info$target_sd, sd(c(35, 40, 80)))
  })

  it("rule 3: never reduces a cell by more than 85% of its LANDFIRE cover", {
    s <- make_stack()
    res <- correct(s, scans(s, 5, 5, 5), "canopy_cover") # 45 points below the LANDFIRE mean
    v <- canopy_values(res, s, "canopy_cover")

    expect_equal(res$info$rule, "single")
    expect_true(all(v$after >= round(0.15 * v$before)))
    expect_true(res$info$cells_floored > 0)
    # cells high enough to stay above the floor get the full shift
    expect_equal(v$after[v$before == 95], rep(50, sum(v$before == 95)))
  })

  it("leaves canopy base height untouched", {
    s <- make_stack()
    res <- correct(s, scans(s, 5, 5, 5), "canopy_cover")
    expect_equal(terra$values(res$stack[["canopy_base"]]), terra$values(s[["canopy_base"]]))
  })
})

describe("correct_landfire_canopy: stand height (band 6)", {
  it("rule 1: shifts by the mean difference whenever all scans are in the AOI", {
    s <- make_height_stack()
    # LANDFIRE at these cells is 140, 180, 220; differences +30, -10, +40 are uneven
    res <- correct(s, scans(s, c(3, 5, 7), c(3, 5, 7), c(170, 170, 260)), "stand_height")
    v <- canopy_values(res, s, "stand_height")

    expect_equal(res$info$rule, "shift")
    expect_false(res$info$even_trend)
    expect_equal(res$info$shift, 2.0, tolerance = 1e-9)
    expect_equal(v$after, v$before + 20)
    expect_true(all(v$zero_after == 0))
  })

  it("rule 1: lowers every cell when the scans are shorter than LANDFIRE", {
    s <- make_height_stack()
    res <- correct(s, scans(s, c(3, 5), c(3, 5), c(110, 150)), "stand_height") # -30 at both
    v <- canopy_values(res, s, "stand_height")

    expect_equal(res$info$shift, -3.0, tolerance = 1e-9)
    expect_equal(v$after, v$before - 30)
  })

  it("rule 2: matches mean and SD when a scan lies outside the AOI", {
    s <- make_height_stack()
    obs <- scans(s, c(3, 5, 7), c(3, 5, 7), c(170, 170, 260))
    res <- correct(s, obs, "stand_height", aoi = left_half_aoi(s))

    expect_equal(res$info$rule, "distribution")
    expect_equal(res$info$target_mean, mean(c(170, 170, 260)) / 10)
    expect_equal(res$info$target_sd, sd(c(170, 170, 260)) / 10)
    after <- terra$values(res$stack[["stand_height"]], mat = FALSE)
    before <- terra$values(s[["stand_height"]], mat = FALSE)
    inside <- terra$colFromCell(s, seq_along(before)) <= 5 & before > 0
    # LANDFIRE's mean and SD inside the AOI land on the scans', up to rounding
    expect_true(abs(mean(after[inside]) - mean(c(170, 170, 260))) < 0.5)
    expect_true(abs(sd(after[inside]) - sd(c(170, 170, 260))) < 0.5)
    expect_equal(after[!inside], before[!inside])
  })

  it("rule 3: shifts the LANDFIRE mean onto a single scan, never below half a cell's height", {
    s <- make_height_stack()
    res <- correct(s, scans(s, 5, 5, 90), "stand_height") # 10 m below the LANDFIRE mean
    v <- canopy_values(res, s, "stand_height")

    expect_equal(res$info$rule, "single")
    expect_equal(res$info$shift, -10)
    expect_true(all(v$after >= 0.5 * v$before))
    expect_equal(v$after[v$before == 100], rep(50, sum(v$before == 100)))
    expect_equal(v$after[v$before == 280], rep(180, sum(v$before == 280)))
    expect_true(res$info$cells_floored > 0)
  })

  it("caps canopy base height at the corrected stand height when corrected first", {
    s <- make_height_stack()
    height <- correct(s, scans(s, 5, 5, 90), "stand_height")$stack
    cbh <- correct(height, scans(height, 5, 5, 105), "canopy_base")
    h <- terra$values(cbh$stack[["stand_height"]], mat = FALSE)
    b <- terra$values(cbh$stack[["canopy_base"]], mat = FALSE)

    expect_true(all(b[h > 0] <= floor(0.9 * h[h > 0])))
    expect_true(cbh$info$cells_capped > 0)
  })
})

describe("check_crown_length", {
  # stand height lowered by 100 (m x 10) in every canopy cell, floored at half
  lowered <- function(s) correct(s, scans(s, 5, 5, 90), "stand_height")$stack

  it("scales LANDFIRE CBH down with a lowered stand height", {
    s <- make_height_stack()
    res <- lcp_canopy$check_crown_length(lowered(s), s)
    h_lf <- terra$values(s[["stand_height"]], mat = FALSE)
    h <- terra$values(res$stack[["stand_height"]], mat = FALSE)
    cbh_lf <- terra$values(s[["canopy_base"]], mat = FALSE)
    cbh <- terra$values(res$stack[["canopy_base"]], mat = FALSE)

    # col 10: height 280 -> 180, CBH 100 -> 64
    expect_equal(cbh[h_lf == 280], rep(64, sum(h_lf == 280)))
    expect_equal(res$info$cells_rescaled, sum(h < h_lf & cbh_lf > 0))
    expect_true(all(cbh[h > 0] <= floor(0.9 * h[h > 0])))
  })

  it("leaves CBH alone where stand height rose", {
    s <- make_height_stack()
    raised <- correct(s, scans(s, 5, 5, 290), "stand_height")$stack # +100 everywhere
    res <- lcp_canopy$check_crown_length(raised, s)

    expect_equal(terra$values(res$stack[["canopy_base"]]), terra$values(s[["canopy_base"]]))
    expect_equal(res$info$cells_rescaled, 0)
  })

  it("caps a corrected CBH at 90% of stand height without rescaling it", {
    s <- make_height_stack()
    st <- lowered(s)
    st[["canopy_base"]] <- terra$setValues(st[["canopy_base"]], 150) # e.g. a burned plot
    res <- lcp_canopy$check_crown_length(st, s, rescale = FALSE)
    h <- terra$values(res$stack[["stand_height"]], mat = FALSE)
    cbh <- terra$values(res$stack[["canopy_base"]], mat = FALSE)

    expect_equal(res$info$cells_rescaled, 0)
    expect_equal(cbh[h > 0], pmin(150, floor(0.9 * h[h > 0])))
    # first row has no stand height: its CBH is cleared
    expect_true(all(cbh[h == 0] == 0))
    expect_equal(res$info$cells_cleared, 10)
  })

  it("caps every cell inside the AOI, even ones no correction moved", {
    s <- make_stack(stand_height = 50) # LANDFIRE CBH up to 100 sits above it
    res <- lcp_canopy$check_crown_length(s, s, aoi = left_half_aoi(s))
    before <- terra$values(s[["canopy_base"]], mat = FALSE)
    after <- terra$values(res$stack[["canopy_base"]], mat = FALSE)
    inside <- terra$colFromCell(s, seq_along(before)) <= 5

    expect_equal(after[inside], pmin(before[inside], 45))
    expect_equal(res$info$cells_capped, sum(inside & before > 45))
    expect_equal(res$info$cells_rescaled, 0)
    expect_true(grepl("Crown check: 0 cells.*9 capped", lcp_canopy$describe_crown_check(res$info)))
  })

  it("leaves LANDFIRE outside the AOI except where plots were burned in", {
    s <- make_stack(stand_height = 50)
    st <- s
    plot_cell <- terra$cellFromRowCol(s, 5, 9)
    cbh <- terra$values(s[["canopy_base"]], mat = FALSE)
    cbh[plot_cell] <- 70 # a burned-in plot outside the AOI
    st[["canopy_base"]] <- terra$setValues(st[["canopy_base"]], cbh)
    res <- lcp_canopy$check_crown_length(st, s, aoi = left_half_aoi(s))
    before <- terra$values(s[["canopy_base"]], mat = FALSE)
    after <- terra$values(res$stack[["canopy_base"]], mat = FALSE)
    outside <- terra$colFromCell(s, seq_along(before)) > 5

    expect_equal(after[plot_cell], 45)
    others <- outside & seq_along(before) != plot_cell
    expect_equal(after[others], before[others])
  })
})

describe("describe_canopy_correction", {
  it("summarises the band and rule that were applied", {
    s <- make_stack()
    cbh <- correct(s, scans(s, 5, 5, 65), "canopy_base")$info
    cover <- correct(s, scans(s, 5, 5, 5), "canopy_cover")$info
    expect_true(grepl("Canopy base height: single scan", lcp_canopy$describe_canopy_correction(cbh)))
    expect_true(grepl("Canopy cover: single scan.*15% of their LANDFIRE",
                      lcp_canopy$describe_canopy_correction(cover)))
    height <- correct(make_height_stack(), scans(s, 5, 5, 90), "stand_height")$info
    expect_true(grepl("Stand height: single scan.*50% of their LANDFIRE",
                      lcp_canopy$describe_canopy_correction(height)))
    none <- list(band = "canopy_cover", rule = "none")
    expect_true(grepl("LANDFIRE values kept", lcp_canopy$describe_canopy_correction(none)))
  })
})
