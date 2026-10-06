box::use(
  data.table[copy, data.table],
  terra,
  testthat[describe, expect_equal, expect_error, expect_false, expect_true, it],
  utils[unzip],
)

box::use(
  app/logic/lcp,
)

impl <- attr(lcp, "namespace")

# A small 8-band landscape in CONUS Albers (30 m cells) with a flat LANDFIRE
# value per band, centred on a real plot location in New Mexico.
plot_xy <- terra$project(
  terra$vect(data.frame(x = -106.5, y = 35.8), geom = c("x", "y"), crs = "EPSG:4326"),
  "EPSG:5070"
)
fake_stack <- function() {
  xy <- terra$crds(plot_xy)
  r <- terra$rast(
    xmin = xy[1] - 300, xmax = xy[1] + 300, ymin = xy[2] - 300, ymax = xy[2] + 300,
    resolution = 30, crs = "EPSG:5070", nlyrs = 8
  )
  r <- terra$setValues(r, rep(c(2000, 10, 180, 165, 40, 150, 20, 10), each = terra$ncell(r)))
  names(r) <- impl$band_names()
  r
}

plots <- data.table(site = "S1", plot = "0001", Longitude = -106.5, Latitude = 35.8)
metrics <- data.table(
  site = "S1", plot = "0001",
  date = as.Date(c("2023-05-01", "2024-05-01")),
  canopyCover = c(0.10, 0.55), MaxTH = c(10, 16.87), CBH = c(1, 3.35)
)

describe("lcp_products", {
  it("returns the 8 LFPS layers in LCP band order", {
    expect_equal(
      lcp$lcp_products("LF2024"),
      c(
        "LF2020_Elev", "LF2020_SlpD", "LF2020_Asp", "LF2024_FBFM40",
        "LF2024_CC", "LF2024_CH", "LF2024_CBH", "LF2024_CBD"
      )
    )
  })
})

describe("read_landfire_stack", {
  # an LFPS-style GeoTIFF: the 8 LCP layers, then FCCS fuelbeds and map zones
  lfps_tif <- function(n_extra = 2) {
    s <- fake_stack()
    if (n_extra > 0) {
      extra <- terra$rast(s[[1:n_extra]])
      extra <- terra$setValues(extra, rep(c(1203, 15)[seq_len(n_extra)], each = terra$ncell(s)))
      s <- c(s, extra)
    }
    names(s) <- paste0("US_", seq_len(terra$nlyr(s)))
    path <- tempfile(fileext = ".tif")
    terra$writeRaster(s, path)
    path
  }

  it("names the 8 LCP bands and the IFTDSS extras in request order", {
    s <- lcp$read_landfire_stack(lfps_tif(), lcp$IFTDSS_EXTRA_BANDS)
    expect_equal(names(s), c(impl$band_names(), "fccs", "map_zone"))
    expect_equal(unname(unlist(s[1])), c(2000, 10, 180, 165, 40, 150, 20, 10, 1203, 15))
  })

  it("reads the 8 LCP bands alone when no extras were requested", {
    expect_equal(names(lcp$read_landfire_stack(lfps_tif(0))), impl$band_names())
  })

  it("refuses a band count that does not match the request", {
    expect_error(lcp$read_landfire_stack(lfps_tif(0), lcp$IFTDSS_EXTRA_BANDS), "expected 10")
  })
})

describe("IFTDSS_EXTRA_BANDS", {
  it("requests FCCS fuelbeds and map zones, the IFTDSS 3.12 bands 9-10", {
    products <- vapply(lcp$IFTDSS_EXTRA_BANDS, `[[`, character(1), "product")
    expect_equal(products, c("LF2023_FCCS", "map_zones"))
  })
})

describe("LCP_BANDS", {
  it("only replaces canopy cover, stand height and canopy base height", {
    replaced <- vapply(lcp$LCP_BANDS, function(b) !is.na(b$metric), logical(1))
    expect_equal(which(replaced), 5:7)
  })

  it("converts lidar units to LCP units", {
    b <- lcp$LCP_BANDS
    expect_equal(b[[5]]$to_lcp(c(0.512, 1.2, -0.1)), c(51, 100, 0))
    expect_equal(b[[6]]$to_lcp(16.867), 169)
    expect_equal(b[[7]]$to_lcp(3.351), 34)
  })
})

describe("build_lcp_aoi", {
  it("returns a WGS84 bbox containing the plots, buffered on every side", {
    aoi <- lcp$build_lcp_aoi(plots, buffer_m = 2000)
    expect_equal(length(aoi), 4)
    expect_true(aoi[1] < -106.5 && aoi[3] > -106.5 && aoi[2] < 35.8 && aoi[4] > 35.8)
    # 2 km is ~0.018 degrees of latitude
    expect_true(abs((aoi[4] - aoi[2]) / 2 - 0.018) < 0.002)
  })
})

describe("check_band_ranges", {
  it("passes a stack in LCP order", {
    expect_true(all(lcp$check_band_ranges(fake_stack())))
  })

  it("flags bands that are out of order", {
    # elevation and fuel swapped: an elevation of 165 m is plausible, but a
    # fuel code of 2000 is not
    s <- fake_stack()[[c(4, 2, 3, 1, 5:8)]]
    ok <- lcp$check_band_ranges(s)
    expect_equal(names(ok)[!ok], "fuel")
  })
})

describe("burn_lidar_canopy", {
  it("burns the latest scan into bands 5-7 and leaves 1-4 and 8 alone", {
    before <- fake_stack()
    after <- lcp$burn_lidar_canopy(before, metrics, plots)
    at_plot <- unlist(terra$extract(after, plot_xy, ID = FALSE))

    expect_equal(unname(at_plot), c(2000, 10, 180, 165, 55, 169, 34, 10))
    # cells far from the plot keep LANDFIRE values
    expect_equal(unname(unlist(after[1, 1])), c(2000, 10, 180, 165, 40, 150, 20, 10))
    # a 30 m disc on a 30 m grid covers about three cells
    changed <- sum(terra$values(after[["canopy_cover"]]) == 55)
    expect_true(changed >= 1 && changed <= 5)
    for (i in c(1:4, 8)) {
      expect_equal(terra$values(after[[i]]), terra$values(before[[i]]))
    }
  })

  it("keeps LANDFIRE for a band whose lidar metric is missing", {
    m <- copy(metrics)[, CBH := NA_real_]
    after <- lcp$burn_lidar_canopy(fake_stack(), m, plots)
    at_plot <- unlist(terra$extract(after, plot_xy, ID = FALSE))
    expect_equal(unname(at_plot[5:7]), c(55, 169, 20))
  })

  it("returns the stack unchanged when no plot has coordinates", {
    no_loc <- copy(plots)[, Longitude := NA_real_]
    after <- lcp$burn_lidar_canopy(fake_stack(), metrics, no_loc)
    expect_equal(terra$values(after), terra$values(fake_stack()))
  })
})

describe("write_lcp", {
  it("writes an 8-band LCP that reads back with the same values and units", {
    s <- lcp$burn_lidar_canopy(fake_stack(), metrics, plots)
    path <- lcp$write_lcp(s, tempfile(fileext = ".lcp"))
    back <- terra$rast(path)

    expect_equal(terra$nlyr(back), 8)
    expect_equal(unname(unlist(terra$extract(back, plot_xy, ID = FALSE))),
                 c(2000, 10, 180, 165, 55, 169, 34, 10))

    info <- paste(terra$describe(path), collapse = "\n")
    expect_true(grepl("CANOPY_COV_UNIT_NAME=Percent", info, fixed = TRUE))
    expect_true(grepl("CANOPY_HT_UNIT_NAME=Meters x 10", info, fixed = TRUE))
    expect_true(grepl("CBH_UNIT_NAME=Meters x 10", info, fixed = TRUE))
    expect_true(grepl("CBD_UNIT_NAME=kg/m^3 x 100", info, fixed = TRUE))
    expect_true(grepl("LATITUDE=36", info, fixed = TRUE))
  })

  it("writes cells LANDFIRE leaves empty (open ocean) as flat water, fuel model 98", {
    s <- fake_stack()
    s[1] <- NA
    back <- terra$rast(lcp$write_lcp(s, tempfile(fileext = ".lcp")))

    expect_equal(unname(unlist(back[1])), c(0, 0, -1, 98, 0, 0, 0, 0))
    expect_equal(sum(terra$values(back) == -9999), 0)
    # cells with data are untouched
    expect_equal(unname(unlist(back[2])), c(2000, 10, 180, 165, 40, 150, 20, 10))
  })

  it("bundles the .lcp and .prj into a zip under one name", {
    lcp_path <- lcp$write_lcp(fake_stack(), tempfile(fileext = ".lcp"))
    zip_path <- lcp$bundle_lcp(lcp_path, tempfile(fileext = ".zip"), name = "site_x")

    out <- tempfile()
    unzip(zip_path, exdir = out)
    expect_equal(sort(list.files(out)), c("site_x.lcp", "site_x.prj"))
    back <- terra$rast(file.path(out, "site_x.lcp"))
    expect_equal(terra$nlyr(back), 8)
    expect_true(grepl("Albers", terra$crs(back, describe = TRUE)$name))
  })

  it("bundles a custom fuel model file under the same name", {
    lcp_path <- lcp$write_lcp(fake_stack(), tempfile(fileext = ".lcp"), custom_fuels = TRUE)
    fmd_path <- tempfile(fileext = ".fmd")
    writeLines("ENGLISH", fmd_path)
    zip_path <- lcp$bundle_lcp(lcp_path, tempfile(fileext = ".zip"), name = "site_x",
                               fmd_path = fmd_path)

    out <- tempfile()
    unzip(zip_path, exdir = out)
    expect_equal(sort(list.files(out)), c("site_x.fmd", "site_x.lcp", "site_x.prj"))
  })

  it("refuses a stack without 8 bands", {
    expect_error(lcp$write_lcp(fake_stack()[[1:5]], tempfile(fileext = ".lcp")), "8 bands")
  })
})

describe("write_iftdss_tif", {
  it("writes an 8-band 32-bit integer GeoTIFF with the LCP values and -9999 NoData", {
    s <- lcp$burn_lidar_canopy(fake_stack(), metrics, plots)
    s[1] <- NA
    path <- lcp$write_iftdss_tif(s, tempfile(fileext = ".tif"))
    back <- terra$rast(path)

    expect_equal(terra$nlyr(back), 8)
    expect_equal(names(back), impl$band_names())
    expect_equal(unname(unlist(terra$extract(back, plot_xy, ID = FALSE))),
                 c(2000, 10, 180, 165, 55, 169, 34, 10))
    expect_true(all(is.na(unlist(back[1]))))
    expect_equal(attr(path, "nodata_share"), 1 / terra$ncell(s))

    info <- paste(terra$describe(path), collapse = "\n")
    expect_true(grepl("Type=Int32", info, fixed = TRUE))
    expect_true(grepl("NoData Value=-9999", info, fixed = TRUE))
    expect_true(grepl("Albers", terra$crs(back, describe = TRUE)$name))
  })

  it("holds stand height, CBH and CBD to IFTDSS's limits", {
    s <- fake_stack()
    v <- terra$values(s)
    v[1, c(6, 7, 8)] <- c(1400, 1300, 60) # too tall, CBH above the capped height, CBD high
    v[2, c(6, 7)] <- c(150, 200) # LANDFIRE CBH above stand height
    s <- terra$setValues(s, v)
    path <- lcp$write_iftdss_tif(s, tempfile(fileext = ".tif"))
    back <- terra$rast(path)

    expect_equal(unname(unlist(back[1]))[6:8], c(1200, 1200, 50))
    expect_equal(unname(unlist(back[2]))[6:7], c(150, 150))
    expect_equal(unname(unlist(back[3])), c(2000, 10, 180, 165, 40, 150, 20, 10))
    expect_equal(attr(path, "clamped"), c(stand_height = 1, canopy_base = 2, canopy_bulk = 1))
    expect_true(grepl("1 cells' stand height capped", lcp$describe_iftdss_tif(path)))
  })

  it("writes FCCS fuelbeds and map zones as bands 9-10, uncorrected", {
    s <- fake_stack()
    # a disturbed fuelbed: 531 * 10000 + disturbance 122, past the 16-bit limit
    extra <- terra$setValues(s[[1:2]], rep(c(5310122, 15), each = terra$ncell(s)))
    s <- c(s, extra)
    names(s) <- c(impl$band_names(), "fccs", "map_zone")
    v <- terra$values(s)
    v[1, 9] <- NA # FCCS gap (e.g. water) is not counted as landscape NoData
    s <- terra$setValues(s, v)
    path <- lcp$write_iftdss_tif(s, tempfile(fileext = ".tif"))
    back <- terra$rast(path)

    expect_equal(terra$nlyr(back), 10)
    expect_equal(names(back)[9:10], c("fccs", "map_zone"))
    expect_equal(unname(unlist(back[2])), c(2000, 10, 180, 165, 40, 150, 20, 10, 5310122, 15))
    expect_true(is.na(unlist(back[1])[[9]]))
    expect_equal(attr(path, "bands"), 10)
    expect_equal(attr(path, "nodata_share"), 0)
    expect_false(grepl("8 LCP bands only", lcp$describe_iftdss_tif(path)))
  })

  it("notes when the GeoTIFF has the 8 LCP bands only", {
    path <- lcp$write_iftdss_tif(fake_stack(), tempfile(fileext = ".tif"))
    expect_true(grepl("8 LCP bands only", lcp$describe_iftdss_tif(path)))
  })

  it("flags a landscape IFTDSS would reject for too much NoData", {
    s <- fake_stack()
    v <- terra$values(s)
    v[seq_len(ceiling(0.6 * nrow(v))), ] <- NA
    path <- lcp$write_iftdss_tif(terra$setValues(s, v), tempfile(fileext = ".tif"))

    expect_true(grepl("IFTDSS rejects more than 50%", lcp$describe_iftdss_tif(path)))
  })

  it("refuses rectangular cells", {
    s <- terra$rast(nrows = 10, ncols = 10, xmin = 0, xmax = 300, ymin = 0, ymax = 600,
                    crs = "EPSG:5070", nlyrs = 8)
    expect_error(lcp$write_iftdss_tif(s, tempfile(fileext = ".tif")), "square")
  })
})
