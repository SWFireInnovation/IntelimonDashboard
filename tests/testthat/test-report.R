box::use(
  testthat[describe, expect_equal, expect_false, expect_true, it],
)

box::use(
  app/logic/report,
)

fig <- function(title = "Midstory volume", source = "Standard outputs", analysis = NULL) {
  report$report_item("figure", title, source,
    settings = list(`Plot type` = "Box and Whisker", `Data type` = "Percent change"),
    plot = "a ggplot", analysis = analysis
  )
}
tbl <- function() {
  report$report_item("table", "Midstory volume", "Standard outputs",
    table = data.frame(a = 1), note = "One row per time step."
  )
}
types <- function(blocks) vapply(blocks, `[[`, character(1), "type")
titles <- function(items) vapply(items, `[[`, character(1), "title")
headings <- function(blocks) {
  unlist(lapply(Filter(function(x) x$type == "heading", blocks), `[[`, "text"))
}
# The report body: everything after the table of contents and its page break,
# up to the About these data section that closes every report.
blocks_of <- function(...) {
  b <- report$report_blocks(...)
  b <- b[-seq_len(which(types(b) == "toc") + 1)]
  about <- which(vapply(b, function(x) identical(x$text, "About these data"), logical(1)))
  b[seq_len(about - 1)]
}

describe("report items", {
  it("gives every item its own id", {
    expect_false(fig()$id == fig()$id)
  })

  it("starts a report with optional text blocks around the standard sections", {
    items <- report$default_report_items()
    expect_equal(vapply(items, `[[`, character(1), "kind"),
                 c("note", "note", "section", "section", "section", "note", "note"))
    expect_equal(vapply(items[3:5], `[[`, character(1), "key"), c("context", "map", "design"))
    expect_equal(vapply(items[c(1, 2, 6, 7)], `[[`, character(1), "heading"),
                 c("Introduction", "Data description", "Results", "Management relevance"))
    expect_true(all(vapply(items[c(1, 2, 6, 7)], `[[`, logical(1), "optional")))
    expect_equal(report$missing_sections(items), character())
    expect_equal(report$missing_sections(items[6]), c("context", "map", "design"))
  })
})

describe("insert_after and add_data_item", {
  it("inserts after the given id, or at the end", {
    items <- list(fig("A"), fig("B"))
    expect_equal(titles(report$insert_after(items, fig("C"), items[[1]]$id)), c("A", "C", "B"))
    expect_equal(titles(report$insert_after(items, fig("C"))), c("A", "B", "C"))
    expect_equal(titles(report$insert_after(items, fig("C"), "gone")), c("A", "B", "C"))
  })

  it("puts card data after Results, then after the last figure or table", {
    items <- report$default_report_items()
    items <- report$add_data_item(items, fig("A"))
    items <- report$add_data_item(items, fig("B"))
    expect_equal(tail(titles(items), 4), c("Text block", "A", "B", "Text block"))
    expect_equal(items[[length(items)]]$heading, "Management relevance")
    expect_equal(titles(report$add_data_item(list(), fig("A"))), "A")
  })
})

describe("settings_line", {
  it("joins settings and skips empty ones", {
    s <- list(`Plot type` = "Bar", `Error bars` = NULL, Blank = "", `Data type` = "Values")
    expect_equal(report$settings_line(s), "Plot type: Bar; Data type: Values")
    expect_equal(report$settings_line(list()), "")
  })
})

describe("move_item and remove_item", {
  items <- list(fig("A"), report$note_item("B"), fig("C"))

  it("swaps neighbours of any kind and ignores moves past either end", {
    expect_equal(titles(report$move_item(items, items[[2]]$id, "up")), c("Text block", "A", "C"))
    expect_equal(titles(report$move_item(items, items[[2]]$id, "down")), c("A", "C", "Text block"))
    expect_equal(titles(report$move_item(items, items[[1]]$id, "up")), c("A", "Text block", "C"))
    expect_equal(titles(report$move_item(items, items[[3]]$id, "down")), c("A", "Text block", "C"))
  })

  it("removes by id", {
    expect_equal(titles(report$remove_item(items, items[[2]]$id)), c("A", "C"))
  })
})

describe("report_blocks", {
  meta <- list(title = "Big Creek", summary = "First.\n\nSecond.")
  context <- list(
    scan = list(text = "This report draws on 4 scans.", plots = data.frame(Site = "A"),
                steps = data.frame(`Time step` = 1, check.names = FALSE)),
    checks = c("Only 2 plots are loaded.")
  )

  it("numbers figures and tables separately, in report order", {
    b <- blocks_of(list(fig(), tbl(), fig()), meta)
    expect_equal(unlist(lapply(b, `[[`, "label")), c("Figure 1.", "Table 1.", "Figure 2."))
  })

  it("lays out sections and notes where they sit in the list", {
    items <- list(
      report$section_item("context"), report$note_item("Fuels", "Fuel notes."), fig(),
      report$section_item("design")
    )
    b <- blocks_of(items, meta, context)
    expect_equal(headings(b), c(
      "Summary", "Scans, plots and treatments", "Fuels", "Midstory volume",
      "Sample size and design", "All loaded scans"
    ))
    # the context tables come first, so the figure follows them and is Figure 1
    labels <- unlist(lapply(b, `[[`, "label"))
    expect_equal(labels, c("Table 1.", "Table 2.", "Figure 1."))
    expect_true("bullet" %in% types(b))
  })

  it("reports when there are no design issues or no scans", {
    items <- list(report$section_item("context"), report$section_item("design"))
    b <- blocks_of(items, meta, context = NULL)
    texts <- unlist(lapply(Filter(function(x) x$type == "paragraph", b), `[[`, "text"))
    expect_true(any(grepl("No scans were loaded", texts)))
    expect_true(any(grepl("No sample size or design issues", texts)))
  })

  it("prints the automated description unless it is switched off", {
    a <- list(summary = "Summary text.", cautions = c("Small sample."), implication = "Meaning.")
    with <- blocks_of(list(fig(analysis = a)), meta)
    expect_equal(types(with)[-(1:3)],
                 c("heading", "figure", "paragraph", "bullet", "paragraph"))
    item <- fig(analysis = a)
    item$include_analysis <- FALSE
    without <- blocks_of(list(item), meta)
    expect_equal(types(without)[-(1:3)], c("heading", "figure"))
  })

  it("points a repeated description back to the item that first gave it", {
    a <- list(summary = "Same data.", cautions = character(), implication = NULL)
    item_tbl <- tbl()
    item_tbl$analysis <- a
    b <- blocks_of(list(fig(analysis = a), item_tbl), meta)
    texts <- unlist(lapply(Filter(function(x) x$type == "paragraph", b), `[[`, "text"))
    expect_equal(sum(texts == "Same data."), 1)
    expect_true("These data are described under Figure 1." %in% texts)
  })

  it("lists item notes under Sample size and design with a pointer under the item", {
    a <- list(summary = "Data.", cautions = c("Small sample."), implication = NULL)
    items <- list(report$section_item("design"), fig(analysis = a))
    b <- blocks_of(items, meta, context)
    ty <- types(b)
    # the design section names the figure and lists its note
    label <- b[[which(ty == "label")]]
    expect_equal(label$text, "Figure 1. Midstory volume")
    expect_equal(b[[which(ty == "label") + 1]]$text, "Small sample.")
    expect_true("Figures and tables" %in% headings(b))
    # under the figure: the red pointer, and no inline bullets
    at <- which(ty == "figure")
    expect_equal(ty[at + 1], "flag")
    expect_equal(b[[at + 1]]$text, report$DESIGN_POINTER)
    expect_false("bullet" %in% ty[at:length(ty)])
  })

  it("lists a graph and its statistics table together, flagging both", {
    a <- list(summary = "Data.", cautions = c("Small sample."), implication = NULL)
    item_tbl <- tbl()
    item_tbl$analysis <- a
    items <- list(report$section_item("design"), fig(analysis = a), item_tbl)
    b <- blocks_of(items, meta, context)
    ty <- types(b)
    expect_equal(sum(ty == "flag"), 2)
    expect_equal(sum(ty == "label"), 1)
    expect_equal(b[[which(ty == "label")]]$text, "Figure 1 and Table 1. Midstory volume")
  })

  it("keeps item notes under the item when the report has no design section", {
    a <- list(summary = "Data.", cautions = c("Small sample."), implication = NULL)
    b <- blocks_of(list(fig(analysis = a)), meta)
    expect_false("flag" %in% types(b))
    expect_equal(types(b)[-(1:3)], c("heading", "figure", "paragraph", "bullet"))
  })

  it("says when nothing at all is flagged", {
    b <- blocks_of(list(report$section_item("design")), meta,
                   list(scan = NULL, checks = character()))
    texts <- unlist(lapply(Filter(function(x) x$type == "paragraph", b), `[[`, "text"))
    expect_true(any(grepl("No sample size or design issues", texts)))
  })

  it("adds a comment under its item", {
    items <- list(fig())
    items[[1]]$comment <- "Volume fell after the burn."
    b <- blocks_of(items, meta)
    expect_equal(b[[length(b)]]$text, "Volume fell after the burn.")
    expect_true(grepl("^Source: Standard outputs; Plot type", b[[length(b) - 1]]$settings))
  })

  it("adds the rothRmel caveat only when rothRmel output is included", {
    without <- blocks_of(list(fig()), meta)
    with <- blocks_of(list(fig(source = "rothRmel")), meta)
    expect_false("warning" %in% types(without))
    expect_true("warning" %in% types(with))
  })

  it("adds the custom model caveat only when custom model output is included", {
    warnings <- function(items) {
      b <- blocks_of(items, meta)
      unlist(lapply(Filter(function(x) x$type == "warning", b), `[[`, "text"))
    }
    expect_null(warnings(list(fig())))
    expect_equal(warnings(list(fig(source = "Custom models"))), report$CUSTOM_MODEL_CAVEAT)
    expect_equal(
      warnings(list(fig(source = "Custom models"), fig(source = "rothRmel"))),
      c(report$ROTHRMEL_CAVEAT, report$CUSTOM_MODEL_CAVEAT)
    )
  })

})

describe("front matter", {
  meta <- list(title = "", subtitle = "Unit A", author = "Tester", organization = "Org",
               date = "October 13, 2026")
  cover <- list(caption = "Cover Photo: USFS, GAFSQ, plot 1085, 02/15/2022, Points2Pano image")

  it("opens with a title page, then the cover photo page, then the contents", {
    b <- report$report_blocks(list(), meta, cover = cover)
    ty <- types(b)
    expect_equal(ty[1:4], c("title_page", "page_break", "cover_caption", "ruled_lines"))
    expect_equal(b[[1]]$title, "IntELiMon monitoring report")
    expect_equal(b[[1]]$subtitle, "Unit A")
    expect_equal(unlist(b[[1]]$lines), c("Prepared by Tester", "Org", "October 13, 2026"))
    expect_equal(b[[3]]$text, cover$caption)
    expect_equal(b[[4]]$n, 5)
    texts <- unlist(lapply(b, `[[`, "text"))
    expect_true(report$DISCLAIMER %in% texts)
    expect_true(report$ORIGIN_TEXT %in% texts)
    # About these data sits on the cover photo page, before the contents
    expect_true(which(texts == "About these data")[1] < which(ty == "toc"))
    expect_equal(ty[which(ty == "toc") + 1], "page_break")
  })

  it("repeats About these data at the end, listed in the contents only there", {
    b <- report$report_blocks(list(), meta, cover = cover)
    about <- which(vapply(b, function(x) identical(x$text, "About these data"), logical(1)))
    expect_equal(length(about), 2)
    expect_true(about[1] < which(types(b) == "toc"))
    expect_false(b[[about[1]]]$toc)
    expect_true(b[[about[2]]]$toc)
    expect_equal(b[[length(b)]]$type, "paragraph")
  })

  it("lists the body's headings in the contents, not the front matter's", {
    items <- list(report$section_item("design"), report$note_item("Results"), tbl())
    b <- report$report_blocks(items, list(summary = "Text."), list(checks = "One check."))
    toc <- b[[which(types(b) == "toc")]]$entries
    expect_equal(vapply(toc, `[[`, character(1), "text"), c(
      "Summary", "Sample size and design", "All loaded scans", "Results", "Midstory volume",
      "About these data", "References"
    ))
    expect_equal(vapply(toc, `[[`, numeric(1), "level"), c(1, 1, 2, 1, 2, 1, 1))
  })

  it("puts a graph and its statistics under one heading with a subheading each", {
    graph <- fig()
    graph$subheading <- "Box and Whisker plot"
    stats <- tbl()
    stats$subheading <- "Statistics"
    other <- report$report_item("image", "Stem map", "Forestry exports", group = "Forestry")
    b <- report$report_blocks(list(report$note_item("Results"), graph, stats, other), list())
    toc <- b[[which(types(b) == "toc")]]$entries
    texts <- vapply(toc, `[[`, character(1), "text")
    expect_equal(texts[1:5], c("Results", "Midstory volume", "Box and Whisker plot",
                               "Statistics", "Forestry"))
    expect_equal(vapply(toc, `[[`, numeric(1), "level")[1:5], c(1, 2, 3, 3, 2))
  })

  it("draws the plot locations map as a figure from the selected plots", {
    pts <- data.frame(site = "A", plot = c("1", "2"), lon = c(-81, -81.01), lat = c(32, 32.01))
    b <- blocks_of(list(report$section_item("map")), list(), list(points = pts))
    map <- Filter(function(x) x$type == "image", b)[[1]]
    expect_equal(map$label, "Figure 1.")
    expect_equal(map$title, "Locations of the two plots in this report.")
    expect_equal(map$map, pts)
    empty <- blocks_of(list(report$section_item("map")), list(), list(points = NULL))
    expect_false("image" %in% types(empty))
  })
})

describe("cover_caption", {
  it("lists agency, site, plot and date, skipping blanks", {
    expect_equal(
      report$cover_caption("USFS", "GAFSQ", "1085", as.Date("2022-02-15")),
      "Cover Photo: USFS, GAFSQ, plot 1085, 02/15/2022, Points2Pano image"
    )
    expect_equal(
      report$cover_caption(NA, "GAFSQ", "1085", as.Date("2022-02-15")),
      "Cover Photo: GAFSQ, plot 1085, 02/15/2022, Points2Pano image"
    )
  })
})

describe("report_filename", {
  it("names the file from the title and the date code", {
    expect_equal(
      report$report_filename("GAFSQ treatment: 2022 burn", "pdf", as.Date("2026-10-13")),
      "GAFSQ_treatment_2022_burn_20261013.pdf"
    )
    expect_equal(
      report$report_filename("", "docx", as.Date("2026-10-13")),
      "IntELiMon_monitoring_report_20261013.docx"
    )
  })
})

describe("optional text blocks", {
  it("are left out while blank, unless figures or tables follow", {
    items <- list(
      report$note_item("Introduction", optional = TRUE),
      report$note_item("Results", optional = TRUE), fig(),
      report$note_item("Management relevance", "Thin before burning.", optional = TRUE),
      report$note_item("Plain heading")
    )
    expect_equal(headings(blocks_of(items, list())), c(
      "Results", "Midstory volume", "Management relevance", "Plain heading"
    ))
  })
})

describe("methods and references", {
  fire <- function() {
    report$report_item("figure", "Flame length", "rothRmel", plot = "a ggplot",
                       methods = c("fire_model", "brown"))
  }
  stand <- function() {
    report$report_item("table", "Stand metrics", "Forestry exports",
                       table = data.frame(a = 1), methods = "stand_density")
  }
  texts <- function(blocks) {
    vapply(blocks, function(x) if (is.null(x$text)) "" else x$text, character(1))
  }
  # the text of each About these data section (up to the next heading or
  # page break), front matter copy first
  about_sections <- function(b) {
    t <- texts(b)
    lapply(which(t == "About these data"), function(i) {
      stop_at <- which(vapply(b, function(x) x$type %in% c("heading", "label", "page_break"),
                              logical(1)))
      t[(i + 1):(min(stop_at[stop_at > i]) - 1)]
    })
  }
  # the paragraphs after the References heading
  references <- function(b) {
    t <- texts(b)
    at <- which(t == "References")
    t[-seq_len(at)]
  }

  it("lists only the base text and references when no item uses a method", {
    b <- report$report_blocks(list(fig()), list())
    for (sec in about_sections(b)) expect_equal(length(sec), 1)
    expect_equal(sub(" [(].*", "", references(b)),
                 c("Murphy, M. C., Loudermilk, E. L., Pokswinski, S., et al.",
                   "Pokswinski, S., Nelson, K., Maxwell, A., et al."))
  })

  it("explains each method used in both copies of About these data", {
    secs <- about_sections(report$report_blocks(list(stand(), fire(), fire()), list()))
    expect_equal(length(secs), 2)
    for (t in secs) {
      # one paragraph per method, in METHODS order
      expect_equal(sum(t == report$METHODS$fire_model$text), 1)
      expect_true(match(report$METHODS$fire_model$text, t) <
                    match(report$METHODS$stand_density$text, t))
      expect_true(report$METHODS$brown$text %in% t)
      expect_false(report$METHODS$fbfm40$text %in% t)
    }
  })

  it("compiles every reference once, in one section that ends the report", {
    b <- report$report_blocks(list(stand(), fire(), fire()), list())
    t <- texts(b)
    expect_equal(sum(t == "References"), 1)
    head <- b[[which(t == "References")]]
    expect_equal(head$level, 1)
    expect_null(head$toc)
    refs <- references(b)
    expect_equal(length(refs), 12)
    expect_equal(refs, sort(refs, method = "radix"))
    expect_true(any(startsWith(refs, "Reineke, L. H. (1933)")))
    expect_false(any(startsWith(refs, "Scott, J. H., & Burgan")))
    expect_equal(b[[length(b)]]$text, refs[length(refs)])
  })

  it("cites every reference a method names", {
    keys <- unlist(lapply(report$METHODS, `[[`, "refs"))
    expect_true(all(keys %in% names(attr(report, "namespace")$REFERENCE_TEXT)))
  })
})

describe("forestry methods", {
  it("cites SDI, FVS and the fire and fuels extension when their items are included", {
    stand <- report$report_item("table", "Stand metrics", "Forestry exports",
                                table = data.frame(a = 1),
                                methods = c("occlusion", "stand_density"))
    fvs <- report$report_item("table", "FVS export", "Forestry exports",
                              table = data.frame(a = 1), methods = c("fvs", "ffe"))
    b <- report$report_blocks(list(stand, fvs), list())
    t <- unlist(lapply(b, `[[`, "text"))
    for (m in c("occlusion", "stand_density", "fvs", "ffe")) {
      expect_true(report$METHODS[[m]]$text %in% t, info = m)
    }
    for (r in c("Reineke, L. H.", "Curtis, R. O.", "Dixon, G. E.", "Reinhardt, E. D.")) {
      expect_true(any(startsWith(t, r)), info = r)
    }
  })
})

describe("us_date_block", {
  impl <- attr(report, "namespace")

  it("writes dates in text and tables as MM/DD/YYYY", {
    b <- impl$us_date_block(list(type = "paragraph", text = "Scanned on 2025-05-15."))
    expect_equal(b$text, "Scanned on 05/15/2025.")
    tab <- data.frame(`Time step` = c("2024-01-01", "2024-06-01"), n = c("4", "4"),
                      check.names = FALSE)
    b <- impl$us_date_block(list(type = "table", title = "Steps", data = tab))
    expect_equal(b$data$`Time step`, c("01/01/2024", "06/01/2024"))
    expect_equal(b$data$n, c("4", "4"))
  })
})
