# ---------------------------------------------------------------------------
# Word (.docx) writer for the report builder. Renders the blocks from
# report_blocks() (app/logic/report.R) with officer and flextable, styled from
# REPORT_STYLE so the document matches the PDF writer. Pure R: no pandoc, so it
# runs the same on the server and in the desktop build.
# ---------------------------------------------------------------------------

box::use(
  flextable,
  officer,
  utils[unzip],
  zip[zip],
)

box::use(
  app/logic/report[REPORT_STYLE, footer_text],
  app/logic/report_cover[image_ratio, read_image],
)

txt <- function(size, color = REPORT_STYLE$ink, bold = FALSE, italic = FALSE) {
  officer$fp_text(
    font.family = REPORT_STYLE$font, font.size = size, color = color,
    bold = bold, italic = italic
  )
}

pp <- function(before = 0, after = 6, align = "left", rule = FALSE, indent = 0, tabs = NULL) {
  officer$fp_par(
    text.align = align, padding.top = before, padding.bottom = after, padding.left = indent,
    line_spacing = 1.15,
    border.bottom = if (rule) officer$fp_border(color = REPORT_STYLE$rule, width = 1) else
      officer$fp_border(width = 0),
    tabs = tabs
  )
}

#' Page number placeholder in the Word table of contents, highlighted so it
#' is easy to find and type over.
#' @export
TOC_PAGE_PLACEHOLDER <- "#"

# Table of contents: each heading, a dotted leader and a placeholder for its
# page number. Word only fills in a table of contents field when it refreshes
# fields on opening, which Protected View and other editors skip, so the
# entries are written out and the page numbers are left to fill in. The
# right tab's dot leader is set by dot_leaders() after the file is saved.
add_toc <- function(doc, b) {
  s <- REPORT_STYLE
  doc <- add_par(doc, officer$ftext("Contents", txt(s$size_h1, s$accent, bold = TRUE)),
                 fp_p = pp(after = 8))
  tabs <- officer$fp_tabs(officer$fp_tab(s$page_width - 2 * s$margin, style = "right"))
  for (e in b$entries) {
    top <- e$level == 1
    size <- if (top) s$size_body + 1 else s$size_body
    page <- txt(size, bold = top)
    page$shading.color <- "#fff3bf"
    # no `style`: officer rewrites the paragraph properties for one, dropping the tab stop
    doc <- officer$body_add_fpar(doc, officer$fpar(
      officer$ftext(e$text, txt(size, bold = top)),
      officer$run_tab(),
      officer$ftext(TOC_PAGE_PLACEHOLDER, page),
      fp_p = pp(before = if (top) 4 else 0, after = 2, indent = (e$level - 1) * 18, tabs = tabs)
    ))
  }
  doc
}

add_par <- function(doc, ..., fp_p = pp(), style = "Normal") {
  officer$body_add_fpar(doc, officer$fpar(..., fp_p = fp_p), style = style)
}

# Caption: bold label + title, then the settings line in small grey type.
add_caption <- function(doc, b, before = 4) {
  doc <- add_par(doc,
    officer$ftext(paste0(b$label, " "), txt(REPORT_STYLE$size_caption, bold = TRUE)),
    officer$ftext(b$title, txt(REPORT_STYLE$size_caption)),
    fp_p = pp(before = before, after = if (nzchar(b$settings)) 0 else 6)
  )
  if (nzchar(b$settings)) {
    doc <- add_par(doc,
      officer$ftext(
        b$settings, txt(REPORT_STYLE$size_caption - 1, REPORT_STYLE$dim, italic = TRUE)
      ),
      fp_p = pp(after = 6)
    )
  }
  doc
}

style_table <- function(df) {
  s <- REPORT_STYLE
  ft <- flextable$flextable(df)
  ft <- flextable$font(ft, fontname = s$font, part = "all")
  ft <- flextable$fontsize(ft, size = s$size_table, part = "all")
  ft <- flextable$color(ft, color = s$ink, part = "body")
  ft <- flextable$bg(ft, bg = s$head_fill, part = "header")
  ft <- flextable$color(ft, color = s$head_ink, part = "header")
  ft <- flextable$bold(ft, part = "header")
  if (nrow(df) > 1) {
    ft <- flextable$bg(ft, i = seq(2, nrow(df), by = 2), bg = s$stripe, part = "body")
  }
  ft <- flextable$border_remove(ft)
  ft <- flextable$hline_bottom(ft, border = officer$fp_border(color = s$rule), part = "body")
  ft <- flextable$padding(ft, padding.top = 2, padding.bottom = 2, part = "all")
  # the first column holds labels; the rest are numbers or dates
  ft <- flextable$align(ft, j = 1, align = "left", part = "all")
  if (ncol(df) > 1) ft <- flextable$align(ft, j = 2:ncol(df), align = "right", part = "all")
  ft <- flextable$autofit(ft)
  full <- s$page_width - 2 * s$margin
  if (sum(flextable$dim_pretty(ft)$widths) > full) ft <- flextable$fit_to_width(ft, full)
  ft
}

add_block <- function(doc, b) {
  s <- REPORT_STYLE
  switch(b$type,
    title_page = {
      center <- function(before = 0, after = 6) pp(before = before, after = after, align = "center")
      doc <- add_par(doc, officer$ftext(b$title, txt(s$size_cover, s$accent, bold = TRUE)),
                     fp_p = center(before = 48, after = 18))
      img <- read_image(b$image)
      if (is.null(img)) {
        # placeholder where the Points2Pano image goes when it can't be fetched
        doc <- add_par(doc,
                       officer$ftext("Points2Pano image not available", txt(s$size_body, s$dim)),
                       fp_p = officer$fp_par(text.align = "center", padding.top = 70,
                                             padding.bottom = 70, shading.color = s$stripe))
      } else {
        doc <- add_par(doc, officer$external_img(b$image, width = s$fig_width,
                                                 height = s$fig_width * image_ratio(img)),
                       fp_p = center(after = 0))
      }
      if (!is.null(b$subtitle)) {
        doc <- add_par(doc, officer$ftext(b$subtitle, txt(s$size_subtitle + 2, s$dim)),
                       fp_p = center(before = 18, after = 24))
      }
      for (l in b$lines) {
        doc <- add_par(doc, officer$ftext(l, txt(s$size_body + 1, s$dim)), fp_p = center(after = 2))
      }
      doc
    },
    page_break = officer$body_add_break(doc),
    cover_caption = add_par(doc, officer$ftext(b$text, txt(s$size_body, bold = TRUE)),
                            fp_p = pp(after = 10)),
    # blank ruled lines for handwritten notes
    ruled_lines = {
      for (i in seq_len(b$n)) {
        doc <- add_par(doc, officer$ftext(" ", txt(s$size_body)),
                       fp_p = pp(before = 12, rule = TRUE))
      }
      add_par(doc, officer$ftext(" ", txt(4)), fp_p = pp(after = 10))
    },
    toc = add_toc(doc, b),
    heading = {
      size <- switch(b$level, s$size_h1, s$size_h2, s$size_h3)
      # front-matter headings use Normal so Word's table of contents skips them
      add_par(doc, officer$ftext(b$text, txt(size, if (b$level == 3) s$ink else s$accent,
                                             bold = TRUE)),
              fp_p = pp(before = switch(b$level, 14, 10, 6), after = 4),
              style = if (isFALSE(b$toc)) "Normal" else paste("heading", b$level))
    },
    paragraph = {
      size <- if (identical(b$size, "small")) s$size_caption else s$size_body
      add_par(doc, officer$ftext(b$text, txt(size, italic = identical(b$face, "italic"))))
    },
    bullet = {
      color <- if (identical(b$tone, "caution")) s$caution else s$ink
      add_par(doc, officer$ftext(paste0("\u2022  ", b$text), txt(s$size_body - 0.5, color)),
              fp_p = pp(after = 3, indent = 12))
    },
    warning = add_par(doc, officer$ftext(b$text, txt(s$size_body, s$warn, bold = TRUE)),
                      fp_p = pp(before = 6, after = 8)),
    # red pointer under a figure or table with sample size or design notes
    flag = add_par(doc, officer$ftext(b$text, txt(s$size_caption, s$warn, bold = TRUE)),
                   fp_p = pp(after = 6)),
    # figure or table named in the Sample size and design section
    label = add_par(doc, officer$ftext(b$text, txt(s$size_body, bold = TRUE)),
                    fp_p = pp(before = 6, after = 2)),
    figure = {
      doc <- officer$body_add_gg(doc, value = b$plot, width = s$fig_width, height = s$fig_height,
                                 res = 200, style = "centered")
      add_caption(doc, b, before = 2)
    },
    # a picture file (Forestry chart, Points2Pano photo, plot map) and its caption
    image = {
      img <- read_image(b$path)
      if (is.null(img)) {
        doc <- add_par(doc, officer$ftext("Image not available", txt(s$size_body, s$dim)),
                       fp_p = officer$fp_par(text.align = "center", padding.top = 40,
                                             padding.bottom = 40, shading.color = s$stripe))
      } else {
        size <- image_size(img)
        doc <- add_par(doc, officer$external_img(b$path, width = size$w, height = size$h),
                       fp_p = pp(after = 0, align = "center"))
      }
      add_caption(doc, b, before = 2)
    },
    table = {
      doc <- add_caption(doc, b, before = 6)
      doc <- flextable$body_add_flextable(doc, style_table(b$data), align = "left")
      if (!is.null(b$note) && nzchar(b$note)) {
        doc <- add_par(doc, officer$ftext(b$note, txt(s$size_caption - 1, s$dim)),
                       fp_p = pp(before = 2, after = 8))
      }
      doc
    },
    doc
  )
}

# Page size of a picture: full figure width, shrunk so it is no taller than
# MAX_IMAGE_H inches.
image_size <- function(img) {
  w <- REPORT_STYLE$fig_width
  h <- w * image_ratio(img)
  if (h > MAX_IMAGE_H) {
    w <- w * MAX_IMAGE_H / h
    h <- MAX_IMAGE_H
  }
  list(w = w, h = h)
}

MAX_IMAGE_H <- 4.5

#' Write report blocks to a .docx file.
#' @param blocks Output of `report_blocks()`.
#' @param path File to write.
#' @return `path`, invisibly.
#' @export
render_docx <- function(blocks, path, date = Sys.Date()) {
  s <- REPORT_STYLE
  doc <- officer$read_docx()
  doc <- officer$docx_set_paragraph_style(
    doc, style_id = "Normal", style_name = "Normal",
    fp_p = pp(), fp_t = txt(s$size_body)
  )
  for (b in blocks) doc <- add_block(doc, b)

  footer <- officer$block_list(officer$fpar(
    officer$ftext(paste0(footer_text(date), "  \u00b7  Page "), txt(s$size_footer, s$dim)),
    officer$run_word_field("PAGE", prop = txt(s$size_footer, s$dim)),
    fp_p = pp(after = 0, align = "right")
  ))
  doc <- officer$body_set_default_section(doc, officer$prop_section(
    page_size = officer$page_size(
      width = s$page_width, height = s$page_height, orient = "portrait"
    ),
    page_margins = officer$page_mar(
      top = s$margin, bottom = s$margin, left = s$margin, right = s$margin,
      header = 0.5, footer = 0.5, gutter = 0
    ),
    footer_default = footer
  ))
  print(doc, target = path)
  dot_leaders(path)
  invisible(path)
}

# Give right tab stops a dotted leader, for the table of contents (the only
# paragraphs with one). officer always writes w:leader="none", so the leader
# is changed in word/document.xml directly.
dot_leaders <- function(path) {
  dir <- tempfile("docx_")
  unzip(path, exdir = dir)
  document <- file.path(dir, "word", "document.xml")
  xml <- paste(readLines(document, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  xml <- gsub('w:val="right" w:leader="none"', 'w:val="right" w:leader="dot"', xml, fixed = TRUE)
  writeLines(xml, document, useBytes = TRUE)
  file.remove(path)
  zip(path, files = list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE), root = dir)
  unlink(dir, recursive = TRUE)
}
