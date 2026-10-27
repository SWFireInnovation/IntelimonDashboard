# ---------------------------------------------------------------------------
# PDF writer for the report builder. Lays out the blocks from report_blocks()
# (app/logic/report.R) page by page with grid on R's own Cairo PDF device,
# styled from REPORT_STYLE so it matches the Word writer. Pure R: no LaTeX,
# pandoc or browser, so it runs the same on the server and in the desktop build.
#
# Layout keeps a cursor (inches down from the top of the page). Each block
# measures itself, starts a new page when it doesn't fit, and draws; long
# paragraphs break between lines and long tables between rows, repeating the
# header row.
# ---------------------------------------------------------------------------

box::use(
  grDevices[cairo_pdf, dev.off],
  grid,
)

box::use(
  app/logic/report[REPORT_STYLE, footer_text],
  app/logic/report_cover[image_ratio, read_image],
)
LINE_GAP <- 1.3 # line height as a multiple of the font size

gp <- function(size, color = REPORT_STYLE$ink, face = "plain") {
  grid$gpar(fontfamily = "sans", fontsize = size, col = color, fontface = face)
}

pts <- function(size) size / 72 * LINE_GAP # one line of text, in inches

# Arial has no subscript digits (e.g. the I\u2080 in "crown-initiation
# intensity"), so they are drawn as plain digits.
pdf_text <- function(x) chartr(intToUtf8(0x2080:0x2089), "0123456789", x)

# Width in inches of each string. Measured one at a time: grobWidth() of a
# multi-label textGrob reports the first label only, not the widest.
text_width <- function(x, g) {
  vapply(x, function(s) {
    grid$convertWidth(grid$grobWidth(grid$textGrob(s, gp = g)), "in", valueOnly = TRUE)
  }, numeric(1), USE.NAMES = FALSE)
}

#' Greedy word wrap to a width in inches, measured with the real font.
#' Newlines in `x` start new lines.
wrap_text <- function(x, g, width) {
  x <- pdf_text(x)
  out <- character()
  for (para in strsplit(x, "\n", fixed = TRUE)[[1]]) {
    words <- strsplit(para, "[[:space:]]+")[[1]]
    words <- words[nzchar(words)]
    line <- ""
    for (w in words) {
      candidate <- if (nzchar(line)) paste(line, w) else w
      if (nzchar(line) && text_width(candidate, g) > width) {
        out <- c(out, line)
        line <- w
      } else {
        line <- candidate
      }
    }
    out <- c(out, line)
  }
  out
}

new_layout <- function(date) {
  s <- REPORT_STYLE
  env <- new.env()
  env$page <- 0L
  env$y <- 0
  env$left <- s$margin
  env$width <- s$page_width - 2 * s$margin
  env$bottom <- s$page_height - s$margin
  env$footer <- footer_text(date)
  env
}

new_page <- function(lay, footer = TRUE) {
  s <- REPORT_STYLE
  grid$grid.newpage()
  lay$page <- lay$page + 1L
  lay$y <- s$margin
  if (footer) grid$grid.text(
    paste0(lay$footer, "  \u00b7  Page ", lay$page),
    x = grid$unit(s$page_width - s$margin, "in"), y = grid$unit(s$margin / 2, "in"),
    just = c("right", "center"), gp = gp(s$size_footer, s$dim)
  )
}

ensure <- function(lay, height) {
  if (lay$page == 0L || lay$y + height > lay$bottom) new_page(lay)
}

# Draw one line of text with its top at the cursor and advance.
draw_line <- function(lay, label, g, size, x_offset = 0, align = "left") {
  x <- if (align == "center") lay$left + lay$width / 2 else lay$left + x_offset
  grid$grid.text(
    label,
    x = grid$unit(x, "in"),
    y = grid$unit(REPORT_STYLE$page_height - lay$y - pts(size) * 0.8, "in"),
    just = c(align, "bottom"), gp = g
  )
  lay$y <- lay$y + pts(size)
}

# Wrapped text with its top at the cursor. `bullet` hangs a bullet in the
# left margin of the first line and indents the text.
draw_text <- function(lay, x, size, color = REPORT_STYLE$ink, face = "plain",
                      before = 0, after = 6 / 72, bullet = FALSE, align = "left") {
  g <- gp(size, color, face)
  indent <- if (bullet) 0.2 else 0
  lines <- wrap_text(x, g, lay$width - indent)
  lay$y <- lay$y + before
  # keep at least two lines together at a page break
  ensure(lay, pts(size) * min(2, length(lines)))
  for (i in seq_along(lines)) {
    ensure(lay, pts(size))
    if (bullet && i == 1) {
      grid$grid.text(
        "\u2022", x = grid$unit(lay$left + 0.06, "in"),
        y = grid$unit(REPORT_STYLE$page_height - lay$y - pts(size) * 0.8, "in"),
        just = c("left", "bottom"), gp = g
      )
    }
    draw_line(lay, lines[i], g, size, x_offset = indent, align = align)
  }
  lay$y <- lay$y + after
}

draw_rule <- function(lay, after = 0.15) {
  y <- REPORT_STYLE$page_height - lay$y
  grid$grid.lines(
    x = grid$unit(c(lay$left, lay$left + lay$width), "in"), y = grid$unit(c(y, y), "in"),
    gp = grid$gpar(col = REPORT_STYLE$rule, lwd = 0.8)
  )
  lay$y <- lay$y + after
}

draw_caption <- function(lay, b) {
  s <- REPORT_STYLE
  draw_text(lay, paste(b$label, b$title), s$size_caption, face = "bold",
            after = if (nzchar(b$settings)) 0 else 6 / 72)
  if (nzchar(b$settings)) {
    draw_text(lay, b$settings, s$size_caption - 1, s$dim, face = "italic")
  }
}

# Title page: title, cover image (or a placeholder when it couldn't be
# fetched), subtitle and the author / organization / date lines, centered.
# No page footer on this page.
draw_title_page <- function(lay, b) {
  s <- REPORT_STYLE
  new_page(lay, footer = FALSE)
  lay$y <- lay$y + 0.7
  draw_text(lay, b$title, s$size_cover, s$accent, "bold", after = 0.3, align = "center")
  img <- shrink_image(read_image(b$image), s$fig_width * 200)
  w <- s$fig_width
  h <- if (is.null(img)) 3.25 else w * image_ratio(img)
  if (h > 4.5) {
    w <- w * 4.5 / h
    h <- 4.5
  }
  top <- s$page_height - lay$y
  x <- lay$left + (lay$width - w) / 2
  if (is.null(img)) {
    grid$grid.rect(
      x = grid$unit(x, "in"), y = grid$unit(top, "in"), width = grid$unit(w, "in"),
      height = grid$unit(h, "in"), just = c("left", "top"),
      gp = grid$gpar(fill = s$stripe, col = s$rule)
    )
    grid$grid.text(
      "Points2Pano image not available", x = grid$unit(x + w / 2, "in"),
      y = grid$unit(top - h / 2, "in"), gp = gp(s$size_body, s$dim)
    )
  } else {
    grid$grid.raster(
      img, x = grid$unit(x, "in"), y = grid$unit(top, "in"),
      width = grid$unit(w, "in"), height = grid$unit(h, "in"), just = c("left", "top")
    )
  }
  lay$y <- lay$y + h + 0.3
  if (!is.null(b$subtitle)) {
    draw_text(lay, b$subtitle, s$size_subtitle + 2, s$dim, after = 0.3, align = "center")
  }
  for (l in b$lines) draw_text(lay, l, s$size_body + 1, s$dim, after = 2 / 72, align = "center")
}

# Keep every nth pixel so the image is at most `max_px` wide (about 200 dpi
# at full page width). The PDF device stores rasters nearly uncompressed, so a
# full-size panorama would add several megabytes.
shrink_image <- function(img, max_px) {
  if (is.null(img) || dim(img)[2] <= max_px) return(img)
  k <- ceiling(dim(img)[2] / max_px)
  img[seq(1, dim(img)[1], by = k), seq(1, dim(img)[2], by = k), , drop = FALSE]
}

# Blank ruled lines for handwritten notes.
draw_ruled_lines <- function(lay, n) {
  for (i in seq_len(n)) {
    ensure(lay, 0.4)
    lay$y <- lay$y + 0.38
    draw_rule(lay, after = 0)
  }
  lay$y <- lay$y + 0.2
}

# Table of contents: each heading with a dotted leader to its page number.
# Page numbers come from the first layout pass (lay$toc_pages); the first
# pass itself draws the same entries without numbers, so both passes take
# the same space.
draw_toc <- function(lay, b) {
  s <- REPORT_STYLE
  draw_text(lay, "Contents", s$size_h1, s$accent, "bold", after = 0.15)
  for (i in seq_along(b$entries)) {
    e <- b$entries[[i]]
    size <- if (e$level == 1) s$size_body + 1 else s$size_body
    g <- gp(size, face = if (e$level == 1) "bold" else "plain")
    indent <- (e$level - 1) * 0.3
    page <- if (length(lay$toc_pages) >= i) as.character(lay$toc_pages[i]) else ""
    ensure(lay, pts(size) + 0.06)
    lay$y <- lay$y + if (e$level == 1) 0.06 else 0
    base <- s$page_height - lay$y - pts(size) * 0.8
    label <- pdf_text(e$text)
    grid$grid.text(label, x = grid$unit(lay$left + indent, "in"), y = grid$unit(base, "in"),
                   just = c("left", "bottom"), gp = g)
    grid$grid.text(page, x = grid$unit(lay$left + lay$width, "in"), y = grid$unit(base, "in"),
                   just = c("right", "bottom"), gp = g)
    from <- lay$left + indent + text_width(label, g) + 0.08
    to <- lay$left + lay$width - text_width(if (nzchar(page)) page else "00", g) - 0.08
    if (to > from) {
      grid$grid.lines(x = grid$unit(c(from, to), "in"), y = grid$unit(c(base, base) + 0.02, "in"),
                      gp = grid$gpar(col = s$dim, lty = "dotted", lwd = 0.8))
    }
    lay$y <- lay$y + pts(size)
  }
}

draw_figure <- function(lay, b) {
  s <- REPORT_STYLE
  caption_h <- pts(s$size_caption) * 3
  ensure(lay, s$fig_height + caption_h)
  grid$pushViewport(grid$viewport(
    x = grid$unit(lay$left + (lay$width - s$fig_width) / 2, "in"),
    y = grid$unit(s$page_height - lay$y, "in"),
    width = grid$unit(s$fig_width, "in"), height = grid$unit(s$fig_height, "in"),
    just = c("left", "top")
  ))
  print(b$plot, newp = FALSE)
  grid$popViewport()
  lay$y <- lay$y + s$fig_height + 0.05
  draw_caption(lay, b)
}

MAX_IMAGE_H <- 4.5

# Size on the page of a picture: full figure width, shrunk so it is no taller
# than MAX_IMAGE_H; a placeholder box when the picture is missing.
image_box <- function(img) {
  w <- REPORT_STYLE$fig_width
  h <- if (is.null(img)) 2 else w * image_ratio(img)
  if (h > MAX_IMAGE_H) {
    w <- w * MAX_IMAGE_H / h
    h <- MAX_IMAGE_H
  }
  list(w = w, h = h)
}

image_height <- function(b) image_box(read_image(b$path))$h

# A picture file (Forestry chart, Points2Pano photo, plot map) and its caption.
draw_image <- function(lay, b) {
  s <- REPORT_STYLE
  img <- shrink_image(read_image(b$path), s$fig_width * 200)
  box <- image_box(img)
  ensure(lay, box$h + pts(s$size_caption) * 3)
  top <- s$page_height - lay$y
  x <- lay$left + (lay$width - box$w) / 2
  if (is.null(img)) {
    grid$grid.rect(x = grid$unit(x, "in"), y = grid$unit(top, "in"),
                   width = grid$unit(box$w, "in"), height = grid$unit(box$h, "in"),
                   just = c("left", "top"), gp = grid$gpar(fill = s$stripe, col = s$rule))
    grid$grid.text("Image not available", x = grid$unit(x + box$w / 2, "in"),
                   y = grid$unit(top - box$h / 2, "in"), gp = gp(s$size_body, s$dim))
  } else {
    grid$grid.raster(img, x = grid$unit(x, "in"), y = grid$unit(top, "in"),
                     width = grid$unit(box$w, "in"), height = grid$unit(box$h, "in"),
                     just = c("left", "top"))
  }
  lay$y <- lay$y + box$h + 0.05
  draw_caption(lay, b)
}

# Column widths in inches: each column's widest cell plus padding, scaled to
# the text width when the table would overflow it. Returns the widths and the
# font size (shrunk, to a floor, for very wide tables).
table_geometry <- function(df, width) {
  s <- REPORT_STYLE
  size <- s$size_table
  repeat {
    widths <- vapply(seq_along(df), function(j) {
      cells <- pdf_text(c(names(df)[j], as.character(df[[j]])))
      max(text_width(cells, gp(size, face = "bold"))) + 0.16
    }, numeric(1))
    if (sum(widths) <= width || size <= 6.5) break
    size <- size - 0.5
  }
  if (sum(widths) > width) widths <- widths * width / sum(widths)
  list(widths = widths, size = size)
}

draw_table <- function(lay, b) {
  s <- REPORT_STYLE
  df <- as.data.frame(b$data, stringsAsFactors = FALSE)
  geo <- table_geometry(df, lay$width)
  row_h <- pts(geo$size) + 0.05
  ensure(lay, pts(s$size_caption) * 3 + row_h * min(nrow(df) + 1, 4))
  draw_caption(lay, b)
  x0 <- lay$left + c(0, cumsum(geo$widths))[seq_along(df)]

  draw_row <- function(cells, fill, g, header = FALSE) {
    top <- s$page_height - lay$y
    grid$grid.rect(
      x = grid$unit(lay$left, "in"), y = grid$unit(top, "in"),
      width = grid$unit(sum(geo$widths), "in"), height = grid$unit(row_h, "in"),
      just = c("left", "top"), gp = grid$gpar(fill = fill, col = NA)
    )
    for (j in seq_along(cells)) {
      right <- j > 1
      grid$grid.text(
        pdf_text(cells[j]),
        x = grid$unit(if (right) x0[j] + geo$widths[j] - 0.08 else x0[j] + 0.08, "in"),
        y = grid$unit(top - row_h / 2, "in"),
        just = c(if (right) "right" else "left", "center"), gp = g
      )
    }
    lay$y <- lay$y + row_h
  }
  header <- function() {
    draw_row(names(df), s$head_fill, gp(geo$size, s$head_ink, "bold"), header = TRUE)
  }

  header()
  for (i in seq_len(nrow(df))) {
    if (lay$y + row_h > lay$bottom) {
      new_page(lay)
      header()
    }
    draw_row(as.character(unlist(df[i, ])), if (i %% 2 == 0) s$stripe else NA, gp(geo$size))
  }
  bottom <- s$page_height - lay$y
  grid$grid.lines(
    x = grid$unit(c(lay$left, lay$left + sum(geo$widths)), "in"),
    y = grid$unit(c(bottom, bottom), "in"), gp = grid$gpar(col = s$rule, lwd = 0.8)
  )
  lay$y <- lay$y + 0.05
  if (!is.null(b$note) && nzchar(b$note)) {
    draw_text(lay, b$note, s$size_caption - 1, s$dim, before = 0.02)
  }
  lay$y <- lay$y + 0.08
}

# Height of the first part of a block that must stay on the same page as the
# heading above it: a whole figure, a table's caption and first rows, or the
# first lines of text.
lead_height <- function(b) {
  s <- REPORT_STYLE
  if (is.null(b)) return(0)
  switch(b$type,
    figure = s$fig_height + pts(s$size_caption) * 3,
    image = image_height(b) + pts(s$size_caption) * 3,
    heading = pts(s$size_h2) + pts(s$size_body) * 3,
    table = pts(s$size_caption) * 3 + (pts(s$size_table) + 0.05) * min(nrow(b$data) + 1, 4),
    pts(s$size_body) * 3
  )
}

draw_block <- function(lay, b, next_block = NULL) {
  s <- REPORT_STYLE
  switch(b$type,
    title_page = draw_title_page(lay, b),
    # the next block starts a new page
    page_break = if (lay$page > 0L) lay$y <- Inf,
    cover_caption = draw_text(lay, b$text, s$size_body, face = "bold", after = 0.1),
    ruled_lines = draw_ruled_lines(lay, b$n),
    toc = draw_toc(lay, b),
    heading = {
      size <- switch(b$level, s$size_h1, s$size_h2, s$size_h3)
      before <- switch(b$level, 0.2, 0.14, 0.08)
      ensure(lay, before + pts(size) + 4 / 72 + lead_height(next_block))
      draw_text(lay, b$text, size, if (b$level == 3) s$ink else s$accent, "bold",
                before = before, after = 4 / 72)
      # page of each heading listed in the table of contents
      if (!isFALSE(b$toc)) lay$headings <- c(lay$headings, lay$page)
    },
    paragraph = draw_text(
      lay, b$text, if (identical(b$size, "small")) s$size_caption else s$size_body,
      face = if (identical(b$face, "italic")) "italic" else "plain"
    ),
    bullet = draw_text(
      lay, b$text, s$size_body - 0.5, if (identical(b$tone, "caution")) s$caution else s$ink,
      bullet = TRUE, after = 3 / 72
    ),
    warning = draw_text(lay, b$text, s$size_body, s$warn, "bold", before = 0.06, after = 0.12),
    # red pointer under a figure or table with sample size or design notes
    flag = draw_text(lay, b$text, s$size_caption, s$warn, "bold", after = 6 / 72),
    # figure or table named in the Sample size and design section; kept with
    # the first of its notes
    label = {
      ensure(lay, 0.08 + pts(s$size_body) * 3)
      draw_text(lay, b$text, s$size_body, face = "bold", before = 0.08, after = 2 / 72)
    },
    figure = draw_figure(lay, b),
    image = draw_image(lay, b),
    table = draw_table(lay, b)
  )
}

#' Write report blocks to a PDF file.
#' @param blocks Output of `report_blocks()`.
#' @param path File to write.
#' @return `path`, invisibly, with the number of pages in its "pages" attribute.
#' @export
render_pdf <- function(blocks, path, date = Sys.Date()) {
  # first pass: lay the report out to find each heading's page; second pass:
  # draw it for real with those page numbers in the table of contents
  first <- layout_pass(blocks, tempfile(fileext = ".pdf"), date, toc_pages = integer())
  final <- layout_pass(blocks, path, date, toc_pages = first$headings)
  invisible(structure(path, pages = final$page))
}

layout_pass <- function(blocks, path, date, toc_pages) {
  s <- REPORT_STYLE
  cairo_pdf(path, width = s$page_width, height = s$page_height, onefile = TRUE, family = "sans")
  on.exit(dev.off())
  lay <- new_layout(date)
  lay$headings <- integer()
  lay$toc_pages <- toc_pages
  for (i in seq_along(blocks)) {
    draw_block(lay, blocks[[i]], if (i < length(blocks)) blocks[[i + 1]])
  }
  if (lay$page == 0L) new_page(lay)
  lay
}
