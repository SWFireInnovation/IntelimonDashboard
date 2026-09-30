box::use(
  sf[st_as_sfc, st_bbox, st_crs],
  stats[sd],
  terra,
  testthat[describe, expect_equal, expect_true, it],
)

box::use(
  app/logic/lcp_cbh,
)

# 10 x 10 landscape of 30 m cells in CONUS Albers. LANDFIRE CBH (m x 10) runs
# 10..100 by column; the first row has no canopy (CBH 0). Stand height 200.
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
  cbh[1:10] <- 0
  vals <- cbind(2000, 10, 180, 165, 40, stand_height, cbh, 10)
  r <- terra$setValues(r, vals)
  names(r) <- c(
    "elevation", "slope", "aspect", "fuel", "canopy_cover", "stand_height", "canopy_base", "canopy_bulk"
  )
  r
}

# WGS84 coordinates of the centre of cell (row, col)
cell_lonlat <- function(stack, row, col) {
  xy <- terra$xyFromCell(stack, terra$cellFromRowCol(stack, row, col))
  ll <- terra$crds(terra$project(terra$vect(xy, crs = "EPSG:5070"), "EPSG:4326"))
  data.frame(Longitude = ll[, 1], Latitude = ll[, 2])
}

scans <- function(stack, rows, cols, cbh_m) {
  cbind(do.call(rbind, Map(cell_lonlat, list(stack), rows, cols)), cbh_m = cbh_m)
}

canopy_values <- function(res, stack) {
  before <- terra$values(stack[["canopy_base"]], mat = FALSE)
  after <- terra$values(res$stack[["canopy_base"]], mat = FALSE)
  list(before = before[before > 0], after = after[before > 0], zero_after = after[before == 0])
}

describe("correct_landfire_cbh", {
  it("rule 1: shifts every canopy cell by the mean difference when scans trend evenly", {
    s <- make_stack()
    # LANDFIRE at these cells is 30, 50, 70 (m x 10); scans are ~1.1 m higher
    obs <- scans(s, c(3, 5, 7), c(3, 5, 7), cbh_m = c(4.0, 6.1, 8.2))
    res <- lcp_cbh$correct_landfire_cbh(s, obs)
    v <- canopy_values(res, s)

    expect_equal(res$info$rule, "shift")
    expect_equal(res$info$shift_m, 1.1, tolerance = 1e-9)
    expect_equal(v$after, round(v$before + 11))
    expect_true(all(v$zero_after == 0))
  })

  it("rule 2: matches mean and SD when the differences do not trend evenly", {
    s <- make_stack()
    obs <- scans(s, c(3, 5, 7), c(3, 5, 7), cbh_m = c(6.0, 4.0, 9.0))
    res <- lcp_cbh$correct_landfire_cbh(s, obs)
    v <- canopy_values(res, s)

    expect_equal(res$info$rule, "distribution")
    # mean and SD land on the scans' (60, 40, 90), up to rounding to whole m x 10
    expect_true(abs(mean(v$after) - mean(c(60, 40, 90))) < 0.5)
    expect_true(abs(sd(v$after) - sd(c(60, 40, 90))) < 0.5)
    expect_true(all(v$zero_after == 0))
  })

  it("rule 2: used when a scan lies outside the AOI even if the trend is even", {
    s <- make_stack()
    obs <- scans(s, c(3, 5, 7), c(3, 5, 7), cbh_m = c(4.0, 6.1, 8.2))
    # AOI covers the left half of the landscape; the scan in column 7 is outside
    e <- as.vector(terra$ext(s)) # xmin, xmax, ymin, ymax
    aoi <- st_as_sfc(st_bbox(
      c(xmin = e[[1]], ymin = e[[3]], xmax = e[[1]] + 150, ymax = e[[4]]),
      crs = st_crs(5070)
    ))
    res <- lcp_cbh$correct_landfire_cbh(s, obs, aoi = aoi)

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
    obs <- scans(s, 5, 5, cbh_m = 6.5)
    res <- lcp_cbh$correct_landfire_cbh(s, obs)
    v <- canopy_values(res, s)

    expect_equal(res$info$rule, "single")
    expect_equal(res$info$shift_m, 1.0)
    expect_equal(v$after, v$before + 10)
  })

  it("never reduces a cell below half its LANDFIRE value", {
    s <- make_stack()
    obs <- scans(s, 5, 5, cbh_m = 2.0) # 3.5 m below the LANDFIRE mean
    res <- lcp_cbh$correct_landfire_cbh(s, obs)
    v <- canopy_values(res, s)

    expect_true(all(v$after >= 0.5 * v$before))
    expect_equal(v$after[v$before == 10], rep(5, sum(v$before == 10)))
    expect_true(res$info$cells_floored > 0)
  })

  it("never raises a cell above its stand height", {
    s <- make_stack(stand_height = 80)
    obs <- scans(s, 5, 5, cbh_m = 9.0)
    res <- lcp_cbh$correct_landfire_cbh(s, obs)
    v <- canopy_values(res, s)

    expect_true(all(v$after <= 80))
    expect_true(res$info$cells_capped > 0)
  })

  it("keeps LANDFIRE when there is no scan CBH", {
    s <- make_stack()
    obs <- scans(s, 5, 5, cbh_m = NA)
    res <- lcp_cbh$correct_landfire_cbh(s, obs)

    expect_equal(res$info$rule, "none")
    expect_equal(terra$values(res$stack), terra$values(s))
  })
})

describe("describe_cbh_correction", {
  it("summarises the rule that was applied", {
    s <- make_stack()
    info <- lcp_cbh$correct_landfire_cbh(s, scans(s, 5, 5, cbh_m = 6.5))$info
    expect_true(grepl("single scan", lcp_cbh$describe_cbh_correction(info)))
    expect_true(grepl("LANDFIRE values kept", lcp_cbh$describe_cbh_correction(list(rule = "none"))))
  })
})
