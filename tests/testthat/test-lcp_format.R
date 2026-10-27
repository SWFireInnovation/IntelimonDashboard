box::use(
  terra,
  testthat[describe, expect_equal, expect_error, expect_true, it],
)

box::use(
  app/logic/lcp_format,
)

impl <- attr(lcp_format, "namespace")

# 4 x 3 grid (12 cells), 30 m cells, with negative values that crash GDAL's LCP
# writer before 3.6.4: elevation below sea level and flat aspect -1
make_values <- function() {
  cbind(
    elevation = c(-86L, -10L, 0L, 5L, 10L, 20L, 30L, 40L, 50L, 60L, 70L, 80L),
    slope = rep(c(0L, 5L), 6),
    aspect = rep(c(-1L, 180L), 6),
    fuel = rep(c(98L, 102L, 165L), 4),
    canopy_cover = rep(c(0L, 40L), 6),
    stand_height = rep(c(0L, 150L), 6),
    canopy_base = rep(c(0L, 20L), 6),
    canopy_bulk = rep(c(0L, 10L), 6)
  )
}
extent <- c(500000, 500120, 1500000, 1500090) # xmin, xmax, ymin, ymax

write_test_lcp <- function(values = make_values()) {
  path <- tempfile(fileext = ".lcp")
  lcp_format$write_lcp_binary(
    path, values,
    ncol = 4, nrow = 3, extent = extent, resolution = c(30, 30), latitude = 36
  )
  path
}

read_int32 <- function(bytes, offset, n = 1) {
  readBin(bytes[(offset + 1):(offset + 4 * n)], "integer", n, size = 4, endian = "little")
}
read_double <- function(bytes, offset, n = 1) {
  readBin(bytes[(offset + 1):(offset + 8 * n)], "double", n, size = 8, endian = "little")
}

describe("write_lcp_binary", {
  it("writes a 7316-byte header followed by 2 bytes per band per cell", {
    path <- write_test_lcp()
    expect_equal(file.size(path), 7316 + 12 * 8 * 2)
  })

  it("lays out the header like GDAL's LCP driver", {
    b <- readBin(write_test_lcp(), "raw", 7316)
    expect_equal(read_int32(b, 0, 3), c(21L, 20L, 36L))
    expect_equal(read_double(b, 12, 4), c(500120, 500000, 1500090, 1500000))
    expect_equal(read_int32(b, 4164, 2), c(4L, 3L))
    expect_equal(read_double(b, 4172, 4), c(500120, 500000, 1500090, 1500000))
    expect_equal(read_int32(b, 4204), 0L)
    expect_equal(read_double(b, 4208, 2), c(30, 30))
    expect_equal(
      readBin(b[4225:4244], "integer", 10, size = 2, endian = "little"),
      c(0L, 0L, 2L, 0L, 1L, 3L, 3L, 3L, 1L, 0L)
    )
  })

  it("records each band's min, max and sorted distinct values, including negatives", {
    b <- readBin(write_test_lcp(), "raw", 7316)
    aspect <- 44 + 2 * 412
    expect_equal(read_int32(b, aspect, 5), c(-1L, 180L, 2L, 0L, -1L))
    expect_equal(read_int32(b, aspect + 20), 180L)
    fuel <- 44 + 3 * 412
    expect_equal(read_int32(b, fuel, 6), c(98L, 165L, 3L, 0L, 98L, 102L))
  })

  it("marks bands with 100 or more distinct values with a count of -1", {
    expect_equal(impl$band_classes(1:150)[1:4], c(1L, 150L, -1L, 0L))
    expect_equal(impl$band_classes(c(1:98, -9999L))[3], 98L)
  })

  it("reads back through GDAL with the same values", {
    values <- make_values()
    r <- terra$rast(write_test_lcp(values))
    expect_equal(terra$nlyr(r), 8)
    expect_equal(dim(r)[1:2], c(3, 4))
    expect_equal(unname(terra$values(r)), unname(values * 1.0))
  })

  it("refuses NA, out-of-range values and a wrong band count", {
    v <- make_values()
    v[1, 1] <- NA
    expect_error(write_test_lcp(v), "NA")
    v <- make_values()
    v[1, 1] <- 40000L
    expect_error(write_test_lcp(v), "16-bit")
    expect_error(write_test_lcp(make_values()[, 1:5]), "8 bands")
  })
})

describe("write_esri_prj", {
  it("writes the ESRI WKT1 projection FlamMap reads", {
    prj <- lcp_format$write_esri_prj("EPSG:5070", tempfile(fileext = ".prj"))
    txt <- paste(readLines(prj, warn = FALSE), collapse = "")
    expect_true(startsWith(txt, 'PROJCS["NAD_1983_Contiguous_USA_Albers"'))
    expect_true(grepl('PROJECTION["Albers"]', txt, fixed = TRUE))
  })
})
