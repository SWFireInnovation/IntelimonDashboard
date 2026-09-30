box::use(
  data.table[data.table],
  terra,
  testthat[describe, expect_equal, expect_true, it],
)

box::use(
  app/logic/fccs,
)

impl <- attr(fccs, "namespace")

describe("fccs_crosswalk", {
  xw <- fccs$fccs_crosswalk()

  it("has one row per LANDFIRE FCCS code", {
    expect_true(nrow(xw) > 15000)
    expect_equal(anyDuplicated(xw$fccs), 0)
  })

  it("decodes disturbed codes as fuelbed * 10000 + disturbance", {
    row <- xw[fccs == 220112]
    expect_equal(row$fuelbed, 22)
    expect_equal(row$disturbance, 112)
  })

  it("computes litter bulk density as loading / depth in kg/m^3", {
    # fuelbed 22: 0.74475 tons/acre of litter, 0.5 in deep
    row <- xw[fccs == 22]
    expected <- 0.74475 * impl$TPA_TO_KGM2 / (0.5 * 0.0254)
    expect_equal(row$litter_bd_kgm3, expected, tolerance = 1e-4)
  })

  it("computes live bulk density from live shrub + herb load over their weighted height", {
    row <- xw[fccs == 22]
    depth_m <- row$live_depth_ft * 0.3048
    expect_equal(row$live_bd_kgm3, row$live_load_tpa * impl$TPA_TO_KGM2 / depth_m, tolerance = 1e-4)
    expect_equal(row$height_source, "exact")
  })

  it("leaves live bulk density NA when no shrub/herb heights are known", {
    row <- xw[fccs == 493]
    expect_equal(row$height_source, "none")
    expect_true(is.na(row$live_bd_kgm3))
    expect_true(row$litter_bd_kgm3 > 0)
  })
})

describe("fccs_bulk_density", {
  it("returns rows in the order asked, with NAs for unknown codes", {
    out <- fccs$fccs_bulk_density(c(28, -1, 22))
    expect_equal(out$fccs, c(28L, -1L, 22L))
    expect_true(is.na(out$litter_bd_kgm3[2]))
    expect_equal(out$fuelbed_name[3], "Mature lodgepole pine forest")
  })
})

describe("sample_fccs", {
  it("returns the raw FCCS code under each plot, not its category label", {
    r <- terra$rast(
      xmin = -106, xmax = -105, ymin = 40, ymax = 41, resolution = 0.5, crs = "EPSG:4326"
    )
    r <- terra$setValues(r, c(22L, 28L, 220112L, 493L))
    levels(r) <- data.frame(id = c(22, 28, 220112, 493), FUELBED = c("a", "b", "c", "d"))
    plots <- data.table(
      site = "S", plot = c("1", "2"), Longitude = c(-105.75, -105.25), Latitude = c(40.75, 40.25)
    )
    out <- impl$sample_fccs(r, plots)
    expect_equal(out$fccs, c(22L, 493L))
  })
})

describe("scale_fuel_loads", {
  depths <- data.table(
    site = "S", plot = c("1", "2", "3"),
    MFBDmod = c(10, 10, NA), MLDmod = c(2, 2, 2)
  )
  codes <- data.table(site = "S", plot = c("1", "2", "3"), fccs = c(22L, 493L, 28L))
  out <- fccs$scale_fuel_loads(depths, codes)
  bd <- fccs$fccs_bulk_density(c(22, 493, 28))

  it("multiplies live bulk density by the fuel bed depth (cm -> m)", {
    expect_equal(out$live_load_kgm2[1], bd$live_bd_kgm3[1] * 0.10)
    expect_equal(out$live_load_tpa[1], out$live_load_kgm2[1] / impl$TPA_TO_KGM2)
  })

  it("keeps NA where the bulk density or depth is unknown", {
    expect_true(is.na(out$live_load_kgm2[2]))
    expect_true(is.na(out$live_load_kgm2[3]))
  })

  it("does not scale litter to a loading", {
    expect_true(!any(grepl("litter", names(out))))
  })
})
