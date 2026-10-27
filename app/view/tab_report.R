# ---------------------------------------------------------------------------
# Report builder tab: the last step of the workflow. Holds the report as one
# ordered list (session$userData$report_items):
#   * figures and tables added with the "+ Report data" buttons on cards, each
#     with an automated description (app/logic/report_analysis.R) and an
#     optional comment;
#   * text blocks - a heading and/or text written here (a new report starts
#     with optional Introduction, Data description, Results and Management
#     relevance blocks);
#   * the standard sections ("Scans, plots and treatments", "Sample size and
#     design"), built from the loaded scans when the report is built.
# Every entry can be moved up or down or removed, so text blocks and sections
# can sit anywhere between the data. Clicking an entry selects it; new text
# blocks and sections go right after the selected entry. The sidebar collects the report details.
#
# The build runs in a separate R process (mirai) so a report with many figures
# doesn't block the session; the writers are app/logic/report_docx.R and
# app/logic/report_pdf.R, both laid out from app/logic/report.R's blocks.
# ---------------------------------------------------------------------------

box::use(
  bslib,
  mirai[mirai],
  shiny,
)

box::use(
  app/logic/report,
  app/logic/report_analysis[design_checks, scan_context],
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$nav_panel(
    title = "Report builder",
    bslib$layout_sidebar(
      fillable = FALSE,
      sidebar = bslib$sidebar(
        width = 340,
        shiny$h5("Report details"),
        shiny$textInput(ns("title"), "Title", placeholder = "IntELiMon monitoring report"),
        shiny$textInput(ns("subtitle"), "Subtitle", placeholder = "Unit, project or treatment"),
        shiny$textInput(ns("author"), "Prepared by"),
        shiny$textInput(ns("organization"), "Organization"),
        shiny$dateInput(ns("date"), "Date of preparation", value = Sys.Date(),
                        format = "yyyy-mm-dd"),
        shiny$textAreaInput(ns("summary"), "Summary", rows = 5, resize = "vertical",
          placeholder = paste(
            "Purpose, key findings and recommendations.",
            "Blank lines start new paragraphs."
          )
        ),
        shiny$radioButtons(ns("format"), "Format", inline = TRUE,
          choices = list("Word (.docx)" = "docx", "PDF" = "pdf"), selected = "docx"
        ),
        shiny$actionButton(ns("build"), "Build report", class = "btn-primary", width = "100%"),
        shiny$uiOutput(ns("build_status"))
      ),
      bslib$card(
        bslib$card_header(
          class = "d-flex justify-content-between align-items-center flex-wrap gap-2",
          shiny$span("Report contents"),
          shiny$div(
            class = "d-flex align-items-center gap-2 flex-wrap",
            shiny$actionButton(ns("add_note"), "+ Text block", class = "btn-sm imn-report-btn"),
            shiny$uiOutput(ns("section_buttons"), inline = TRUE),
            shiny$actionLink(ns("reset"), "Start over", class = "imn-report-clear")
          )
        ),
        bslib$card_body(
          shiny$div(
            class = "imn-report-hint",
            "Add figures and tables with the ", shiny$tags$b("+ Report data"), " button on ",
            "each graph card: it adds what the card is showing (the graph, or the summary ",
            "table in Statistics view) with its settings and an automated description. ",
            "Click an entry to select it: new text blocks and sections go right after it. ",
            "Use the arrows to move entries anywhere in the report."
          ),
          shiny$uiOutput(ns("items"))
        )
      )
    )
  )
}

# Up / down / remove buttons. They report through one input (`item_action`)
# rather than one observer per button.
action_buttons <- function(ns, id, n, n_items) {
  action <- function(op, label, title, disabled = FALSE) {
    shiny$tags$button(
      type = "button", class = "btn btn-sm imn-report-btn", title = title,
      disabled = if (disabled) NA,
      onclick = sprintf(
        "Shiny.setInputValue('%s', {id: '%s', op: '%s'}, {priority: 'event'})",
        ns("item_action"), id, op
      ),
      label
    )
  }
  shiny$div(
    class = "imn-report-actions",
    action("up", "\u2191", "Move up", disabled = n == 1),
    action("down", "\u2193", "Move down", disabled = n == n_items),
    action("remove", "\u2715", "Remove from report")
  )
}

# One entry in the contents list: number, badge, title and move / remove
# buttons on top; the detail line (settings, or a section's preview) and any
# inputs below at full width. Clicking it selects it (highlighted at once in
# the browser, and reported through `select_item`).
row_frame <- function(ns, item, n, n_items, badge, title, detail, ..., selected = FALSE) {
  shiny$div(
    class = paste0("imn-report-item is-", item$kind, if (selected) " is-selected"),
    onclick = sprintf(
      paste(
        "document.querySelectorAll('.imn-report-item.is-selected')",
        ".forEach(function(e) { e.classList.remove('is-selected'); });",
        "this.classList.add('is-selected');",
        "Shiny.setInputValue('%s', '%s', {priority: 'event'})"
      ),
      ns("select_item"), item$id
    ),
    shiny$div(
      class = "imn-report-head",
      shiny$span(class = "imn-report-num", n),
      shiny$span(class = paste0("imn-report-kind is-", item$kind), badge),
      shiny$div(class = "imn-report-title", title),
      thumbnail(item),
      action_buttons(ns, item$id, n, n_items)
    ),
    if (!is.null(detail)) shiny$div(class = "imn-report-settings", detail),
    ...
  )
}

# Small preview beside an item, left of its buttons: the picture for figures
# and photos, the first rows of a table.
thumbnail <- function(item) {
  if (!is.null(item$thumb)) {
    return(shiny$tags$img(class = "imn-report-thumb", src = item$thumb, alt = "", loading = "lazy"))
  }
  tbl <- item$table
  if (identical(item$kind, "table") && !is.null(tbl) && nrow(tbl) > 0) {
    tbl <- tbl[seq_len(min(4, nrow(tbl))), seq_len(min(4, ncol(tbl))), drop = FALSE]
    return(shiny$tags$table(
      class = "imn-report-thumb imn-report-minitable",
      shiny$tags$thead(shiny$tags$tr(lapply(names(tbl), shiny$tags$th))),
      shiny$tags$tbody(lapply(seq_len(nrow(tbl)), function(i) {
        shiny$tags$tr(lapply(tbl[i, ], function(v) shiny$tags$td(as.character(v))))
      }))
    ))
  }
  NULL
}

# Heading of a note: pick a preset from the dropdown or type any other text.
note_heading_input <- function(id, value) {
  choices <- unique(c("", report$NOTE_HEADINGS, if (nzchar(value)) value))
  shiny$selectizeInput(
    id, label = NULL, choices = choices, selected = value, width = "100%",
    options = list(create = TRUE, persist = FALSE, placeholder = "Heading (pick or type)")
  )
}

# Preview of the automated description stored with a figure or table.
analysis_preview <- function(ns, item, include) {
  a <- item$analysis
  if (is.null(a)) return(NULL)
  shiny$tags$details(
    class = "imn-report-auto",
    shiny$tags$summary("Automated description"),
    shiny$checkboxInput(ns(paste0("auto_", item$id)), "Include in the report", value = include),
    shiny$p(a$summary),
    if (!is.null(a$implication)) shiny$p(shiny$tags$em(a$implication)),
    if (length(a$cautions) > 0) {
      shiny$tagList(
        shiny$div(class = "imn-report-auto-head", "Listed under Sample size and design:"),
        shiny$tags$ul(class = "imn-report-cautions", lapply(a$cautions, shiny$tags$li))
      )
    }
  )
}

# Red pointer shown (and printed) under items with sample size or design notes.
design_flag <- function(item) {
  if (is.null(item$analysis) || length(item$analysis$cautions) == 0) return(NULL)
  shiny$div(class = "imn-report-flag", report$DESIGN_POINTER)
}

# One row per selected plot (site, plot, lon, lat) for the Plot locations map.
plot_points <- function(scans) {
  if (is.null(scans) || nrow(scans) == 0) return(NULL)
  pts <- unique(data.frame(
    site = as.character(scans$site), plot = as.character(scans$plot),
    lon = as.numeric(scans$Longitude), lat = as.numeric(scans$Latitude)
  ))
  pts[!duplicated(pts[c("site", "plot")]), , drop = FALSE]
}

# The cover photo is the Points2Pano image of the first selected scan (the one
# the Points2Pano card opens on): its agency, site, plot and date, plus the
# caption printed on the page after the title page. NULL with no scans.
cover_scan <- function(scans) {
  if (is.null(scans) || nrow(scans) == 0) return(NULL)
  row <- scans[1, ]
  agency <- if ("Agency" %in% names(scans)) as.character(row$Agency) else NA_character_
  list(
    site = as.character(row$site), plot = as.character(row$plot), date = as.Date(row$date),
    scanner = if ("scanner_id" %in% names(scans)) row$scanner_id else 1,
    caption = report$cover_caption(agency, row$site, row$plot, row$date)
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {
    items <- session$userData$report_items
    # id of the selected entry: new text blocks and sections go after it
    selected <- shiny$reactiveVal(NULL)

    # Values typed into the rows live in inputs; `typed()` reads one back,
    # falling back to the value stored on the item.
    typed <- function(prefix, item, field) {
      v <- input[[paste0(prefix, item$id)]]
      if (is.null(v)) item[[field]] else v
    }
    with_inputs <- function(item) {
      if (item$kind == "note") {
        item$heading <- typed("head_", item, "heading")
        item$text <- typed("text_", item, "text")
      } else if (item$kind %in% c("figure", "table", "image")) {
        # every card entry has a comment box, Points2Pano images included
        item$comment <- typed("comment_", item, "comment")
        item$include_analysis <- typed("auto_", item, "include_analysis")
      }
      item
    }

    context <- shiny$reactive({
      metrics <- session$userData$metrics()
      scans <- session$userData$scan_selection()
      treatments <- session$userData$trtmt_dates()
      treat <- treatments$TreatmentDate
      list(
        scan = scan_context(metrics, scans, treat, treatments$TreatmentType),
        checks = design_checks(metrics, scans, treat),
        points = plot_points(scans)
      )
    })

    section_detail <- function(key, its) {
      ctx <- context()
      if (is.null(ctx$scan)) return("No scans are loaded yet.")
      if (key == "context") return(paste(c(ctx$scan$text, ctx$scan$treatments), collapse = " "))
      if (key == "map") {
        n <- if (is.null(ctx$points)) 0 else nrow(ctx$points)
        return(sprintf(
          "%d plot%s drawn on satellite imagery (Esri World Imagery), zoomed to their extent.",
          n, if (n == 1) "" else "s"
        ))
      }
      n <- length(ctx$checks)
      flagged <- sum(vapply(its, function(it) length(it$analysis$cautions) > 0, logical(1)))
      if (n == 0 && flagged == 0) {
        return("No sample size or design issues detected.")
      }
      paste0(
        sprintf("%d point%s across all loaded scans", n, if (n == 1) "" else "s"),
        if (flagged > 0) {
          sprintf(", plus notes for %d figure%s or table%s", flagged,
                  if (flagged == 1) "" else "s", if (flagged == 1) "" else "s")
        },
        if (n > 0) paste(". First:", ctx$checks[[1]]) else "."
      )
    }

    output$items <- shiny$renderUI({
      its <- items()
      if (length(its) == 0) {
        return(shiny$div(class = "imn-report-empty",
                         "The report is empty. Add a text block or a section."))
      }
      n_items <- length(its)
      ns <- session$ns
      sel <- shiny$isolate(selected())
      # typed values are fed back in so they survive reordering and removal
      shiny$tagList(lapply(seq_along(its), function(i) {
        it <- shiny$isolate(with_inputs(its[[i]]))
        is_sel <- identical(it$id, sel)
        switch(it$kind,
          section = row_frame(ns, it, i, n_items, "Section", it$title, section_detail(it$key, its),
                              selected = is_sel),
          note = row_frame(
            ns, it, i, n_items, "Text", "Text block", NULL,
            note_heading_input(ns(paste0("head_", it$id)), it$heading),
            shiny$textAreaInput(
              ns(paste0("text_", it$id)), label = NULL, value = it$text, rows = 3,
              width = "100%", resize = "vertical",
              placeholder = if (isTRUE(it$optional)) {
                "Optional"
              } else {
                "Text. Blank lines start new paragraphs."
              }
            ),
            selected = is_sel
          ),
          row_frame(
            ns, it, i, n_items, if (it$kind == "table") "Table" else "Figure", it$title,
            report$settings_line(c(list(Source = it$source), it$settings)),
            design_flag(it),
            analysis_preview(ns, it, isTRUE(it$include_analysis)),
            shiny$textAreaInput(
              ns(paste0("comment_", it$id)), label = NULL, value = it$comment, rows = 2,
              width = "100%", resize = "vertical",
              placeholder = "Comment printed below this item in the report (optional)"
            ),
            selected = is_sel
          )
        )
      }))
    })

    output$section_buttons <- shiny$renderUI({
      keys <- report$missing_sections(items())
      shiny$tagList(lapply(keys, function(k) {
        shiny$tags$button(
          type = "button", class = "btn btn-sm imn-report-btn",
          onclick = sprintf(
            "Shiny.setInputValue('%s', '%s', {priority: 'event'})", session$ns("add_section"), k
          ),
          paste("+", report$SECTIONS[[k]])
        )
      }))
    })

    # Edits are saved onto the items before the list changes shape.
    update_items <- function(f) items(f(lapply(items(), with_inputs)))

    shiny$observeEvent(input$item_action, {
      a <- input$item_action
      update_items(function(its) {
        switch(a$op,
          up = report$move_item(its, a$id, "up"),
          down = report$move_item(its, a$id, "down"),
          remove = report$remove_item(its, a$id),
          its
        )
      })
    })
    shiny$observeEvent(input$select_item, selected(input$select_item))
    # a new entry goes after the selected one (at the end with none) and is
    # selected in turn, so several added in a row keep their order
    add_item <- function(new) {
      update_items(function(its) report$insert_after(its, new, selected()))
      selected(new$id)
    }
    shiny$observeEvent(input$add_note, add_item(report$note_item()))
    shiny$observeEvent(input$add_section, add_item(report$section_item(input$add_section)))

    shiny$observeEvent(input$reset, {
      shiny$showModal(shiny$modalDialog(
        title = "Start the report over?",
        paste(
          "This removes every figure, table and text block from the report and restores the",
          "standard sections and text blocks. The cards are not affected."
        ),
        footer = shiny$tagList(
          shiny$modalButton("Cancel"),
          shiny$actionButton(session$ns("reset_confirm"), "Start over", class = "btn-danger")
        ),
        easyClose = TRUE
      ))
    })
    shiny$observeEvent(input$reset_confirm, {
      selected(NULL)
      items(report$default_report_items())
      shiny$removeModal()
    })

    # ---- Build ------------------------------------------------------------
    built_name <- shiny$reactiveVal(NULL)

    build_task <- shiny$ExtendedTask$new(function(blocks, format, path, date, cover) {
      mirai(
        {
          # the worker starts without the project's .Rprofile, so point it at
          # the app's (renv) library, working directory and box path
          .libPaths(lib_paths)
          setwd(project_dir)
          options(box.path = project_dir)
          loadNamespace("ggplot2") # the figures are ggplot objects
          box::use(
            app/logic/report_cover[prepare_images],
            app/logic/report_docx[render_docx],
            app/logic/report_pdf[render_pdf],
          )
          # pictures are downloaded and drawn here so a slow server can't block the app
          blocks <- prepare_images(blocks, cover)
          if (format == "docx") render_docx(blocks, path, date) else render_pdf(blocks, path, date)
          path
        },
        lib_paths = .libPaths(), project_dir = getwd(),
        blocks = blocks, format = format, path = path, date = date, cover = cover
      )
    })

    shiny$observeEvent(input$build, {
      if (build_task$status() == "running") {
        shiny$showNotification("A report is already being built.", type = "warning")
        return()
      }
      date <- if (length(input$date) == 1 && !is.na(input$date)) input$date else Sys.Date()
      cover <- cover_scan(session$userData$scan_selection())
      blocks <- report$report_blocks(
        lapply(items(), with_inputs),
        meta = list(
          title = input$title, subtitle = input$subtitle, author = input$author,
          organization = input$organization, date = format(date, report$REPORT_DATE),
          summary = input$summary
        ),
        context = context(),
        cover = cover
      )
      # named from the title and date as they were when the report was built
      built_name(report$report_filename(input$title, input$format, date))
      build_task$invoke(blocks, input$format, tempfile(fileext = paste0(".", input$format)), date,
                        cover)
    })

    output$build_status <- shiny$renderUI({
      status <- build_task$status()
      if (status == "initial") {
        return(NULL)
      }
      if (status == "running") {
        return(shiny$div(class = "imn-report-status", "Building the report\u2026"))
      }
      if (status == "error") {
        msg <- tryCatch(build_task$result(), error = conditionMessage)
        return(shiny$div(class = "imn-report-status imn-sim-warn",
                         shiny$tags$b("The report could not be built. "), msg))
      }
      shiny$div(
        class = "imn-report-status",
        shiny$downloadButton(session$ns("download"), "Download report", class = "btn-secondary",
                             style = "width:100%")
      )
    })

    output$download <- shiny$downloadHandler(
      filename = function() built_name(),
      content = function(file) file.copy(build_task$result(), file, overwrite = TRUE)
    )
  })
}
