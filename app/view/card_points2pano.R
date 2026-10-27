box::use(
  bslib,
  shiny,
)

box::use(
  app/logic/load_data_api[build_points2pano_url_sdsc],
  app/logic/report[report_item],
  app/logic/report_cover[p2p_tile_url],
  app/view/report_store[add_to_report],
)

#' @export
ui <- function(id) {
  ns <- shiny$NS(id)

  bslib$card(
    area = "panoViewer",
    full_screen = TRUE,
    bslib$card_header(
      class = "d-flex justify-content-between align-items-center",
      shiny$span("Points2Pano"),
      shiny$div(
                class = "d-flex align-items-center gap-2",
                shiny$actionButton(ns("btn_pano_prev"), "\u25C0", class = "btn-sm"),
                shiny$div(
                  class = "pano-info",
                  shiny$textOutput(ns("pano_label"), inline = TRUE)
                ),
                shiny$actionButton(ns("btn_pano_next"), "\u25B6", class = "btn-sm"))
    ),
    bslib$card_body(
      padding = 0,
      style = "position: relative;",
      shiny$uiOutput(ns("pano_frame"), style = "height: 100%;"),
      # adds a photo of the plot showing to the report; over the lower right of
      # the scan, opposite the card's expand button, so a narrow header can't
      # push it off the card
      shiny$div(
        class = "imn-pano-add",
        shiny$actionButton(ns("add_report"), "+ Report data",
                           class = "btn-sm imn-add-report imn-card-add",
                           title = "Add report data: a photo of the plot showing")
      )
    )
  )
}

# One scan as "site|plot|YYYY-MM-DD|scanner", whatever type its date has
# (Date, "2025-01-24" or "20250124"), for matching scans between tabs.
#' @export
scan_id <- function(site, plot, date, scanner_id) {
  d <- if (inherits(date, "Date")) {
    date
  } else {
    as.Date(as.character(date), tryFormats = c("%Y-%m-%d", "%Y%m%d"), optional = TRUE)
  }
  paste(site, plot, format(d, "%Y-%m-%d"), scanner_id, sep = "|")
}

#' @param follow - optional reactive returning one scan (site, plot, date, scanner_id). When
#'        it changes, the viewer moves to that scan.
#' @return a list with `current`: a reactive of the scan showing (one row), or NULL.
#' @export
server <- function(id, session, follow = NULL) {
  shiny$moduleServer(id, function(input, output, session) {
    pano_idx <- shiny$reactiveVal(1)

    # Populated scans available to the viewer (in scan_calls order)
    pano_scans <- shiny$reactive({
      sc <- session$userData$scan_selection()
      if (is.null(sc) || !"date" %in% names(sc)) return(sc[0])
      sc[nzchar(sc$date)]
    })


    # Reset to the first record whenever scan_calls changes
    shiny$observeEvent(session$userData$scan_selection(), {
      pano_idx(1)
    })

    # move to the scan another module is showing (e.g. the Forestry scan)
    if (!is.null(follow)) {
      shiny$observeEvent(list(follow(), pano_scans()), {
        f <- follow()
        df <- pano_scans()
        if (is.null(f) || nrow(df) == 0) return()
        at <- match(scan_id(f$site, f$plot, f$date, f$scanner_id),
                    scan_id(df$site, df$plot, df$date, df$scanner_id))
        if (!is.na(at) && at != pano_idx()) pano_idx(at)
      })
    }

    shiny$observeEvent(input$btn_pano_prev, {
      n <- nrow(pano_scans())
      if (n == 0) {
        return()
      }
      pano_idx(if (pano_idx() <= 1) n else pano_idx() - 1) # wrap
    })

    shiny$observeEvent(input$btn_pano_next, {
      n <- nrow(pano_scans())
      if (n == 0) {
        return()
      }
      pano_idx(if (pano_idx() >= n) 1 else pano_idx() + 1) # wrap
    })

    output$pano_label <- shiny$renderText({
      df <- pano_scans()
      if (nrow(df) == 0) {
        return("No scans loaded")
      }

      row <- df[min(pano_idx(), nrow(df))]
      date_fmt <- row$date

      sprintf(
        "Site: %s | Plot: %s | %s | Scanner: %s",
        row$site, row$plot, date_fmt, row$scanner_id
      )
    })

    shiny$observeEvent(input$add_report, {
      df <- pano_scans()
      if (nrow(df) == 0) {
        shiny$showNotification("No plot is showing to add.", type = "warning")
        return()
      }
      row <- df[min(pano_idx(), nrow(df))]
      title <- sprintf("Points2Pano view of %s plot %s, %s", row$site, row$plot, format(row$date))
      photo <- list(site = row$site, plot = row$plot, date = row$date, scanner = row$scanner_id)
      add_to_report(session, report_item(
        "image", title, "Points2Pano",
        settings = list(View = "Front of the scanner, 90\u00b0 field of view"),
        photo = photo, group = "Points2Pano photos",
        thumb = p2p_tile_url(row$site, row$plot, row$date, row$scanner_id)
      ))
    })

    output$pano_frame <- shiny$renderUI({
      df <- pano_scans()

      if (nrow(df) == 0) {
        return(shiny$div(
          style = "display:flex; align-items:center; justify-content:center;
                   height:100%; color:#888; text-align:center; padding:20px;",
          "No scans loaded - select plots on the Selection Map tab and press Get Data."
        ))
      }

      idx <- min(pano_idx(), nrow(df))
      row <- df[idx]

      pano_url <- build_points2pano_url_sdsc(row$site, row$plot, row$date)

      # the URL hides the page's site list and map (see
      # build_points2pano_url_sdsc()); the page's header and bottom button bar
      # are cropped out by .imn-pano-crop / .imn-pano-frame in main.scss
      shiny$div(
        class = "imn-pano-crop",
        shiny$tags$iframe(
          class = "imn-pano-frame",
          src = pano_url,
          title = paste("Points2Pano:", row$scan_name)
        )
      )
    })

    list(current = shiny$reactive({
      df <- pano_scans()
      if (nrow(df) == 0) NULL else df[min(pano_idx(), nrow(df))]
    }))
  })
}
