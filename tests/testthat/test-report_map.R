box::use(
  png[readPNG],
  testthat[describe, expect_equal, expect_false, expect_true, it],
)

box::use(
  app/logic/report_map,
)

impl <- attr(report_map, "namespace")

describe("map_window", {
  it("never zooms past the deepest imagery level, even for one plot", {
    win <- report_map$map_window(-81.84, 31.99)
    expect_true(win$z <= impl$MAX_ZOOM)
    # the window still spans at least the minimum extent
    span_lat <- diff(sapply(c(win$y0 + win$height, win$y0), function(px) {
      n <- pi - 2 * pi * px / (impl$TILE_PX * 2^win$z)
      180 / pi * atan(0.5 * (exp(n) - exp(-n)))
    }))
    expect_true(span_lat >= impl$MIN_SPAN)
  })

  it("crops the window to the plots at a 3:2 aspect, never below the minimum width", {
    win <- report_map$map_window(c(-81.84, -81.82), c(31.98, 31.99))
    expect_true(win$width >= impl$MIN_W && win$width <= impl$MAP_W)
    expect_equal(win$width / win$height, 1.5, tolerance = 0.01)
  })

  it("zooms out to fit plots that are far apart", {
    near <- report_map$map_window(c(-81.84, -81.82), c(31.98, 31.99))
    far <- report_map$map_window(c(-82, -81), c(31, 32))
    expect_true(far$z < near$z)
    expect_true(diff(impl$lon_px(c(-82, -81), far$z)) <= far$width)
  })
})

describe("render_plot_map", {
  it("draws the plots on a plain background when the imagery can't be fetched", {
    pts <- data.frame(site = "A", plot = c("1", "2"), lon = c(-81.84, -81.83), lat = c(31.99, 32))
    path <- tempfile(fileext = ".png")
    out <- report_map$render_plot_map(pts, path, tiles = "http://127.0.0.1:9/%d/%d/%d")
    expect_false(attr(out, "basemap"))
    win <- report_map$map_window(pts$lon, pts$lat)
    expect_equal(dim(readPNG(path))[1:2], c(win$height, win$width))
  })
})
