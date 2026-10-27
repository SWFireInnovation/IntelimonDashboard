box::use(
  data.table[data.table],
  testthat[describe, expect_equal, it],
)

box::use(
  app/logic/map_fnc,
)

# GeoJSON feature as leaflet.extras sends it: a list of [lng, lat] pairs,
# closed on the first vertex
feature <- function(...) {
  pts <- list(...)
  list(type = "Feature", geometry = list(type = "Polygon", coordinates = list(c(pts, pts[1]))))
}

scans <- data.table(
  site = c("A", "A", "B", "C"),
  plot = c("1", "2", "1", "1"),
  Longitude = c(-105.6, -105.1, -104.5, -105.5),
  Latitude = c(35.5, 35.9, 35.5, 36.5)
)

describe("in_drawn_shape", {
  it("finds the scans inside a drawn rectangle", {
    rect <- feature(list(-106, 35), list(-106, 36), list(-105, 36), list(-105, 35))
    expect_equal(map_fnc$in_drawn_shape(scans, rect), c(TRUE, TRUE, FALSE, FALSE))
  })

  it("follows the edges of a drawn polygon", {
    # triangle with its slanted edge between the two A plots
    tri <- feature(list(-106, 35), list(-106, 36), list(-105, 35))
    expect_equal(map_fnc$in_drawn_shape(scans, tri), c(TRUE, FALSE, FALSE, FALSE))
  })

  it("selects nothing for other shapes", {
    line <- list(geometry = list(type = "LineString", coordinates = list()))
    expect_equal(map_fnc$in_drawn_shape(scans, line), rep(FALSE, 4))
  })
})
