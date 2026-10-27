box::use(
  here[here],
  testthat[describe, expect_equal, expect_identical, expect_null, it, skip_if_offline],
)

box::use(
  app/logic/report_cover,
)

describe("read_image and image_ratio", {
  it("reads a PNG and gives its height-to-width ratio", {
    img <- report_cover$read_image(here("app", "static", "images", "intelimon_logo.png"))
    expect_equal(report_cover$image_ratio(img), 132 / 114)
  })

  it("returns NULL for a missing or unsupported file", {
    expect_null(report_cover$read_image(NULL))
    expect_null(report_cover$read_image(tempfile(fileext = ".png")))
    txt <- tempfile(fileext = ".txt")
    writeLines("x", txt)
    expect_null(report_cover$read_image(txt))
  })
})

describe("fetch_cover_image", {
  it("returns NULL without a tile URL or when the download fails", {
    date <- as.Date("2024-01-01")
    expect_null(report_cover$fetch_cover_image("A", "1", date, tiles = NULL))
    bad <- "http://127.0.0.1:9/%s/%s_%s_%s_%s_%s/%d/%d/%d.jpg"
    expect_null(report_cover$fetch_cover_image("A", "1", date, tiles = bad))
  })
})

describe("fetch_cover_image from Points2Pano", {
  it("makes a 4:3 photo from the front cube face", {
    skip_if_offline("burnpro3d.sdsc.edu")
    path <- report_cover$fetch_cover_image("GAFSQ", "1085", as.Date("2022-02-15"), 1,
                                           dir = tempdir())
    img <- report_cover$read_image(path)
    expect_equal(dim(img), c(768L, 1024L, 3L))
  })
})

describe("attach_cover_image", {
  it("leaves the blocks alone when there is no cover scan or image", {
    blocks <- list(list(type = "title_page", image = NULL))
    expect_identical(report_cover$attach_cover_image(blocks, NULL), blocks)
    # an address nothing answers on, so the fetch fails without the network
    cover <- list(site = "A", plot = "1", date = as.Date("2024-01-01"), scanner = 1)
    nowhere <- "http://127.0.0.1:9/%s%s%s%s%s%s%d%d%d"
    expect_identical(report_cover$attach_cover_image(blocks, cover, tiles = nowhere), blocks)
  })
})
