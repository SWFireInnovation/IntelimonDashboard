# ---------------------------------------------------------------------------
# Report builder core. Pure functions, no Shiny.
#
# Cards add *items* to the session's report (a figure or a table, exactly as
# the card showed it, plus the settings behind it and an automated analysis);
# the Report builder adds notes and the standard sections, all in one ordered
# list. `report_blocks()` lays the items out as a flat list of *blocks*
# (title, heading, paragraph, bullet, warning, figure, table) with figures and
# tables numbered. The Word and PDF writers
# (app/logic/report_docx.R, app/logic/report_pdf.R) render the same blocks
# with the same REPORT_STYLE, so both formats share one template.
# ---------------------------------------------------------------------------

box::use(
  app/logic/report_analysis[plural],
)

#' Shared template for both output formats. Colours match the light export
#' palette the figures are drawn with (EXPORT_PAL in app/view/plotting.R).
#' Sizes are points; page dimensions and margins are inches (US Letter).
#' @export
REPORT_STYLE <- list(
  font          = "Arial",
  size_title    = 22,
  size_cover    = 28,
  size_subtitle = 13,
  size_h1       = 15,
  size_h2       = 12,
  size_h3       = 11,
  size_body     = 10,
  size_caption  = 9,
  size_table    = 8.5,
  size_footer   = 8,
  ink           = "#1a1a1a",
  dim           = "#495057",
  accent        = "#0b7285",
  rule          = "#ced4da",
  head_fill     = "#0b7285",
  head_ink      = "#ffffff",
  stripe        = "#eef3f5",
  warn          = "#c92a2a",
  caution       = "#8a5300",
  page_width    = 8.5,
  page_height   = 11,
  margin        = 1,
  fig_width     = 6.5,
  fig_height    = 3.9,
  product       = "IntELiMon Decision Support Tool"
)

#' Text of the rothRmel caveat, added to any report holding rothRmel output.
#' @export
ROTHRMEL_CAVEAT <- paste(
  "The fire models in the rothRmel tab should be used for change tracking and",
  "treatment success purposes only. These models have not been verified for use",
  "with custom fuel beds generated from TLS."
)

#' Text of the custom model caveat, added to any report holding custom model
#' output.
#' @export
CUSTOM_MODEL_CAVEAT <- paste(
  "Custom model values are predictions from site-level models calibrated with field",
  "data, not direct measurements. They carry model error that is not shown in the",
  "figures, tables or error bars, and they are not validated outside the conditions",
  "of the data used to build them."
)

ABOUT_TEXT <- paste(
  "Data in this report come from the Interagency Ecosystem Lidar Monitoring",
  "Program (IntELiMon). Each plot is recorded with a single terrestrial laser",
  "scan (TLS) from plot center, and every scan is processed with the same",
  "automated pipeline into standardized forestry, fuels and ecological metrics",
  "(Murphy et al., 2024; Pokswinski et al., 2026). Scans are grouped into time",
  "steps, and treatment dates separate pre- and post-treatment scans."
)

# Every work the report can cite, keyed. A report always lists BASE_REFERENCES;
# the others are listed when a figure or table in it uses a METHOD citing them.
# Entries are listed alphabetically by their text.
REFERENCE_TEXT <- list(
  anderson1982 = paste(
    "Anderson, H. E. (1982). Aids to determining fuel models for estimating fire behavior.",
    "Gen. Tech. Rep. INT-122. Ogden, UT: U.S. Department of Agriculture, Forest Service,",
    "Intermountain Forest and Range Experiment Station. 22 p.",
    "https://doi.org/10.2737/INT-GTR-122"
  ),
  bailey_dell1973 = paste(
    "Bailey, R. L., & Dell, T. R. (1973). Quantifying diameter distributions with the",
    "Weibull function. Forest Science, 19(2), 97-104."
  ),
  andrews2018 = paste(
    "Andrews, P. L. (2018). The Rothermel surface fire spread model and associated",
    "developments: a comprehensive explanation. Gen. Tech. Rep. RMRS-GTR-371. Fort Collins,",
    "CO: U.S. Department of Agriculture, Forest Service, Rocky Mountain Research Station.",
    "121 p. https://doi.org/10.2737/RMRS-GTR-371"
  ),
  brown1974 = paste(
    "Brown, J. K. (1974). Handbook for inventorying downed woody material. Gen. Tech. Rep.",
    "INT-16. Ogden, UT: U.S. Department of Agriculture, Forest Service, Intermountain Forest",
    "and Range Experiment Station. 24 p."
  ),
  byram1959 = paste(
    "Byram, G. M. (1959). Combustion of forest fuels. In K. P. Davis (Ed.), Forest fire:",
    "control and use (pp. 61-89). New York: McGraw-Hill."
  ),
  dixon2002 = paste(
    "Dixon, G. E. (comp.) (2002). Essential FVS: a user's guide to the Forest Vegetation",
    "Simulator. Internal Report. Fort Collins, CO: U.S. Department of Agriculture, Forest",
    "Service, Forest Management Service Center. 226 p."
  ),
  curtis1982 = paste(
    "Curtis, R. O. (1982). A simple index of stand density for Douglas-fir. Forest Science,",
    "28(1), 92-94."
  ),
  murphy2024 = paste(
    "Murphy, M. C., Loudermilk, E. L., Pokswinski, S., et al. (2024). Terrestrial 3D",
    "laser scanning for ecosystem and fire effects monitoring. Gen. Tech. Rep. SRS-277.",
    "Asheville, NC: U.S. Department of Agriculture, Forest Service, Southern Research",
    "Station. https://doi.org/10.2737/SRS-GTR-277"
  ),
  neyman_scott1958 = paste(
    "Neyman, J., & Scott, E. L. (1958). Statistical approach to problems of cosmology.",
    "Journal of the Royal Statistical Society: Series B, 20(1), 1-43."
  ),
  pokswinski2026 = paste(
    "Pokswinski, S., Nelson, K., Maxwell, A., et al. (2026). IntELiMon: an automated",
    "framework for standardized terrestrial lidar processing in multi-disciplinary",
    "ecosystem monitoring. Forestry: An International Journal of Forest Research, 99(5),",
    "cpag083. https://doi.org/10.1093/forestry/cpag083"
  ),
  reineke1933 = paste(
    "Reineke, L. H. (1933). Perfecting a stand-density index for even-aged forests.",
    "Journal of Agricultural Research, 46(7), 627-638."
  ),
  reinhardt_crookston2003 = paste(
    "Reinhardt, E. D., & Crookston, N. L. (Tech. Eds.) (2003). The Fire and Fuels Extension",
    "to the Forest Vegetation Simulator. Gen. Tech. Rep. RMRS-GTR-116. Ogden, UT: U.S.",
    "Department of Agriculture, Forest Service, Rocky Mountain Research Station. 209 p."
  ),
  rothermel1972 = paste(
    "Rothermel, R. C. (1972). A mathematical model for predicting fire spread in wildland",
    "fuels. Res. Pap. INT-115. Ogden, UT: U.S. Department of Agriculture, Forest Service,",
    "Intermountain Forest and Range Experiment Station. 40 p."
  ),
  rothermel1991 = paste(
    "Rothermel, R. C. (1991). Predicting behavior and size of crown fires in the Northern",
    "Rocky Mountains. Res. Pap. INT-438. Ogden, UT: U.S. Department of Agriculture, Forest",
    "Service, Intermountain Research Station. 46 p."
  ),
  scott_burgan2005 = paste(
    "Scott, J. H., & Burgan, R. E. (2005). Standard fire behavior fuel models: a",
    "comprehensive set for use with Rothermel's surface fire spread model. Gen. Tech. Rep.",
    "RMRS-GTR-153. Fort Collins, CO: U.S. Department of Agriculture, Forest Service, Rocky",
    "Mountain Research Station. 72 p. https://doi.org/10.2737/RMRS-GTR-153"
  ),
  scott_reinhardt2001 = paste(
    "Scott, J. H., & Reinhardt, E. D. (2001). Assessing crown fire potential by linking",
    "models of surface and crown fire behavior. Res. Pap. RMRS-RP-29. Fort Collins, CO:",
    "U.S. Department of Agriculture, Forest Service, Rocky Mountain Research Station. 59 p.",
    "https://doi.org/10.2737/RMRS-RP-29"
  ),
  vanwagner1977 = paste(
    "Van Wagner, C. E. (1977). Conditions for the start and spread of crown fire. Canadian",
    "Journal of Forest Research, 7(1), 23-34. https://doi.org/10.1139/x77-004"
  )
)

BASE_REFERENCES <- c("murphy2024", "pokswinski2026")

#' Methods behind report items, keyed. A report holding an item that uses one
#' (the `methods` of report_item()) explains it in "About these data", in this
#' order, and lists its references.
#' @export
METHODS <- list(
  fire_model = list(
    text = paste(
      "Fire behavior estimates (rothRmel) use the Rothermel (1972) surface fire spread",
      "model, implemented as described by Andrews (2018), with fireline intensity and flame",
      "length from Byram (1959). Crown fire initiation follows Van Wagner (1977), crown fire",
      "spread follows Rothermel (1991) using standard fuel model 10 (Anderson, 1982), and",
      "torching and crowning indices follow Scott and Reinhardt (2001)."
    ),
    refs = c("rothermel1972", "andrews2018", "byram1959", "vanwagner1977", "rothermel1991",
             "anderson1982", "scott_reinhardt2001")
  ),
  brown = list(
    text = paste(
      "Downed woody fuel loads (1-, 10- and 100-hour) are calculated from time-lag",
      "intercept counts, modeled from each scan per 40 m of transect, with the planar",
      "intersect equations of Brown (1974)."
    ),
    refs = "brown1974"
  ),
  fbfm13 = list(
    text = paste(
      "Live herbaceous and woody loads, and dead loads without a usable count, come from",
      "the 13 fire behavior fuel models of Anderson (1982), scaled to the fuel bed depth."
    ),
    refs = "anderson1982"
  ),
  fbfm40 = list(
    text = paste(
      "Live herbaceous and woody loads, and dead loads without a usable count, come from",
      "the 40 standard fire behavior fuel models of Scott and Burgan (2005), scaled to the",
      "fuel bed depth."
    ),
    refs = "scott_burgan2005"
  ),
  occlusion = list(
    text = paste(
      "Per-area forestry values (density, basal area, stand density index and relative",
      "density) are divided by the unoccluded area (nonocarea) of each scan, the part of",
      "the plot visible to the scanner, which corrects them for trees hidden behind other",
      "stems and vegetation (Murphy et al., 2024; Pokswinski et al., 2026)."
    ),
    refs = c("murphy2024", "pokswinski2026")
  ),
  stand_density = list(
    text = paste(
      "Stand density index follows Reineke (1933) and relative density follows",
      "Curtis (1982). Stocking is expressed as a share of a maximum stand density index",
      "of 450, a general value not specific to the species or region."
    ),
    refs = c("reineke1933", "curtis1982")
  ),
  species_assignment = list(
    text = paste(
      "Tree species are not measured by the scanner. Species were assigned to the detected",
      "stems from a species mix entered by the user, using the assignment rule recorded",
      "with each figure or table, so per-species values depend on those choices."
    ),
    refs = character()
  ),
  size_bias = list(
    text = paste(
      "The size bias chart estimates the stems missed in each diameter class from a",
      "detection probability that falls with stem size. It is indicative only and is not",
      "applied to the stand metrics."
    ),
    refs = character()
  ),
  generative = list(
    text = paste(
      "Simulated stem maps are not measured. Stem diameters are drawn from a two-parameter",
      "Weibull distribution fitted to the scanned stems (Bailey and Dell, 1973) at the",
      "scans' occlusion-corrected density, and stems are placed in a clustered",
      "Neyman-Scott (Neyman and Scott, 1958), random or regular pattern."
    ),
    refs = c("bailey_dell1973", "neyman_scott1958")
  ),
  fvs = list(
    text = paste(
      "Tree lists, stand records and keyword files were prepared for the Forest Vegetation",
      "Simulator (FVS; Dixon, 2002) from the detected stems, with each stem's trees per",
      "acre taken from the unoccluded area. The files have not been tested in a live FVS",
      "run."
    ),
    refs = "dixon2002"
  ),
  ffe = list(
    text = paste(
      "The FVS keyword file includes the Fire and Fuels Extension (Reinhardt and",
      "Crookston, 2003)."
    ),
    refs = "reinhardt_crookston2003"
  )
)

#' Method of each fire behavior fuel model set, by its Fuels exports key.
#' @export
FUEL_MODEL_METHODS <- c(FBFM13 = "fbfm13", FBFM40 = "fbfm40")

# Reference texts for these keys plus the base ones, alphabetically.
reference_texts <- function(keys = character()) {
  keys <- intersect(unique(c(BASE_REFERENCES, keys)), names(REFERENCE_TEXT))
  sort(unlist(REFERENCE_TEXT[keys], use.names = FALSE), method = "radix")
}

#' Disclaimer printed on the page after the title page.
#' @export
DISCLAIMER <- paste(
  "Ecological monitoring utilizing terrestrial based lidar is a new and quickly evolving",
  "technology. The IntELiMon viewer represents the current state of this technology in fuels",
  "and ecological monitoring. The Science Advisory Panel for the IntELiMon viewer welcomes",
  "discussion/input on peer reviewed methodologies that could be utilized to enhance the",
  "system. USGS, or any person associated with IntELiMon, is not responsible for your use of",
  "the information contained in or linked to this data or analysis from the IntELiMon",
  "Decision Support tool."
)

#' Statement of origin printed under the disclaimer.
#' @export
ORIGIN_TEXT <- "This report was generated using the IntELiMon Decision Support Tool."

#' Title used when the report details leave it blank.
#' @export
DEFAULT_TITLE <- "IntELiMon monitoring report"

#' Caption for the cover photo: "Cover Photo: Agency, Site, plot 1085, 02/15/2022,
#' Points2Pano image". Blank parts are left out.
#' @export
cover_caption <- function(agency, site, plot, date) {
  parts <- c(agency, site, if (nonblank(plot)) paste("plot", plot),
             format(as.Date(date), REPORT_DATE))
  parts <- parts[!is.na(parts) & nzchar(parts)]
  paste0("Cover Photo: ", paste(c(parts, "Points2Pano image"), collapse = ", "))
}

.item_counter <- new.env()
.item_counter$n <- 0L

next_id <- function() {
  .item_counter$n <- .item_counter$n + 1L
  paste0("item", .item_counter$n)
}

#' Standard sections that can be placed in the report like any other item.
#' @export
SECTIONS <- list(
  context = "Scans, plots and treatments",
  map = "Plot locations",
  design = "Sample size and design"
)

#' Preset headings offered for notes; any other text can be typed instead.
#' @export
NOTE_HEADINGS <- c(
  "Introduction", "Management objectives", "Methods", "Data description", "Results",
  "Discussion", "Conclusions", "Management relevance", "Suggested management actions"
)

#' One report item, as added from a card.
#' @param kind "figure" (a ggplot in `plot`), "table" (a data.frame in `table`)
#'   or "image" (a picture file in `image`, or a Points2Pano scan in `photo`
#'   that is downloaded when the report is built).
#' @param title Caption title, e.g. the metric label.
#' @param source Tab the card is on, e.g. "Standard outputs".
#' @param settings Named list of the card's settings, shown under the caption.
#' @param note Footnote printed under a table (fixed text from the card).
#' @param analysis Automated description from `describe_series()`
#'   (app/logic/report_analysis.R), or list(summary, cautions, implication).
#' @param group Heading the item is listed under in the report and its table of
#'   contents; consecutive items with the same group share one heading.
#'   Defaults to the title.
#' @param subheading Subheading for this item under its group, e.g. "Statistics"
#'   or "Box and Whisker plot"; NULL for none.
#' @param thumb Preview for the Report builder: an image URL or data URI.
#' @param methods Keys of METHODS behind the item's values; a report holding it
#'   explains them in "About these data" and lists their references.
#' @return A list with a session-unique `id`.
#' @export
report_item <- function(kind, title, source, settings = list(), plot = NULL,
                        table = NULL, note = NULL, analysis = NULL, group = title,
                        subheading = NULL, image = NULL, photo = NULL, thumb = NULL,
                        methods = character()) {
  stopifnot(kind %in% c("figure", "table", "image"))
  list(
    id = next_id(), kind = kind, title = title, source = source, settings = settings,
    plot = plot, table = table, note = note, analysis = analysis, group = group,
    subheading = subheading, image = image, photo = photo, thumb = thumb,
    methods = methods,
    include_analysis = TRUE, comment = ""
  )
}

#' A text block: optional heading and text, placed anywhere in the report.
#' @param optional TRUE for the blocks a new report starts with: left out of the
#'   report while their text is blank, unless figures or tables follow them.
#' @export
note_item <- function(heading = "", text = "", optional = FALSE) {
  list(id = next_id(), kind = "note", title = "Text block", heading = heading, text = text,
       optional = optional)
}

#' One of the standard SECTIONS, by key.
#' @export
section_item <- function(key) {
  stopifnot(key %in% names(SECTIONS))
  list(id = next_id(), kind = "section", key = key, title = SECTIONS[[key]])
}

#' Contents of a new report: optional Introduction and Data description text
#' blocks, the standard sections, a "Results" block that the added figures and
#' tables follow, and a closing Management relevance block.
#' @export
default_report_items <- function() {
  list(
    note_item("Introduction", optional = TRUE), note_item("Data description", optional = TRUE),
    section_item("context"), section_item("map"), section_item("design"),
    note_item("Results", optional = TRUE), note_item("Management relevance", optional = TRUE)
  )
}

#' Insert `item` right after the item with id `after`; at the end when `after`
#' is NULL or not in the list.
#' @export
insert_after <- function(items, item, after = NULL) {
  i <- if (is.null(after)) NA else match(after, item_ids(items))
  if (is.na(i)) i <- length(items)
  append(items, list(item), after = i)
}

#' Where a figure or table from a card goes: after the last figure, table or
#' image, or after the "Results" block when there are none yet, so the data
#' stay ahead of closing blocks such as Management relevance. At the end
#' otherwise.
#' @export
add_data_item <- function(items, item) {
  kinds <- vapply(items, `[[`, character(1), "kind")
  data_at <- which(kinds %in% c("figure", "table", "image"))
  results_at <- which(vapply(items, function(it) {
    identical(it$kind, "note") && identical(it$heading, "Results")
  }, logical(1)))
  after <- if (length(data_at) > 0) {
    items[[max(data_at)]]$id
  } else if (length(results_at) > 0) {
    items[[results_at[1]]]$id
  }
  insert_after(items, item, after)
}

#' Settings as one line: "Plot type: Box and Whisker; Data type: Percent change".
#' Empty and NULL settings are skipped.
#' @export
settings_line <- function(settings) {
  keep <- vapply(settings, function(v) length(v) == 1 && !is.na(v) && nzchar(v), logical(1))
  settings <- settings[keep]
  if (length(settings) == 0) return("")
  paste(paste0(names(settings), ": ", unlist(settings)), collapse = "; ")
}

item_ids <- function(items) vapply(items, `[[`, character(1), "id")

#' Move an item one place up or down in the list; out-of-range moves are no-ops.
#' @export
move_item <- function(items, id, direction = c("up", "down")) {
  direction <- match.arg(direction)
  i <- match(id, item_ids(items))
  j <- if (direction == "up") i - 1 else i + 1
  if (is.na(i) || j < 1 || j > length(items)) return(items)
  items[c(i, j)] <- items[c(j, i)]
  items
}

#' Drop the item with this id.
#' @export
remove_item <- function(items, id) {
  items[item_ids(items) != id]
}

#' Standard sections not currently in the report (keys).
#' @export
missing_sections <- function(items) {
  present <- unlist(lapply(items, function(it) if (identical(it$kind, "section")) it$key))
  setdiff(names(SECTIONS), present)
}

blk <- function(type, ...) list(type = type, ...)

#' Date format used throughout the report: MM/DD/YYYY.
#' @export
REPORT_DATE <- "%m/%d/%Y"

# Rewrite ISO dates (2025-05-15) as MM/DD/YYYY (05/15/2025) in report text.
us_dates <- function(x) gsub("\\b(\\d{4})-(\\d{2})-(\\d{2})\\b", "\\2/\\3/\\1", x, perl = TRUE)

# Every date in the report's text and tables in MM/DD/YYYY, including those
# carried in from the cards (statistics tables, settings lines, comments).
us_date_block <- function(b) {
  fields <- c("text", "title", "subtitle", "settings", "note", "label", "lines")
  for (f in intersect(fields, names(b))) {
    if (is.character(b[[f]])) b[[f]] <- us_dates(b[[f]])
    if (is.list(b[[f]])) {
      b[[f]] <- lapply(b[[f]], function(v) if (is.character(v)) us_dates(v) else v)
    }
  }
  if (is.data.frame(b$data)) {
    names(b$data) <- us_dates(names(b$data))
    for (j in seq_along(b$data)) {
      if (is.character(b$data[[j]])) b$data[[j]] <- us_dates(b$data[[j]])
      if (inherits(b$data[[j]], "Date")) b$data[[j]] <- format(b$data[[j]], REPORT_DATE)
    }
  }
  if (identical(b$type, "toc")) {
    b$entries <- lapply(b$entries, function(e) {
      e$text <- us_dates(e$text)
      e
    })
  }
  b
}

nonblank <- function(x) !is.null(x) && length(x) == 1 && !is.na(x) && nzchar(trimws(x))

paragraphs <- function(text) {
  p <- trimws(strsplit(text, "\n[[:space:]]*\n")[[1]])
  p[nzchar(p)]
}

#' Lay out a report as a flat list of blocks for the writers.
#'
#' @param items Report items in report order: figures and tables from cards,
#'   notes and standard sections (see `report_item()`, `note_item()`,
#'   `section_item()`).
#' @param meta list(title, subtitle, author, organization, date, summary).
#' @param context list(scan = scan_context(), checks = design_checks()) from
#'   app/logic/report_analysis.R, for the standard sections; NULL when no
#'   scans are loaded.
#'   `context$points` (site, plot, lon, lat) are the plots drawn by the Plot
#'   locations section.
#' @param cover list(caption, image) for the title page and the cover photo
#'   caption; `image` is a local file (see app/logic/report_cover.R) or NULL.
#' @export
report_blocks <- function(items, meta, context = NULL, cover = NULL) {
  # methods behind the figures and tables, explained in About these data
  methods <- unique(unlist(lapply(items, `[[`, "methods")))
  out <- list()
  add <- function(b) out[[length(out) + 1]] <<- b
  n_fig <- 0L
  n_tab <- 0L
  add_table <- function(df, title, note = NULL, settings = "") {
    n_tab <<- n_tab + 1L
    add(blk("table", label = paste0("Table ", n_tab, "."), title = title, data = df,
            note = note, settings = settings))
  }
  # summaries already printed, named by the figure or table they sit under, so
  # a graph and its statistics table don't repeat the same description
  described <- character()
  # Sample size and design notes for individual figures and tables, gathered
  # into that section (when the report has it) with a pointer under each one
  has_design <- any(vapply(items, function(it) identical(it$key, "design"), logical(1)))
  object_notes <- list()
  design_at <- NULL
  # heading of the run of items being laid out: consecutive items from one
  # card share it, each with its own subheading
  current_group <- NULL

  if (nonblank(meta$summary)) {
    add(blk("heading", level = 1, text = "Summary"))
    for (p in paragraphs(meta$summary)) add(blk("paragraph", text = p))
  }

  for (k in seq_along(items)) {
    it <- items[[k]]
    if (!it$kind %in% c("figure", "table", "image")) current_group <- NULL
    # a blank optional block is dropped, unless it heads figures or tables
    if (identical(it$kind, "note") && isTRUE(it$optional) && !nonblank(it$text)) {
      nxt <- if (k < length(items)) items[[k + 1]]$kind else ""
      if (!nxt %in% c("figure", "table", "image")) next
    }
    switch(it$kind,
      section = {
        if (it$key == "map") {
          add(blk("heading", level = 1, text = it$title))
          n_plots <- if (is.null(context$points)) 0 else nrow(context$points)
          if (n_plots == 0) {
            add(blk("paragraph", text = "No plots were selected when this report was built."))
          } else {
            n_fig <- n_fig + 1L
            add(blk("image", label = paste0("Figure ", n_fig, "."),
                    title = sprintf("Locations of the %s in this report.",
                                    plural(n_plots, "plot")),
                    path = NULL, map = context$points,
                    settings = "Basemap: Esri World Imagery"))
          }
        } else if (it$key == "context") {
          add(blk("heading", level = 1, text = it$title))
          scan <- context$scan
          if (is.null(scan)) {
            add(blk("paragraph", text = "No scans were loaded when this report was built."))
          } else {
            add(blk("paragraph", text = scan$text))
            for (p in scan$treatments) add(blk("paragraph", text = p))
            add_table(scan$plots, "Plots included in this report.")
            if (!is.null(scan$treatment_table)) {
              add_table(scan$treatment_table, "Treatments entered on the Set Treatments tab.",
                        note = "Scans collected on a treatment date count as after it.")
            }
            add_table(scan$steps, "Time steps: how scans were grouped for analysis.",
                      note = "Scans collected after a treatment date start a new time step.")
          }
        } else {
          # filled in once every figure and table has its number
          add(blk("design_placeholder"))
          design_at <- length(out)
        }
      },
      note = {
        if (nonblank(it$heading)) add(blk("heading", level = 1, text = it$heading))
        if (nonblank(it$text)) for (p in paragraphs(it$text)) add(blk("paragraph", text = p))
      },
      {
        settings <- settings_line(c(list(Source = it$source), it$settings))
        group <- if (nonblank(it$group)) it$group else it$title
        if (!identical(group, current_group)) {
          add(blk("heading", level = 2, text = group))
          current_group <- group
        }
        if (nonblank(it$subheading)) add(blk("heading", level = 3, text = it$subheading))
        if (it$kind == "figure") {
          n_fig <- n_fig + 1L
          label <- paste("Figure", n_fig)
          add(blk("figure", label = paste0(label, "."), title = it$title,
                  plot = it$plot, settings = settings))
        } else if (it$kind == "image") {
          n_fig <- n_fig + 1L
          label <- paste("Figure", n_fig)
          add(blk("image", label = paste0(label, "."), title = it$title,
                  path = it$image, photo = it$photo, settings = settings))
        } else {
          add_table(it$table, it$title, note = it$note, settings = settings)
          label <- paste("Table", n_tab)
        }
        a <- it$analysis
        cautions <- if (is.null(a)) character() else a$cautions
        repeated <- !is.null(a) && a$summary %in% described
        if (length(cautions) > 0 && has_design) {
          # a graph and its statistics table share one entry: "Figure 1 and Table 3"
          same <- Position(function(n) identical(n$summary, a$summary), object_notes)
          if (is.na(same)) {
            object_notes[[length(object_notes) + 1]] <- list(
              labels = label, title = it$title, summary = a$summary, cautions = cautions
            )
          } else {
            object_notes[[same]]$labels <- c(object_notes[[same]]$labels, label)
          }
          add(blk("flag", text = DESIGN_POINTER))
        }
        if (!is.null(a) && !isFALSE(it$include_analysis)) {
          if (repeated) {
            add(blk("paragraph", text = sprintf(
              "These data are described under %s.", names(described)[match(a$summary, described)]
            )))
          } else {
            described[label] <- a$summary
            add(blk("paragraph", text = a$summary))
            if (!has_design) for (ck in cautions) add(blk("bullet", text = ck, tone = "caution"))
            if (nonblank(a$implication)) {
              add(blk("paragraph", text = a$implication, face = "italic"))
            }
          }
        }
        if (nonblank(it$comment)) add(blk("paragraph", text = it$comment))
      }
    )
  }

  if (!is.null(design_at)) {
    section <- design_blocks(context, object_notes)
    out <- c(out[seq_len(design_at - 1)], section, out[-seq_len(design_at)])
  }

  sources <- vapply(items, function(it) if (is.null(it$source)) "" else it$source, character(1))
  if ("rothRmel" %in% sources) add(blk("warning", text = ROTHRMEL_CAVEAT))
  if ("Custom models" %in% sources) add(blk("warning", text = CUSTOM_MODEL_CAVEAT))
  # About these data closes the report as well as opening it, followed by
  # the one list of references
  for (b in about_blocks(toc = TRUE, methods = methods)) add(b)
  for (b in reference_blocks(methods)) add(b)

  # front matter, then the table of contents listing the body's headings
  toc <- Filter(function(b) b$type == "heading", out)
  toc <- lapply(toc, function(b) list(text = b$text, level = b$level))
  blocks <- c(front_blocks(meta, cover, methods),
              list(blk("toc", entries = toc), blk("page_break")), out)
  lapply(blocks, us_date_block)
}

# "About these data": the standard text and a paragraph for each of
# `methods` (keys of METHODS). `toc = FALSE` keeps the copy in the front
# matter out of the table of contents.
about_blocks <- function(toc, methods = character()) {
  methods <- intersect(names(METHODS), methods)
  c(
    list(
      blk("heading", level = 1, text = "About these data", toc = toc),
      blk("paragraph", text = ABOUT_TEXT)
    ),
    lapply(unname(METHODS[methods]), function(m) blk("paragraph", text = m$text))
  )
}

# The References section ending the report: the base references plus those
# of `methods`, alphabetically.
reference_blocks <- function(methods = character()) {
  refs <- unlist(lapply(METHODS[intersect(names(METHODS), methods)], `[[`, "refs"))
  c(
    list(blk("heading", level = 1, text = "References")),
    lapply(reference_texts(refs), function(r) blk("paragraph", text = r, size = "small"))
  )
}

#' Red line under a figure or table whose data have sample size or design
#' issues, pointing to where they are listed.
#' @export
DESIGN_POINTER <- "See notes in sample size and design"

# The "Sample size and design" section: issues across all loaded scans, then
# the issues of each figure and table under its label.
design_blocks <- function(context, object_notes) {
  out <- list(blk("heading", level = 1, text = SECTIONS$design))
  checks <- context$checks
  if (length(checks) == 0 && length(object_notes) == 0) {
    return(c(out, list(blk("paragraph", text = paste(
      "No sample size or design issues were detected in the loaded scans or in the figures",
      "and tables of this report."
    )))))
  }
  out <- c(out, list(blk("paragraph", text = paste(
    "The following points limit how far the results can be generalized and should be",
    "considered when interpreting the figures and tables."
  ))))
  if (length(checks) > 0) {
    out <- c(out, list(blk("heading", level = 2, text = "All loaded scans")))
    out <- c(out, lapply(checks, function(ck) blk("bullet", text = ck, tone = "caution")))
  }
  if (length(object_notes) > 0) {
    out <- c(out, list(blk("heading", level = 2, text = "Figures and tables")))
    for (n in object_notes) {
      label <- paste0(paste(n$labels, collapse = " and "), ". ", n$title)
      out <- c(out, list(blk("label", text = label)),
               lapply(n$cautions, function(ck) blk("bullet", text = ck, tone = "caution")))
    }
  }
  out
}

#' Footer text shared by both formats (the page number is added by each writer).
#' @export
footer_text <- function(date = Sys.Date()) {
  paste0(REPORT_STYLE$product, " \u00b7 Generated ", format(date, REPORT_DATE))
}

# Front matter, before the table of contents: the title page, then a page
# with the cover photo caption, lines for notes, About these data, the
# disclaimer and the statement of origin. Its headings stay out of the
# table of contents.
front_blocks <- function(meta, cover, methods = character()) {
  out <- list(
    blk("title_page",
      title = if (nonblank(meta$title)) meta$title else DEFAULT_TITLE,
      subtitle = if (nonblank(meta$subtitle)) meta$subtitle else NULL,
      lines = Filter(nonblank, list(
        if (nonblank(meta$author)) paste("Prepared by", meta$author),
        meta$organization, meta$date
      )),
      image = cover$image
    ),
    blk("page_break"),
    blk("cover_caption", text = if (is.null(cover$caption)) {
      "Cover Photo: Points2Pano image"
    } else {
      cover$caption
    }),
    blk("ruled_lines", n = 5)
  )
  c(out, about_blocks(toc = FALSE, methods = methods), list(
    blk("label", text = "Disclaimer:"),
    blk("paragraph", text = DISCLAIMER),
    blk("paragraph", text = ORIGIN_TEXT, face = "italic"),
    blk("page_break")
  ))
}

#' File name for a built report: the title with anything but letters, digits,
#' dashes and underscores turned into underscores, then the date code, e.g.
#' "GAFSQ_treatment_monitoring_20261013.docx".
#' @export
report_filename <- function(title, format = c("docx", "pdf"), date = Sys.Date()) {
  format <- match.arg(format)
  if (!nonblank(title)) title <- DEFAULT_TITLE
  stem <- gsub("_+", "_", gsub("[^A-Za-z0-9_-]+", "_", trimws(title)))
  stem <- gsub("^_|_$", "", stem)
  paste0(stem, "_", format(as.Date(date), "%Y%m%d"), ".", format)
}
