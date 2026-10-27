box::use(
  grDevices[dev.off, pdf],
  testthat[describe, expect_equal, expect_gt, expect_true, it],
)

box::use(
  app/logic/report_pdf,
)

impl <- attr(report_pdf, "namespace")

describe("render_pdf", {
  it("writes a multi-page PDF", {
    path <- tempfile(fileext = ".pdf")
    out <- report_pdf$render_pdf(sample_report_blocks(), path, as.Date("2026-10-12"))
    expect_true(file.exists(path))
    expect_equal(rawToChar(readBin(path, "raw", 5)), "%PDF-")
    expect_gt(attr(out, "pages"), 1)
  })
})

describe("layout_pass", {
  it("finds a page for every contents entry, after the front matter", {
    blocks <- sample_report_blocks()
    toc <- Filter(function(b) b$type == "toc", blocks)[[1]]
    lay <- impl$layout_pass(blocks, tempfile(fileext = ".pdf"), Sys.Date(), integer())
    expect_equal(length(lay$headings), length(toc$entries))
    # title page, cover photo page and contents come first
    expect_true(all(lay$headings >= 4))
    expect_true(all(diff(lay$headings) >= 0))
  })
})

describe("wrap_text", {
  it("wraps to the width and keeps explicit line breaks", {
    pdf(NULL)
    on.exit(dev.off())
    g <- impl$gp(10)
    lines <- impl$wrap_text(paste(rep("word", 60), collapse = " "), g, 3)
    expect_gt(length(lines), 3)
    expect_true(all(vapply(lines, impl$text_width, numeric(1), g = g) <= 3))
    expect_equal(impl$wrap_text("one\ntwo", g, 6), c("one", "two"))
  })
})

describe("table_geometry", {
  it("sizes each column to its widest cell, not its header", {
    pdf(NULL)
    on.exit(dev.off())
    df <- data.frame(Site = c("A", "A much longer site name"), Plot = c("1", "2"))
    geo <- impl$table_geometry(df, 6.5)
    widest <- impl$text_width("A much longer site name", impl$gp(geo$size, face = "bold"))
    expect_true(geo$widths[1] > widest)
  })
})

describe("shrink_image", {
  it("thins a wide image to the pixel limit and leaves small ones alone", {
    img <- array(0, c(1024, 3072, 3))
    expect_equal(dim(impl$shrink_image(img, 1300)), c(342, 1024, 3))
    small <- array(0, c(10, 20, 3))
    expect_equal(impl$shrink_image(small, 1300), small)
    expect_equal(impl$shrink_image(NULL, 1300), NULL)
  })
})

describe("pdf_text", {
  it("turns subscript digits into plain digits", {
    expect_equal(impl$pdf_text("I\u2080 and R\u2080"), "I0 and R0")
  })
})
