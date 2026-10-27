box::use(
  officer[docx_summary, read_docx],
  testthat[describe, expect_equal, expect_false, expect_true, it],
  utils[unzip],
)

box::use(
  app/logic/report_docx,
)

describe("render_docx", {
  it("writes a Word file holding the report's text and tables", {
    path <- tempfile(fileext = ".docx")
    report_docx$render_docx(sample_report_blocks(), path, as.Date("2026-10-12"))
    expect_true(file.exists(path))
    s <- docx_summary(read_docx(path))
    text <- paste(s$text, collapse = " ")
    for (x in c("Test report", "Figure 1.", "Table 3.", "Midstory volume", "rothRmel tab",
                "About these data", "Scans, plots and treatments", "Sample size and design",
                "Only 1 plot is loaded.", "reduced ladder fuels", "Notes on the results.",
                "Contents", "Disclaimer:", "Cover Photo:", "Points2Pano image not available",
                "Prepared by Tester", "Stem map", "Forestry", "Image not available")) {
      expect_true(grepl(x, text, fixed = TRUE), info = x)
    }
    expect_equal(length(unique(s$doc_index[s$content_type == "table cell"])), 3)
  })

  it("writes the contents out with dot leaders and page numbers to fill in", {
    path <- tempfile(fileext = ".docx")
    report_docx$render_docx(sample_report_blocks(), path)
    dir <- tempfile()
    unzip(path, files = "word/document.xml", exdir = dir)
    xml <- paste(readLines(file.path(dir, "word", "document.xml"), warn = FALSE), collapse = "")
    expect_true(grepl("w:val=\"right\" w:leader=\"dot\"", xml, fixed = TRUE))
    expect_false(grepl("TOC \\\\", xml, fixed = TRUE))
    s <- docx_summary(read_docx(path))
    entry <- paste0("Sample size and design", report_docx$TOC_PAGE_PLACEHOLDER)
    expect_true(entry %in% s$text, info = paste(head(s$text, 40), collapse = " | "))
  })
})
