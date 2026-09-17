# app/logic/dst_state.R
# ---------------------------------------------------------------------------
# Adapter between this app's `session$userData` store and the data shapes the
# ported Decision Support Tool modules expect (app/view/tab_fuels.R,
# app/view/tab_rothRmel.R, app/view/tab_forestry.R, and the
# app/logic/{fuel,fire_behavior,forestry,fvs,plotting,series}.R modules they
# sit on).
#
# Those modules came from the standalone IntELiMon DST, where every tab was
# handed one `state` list of reactiveVals and the identifying columns were
# named site_name | plot | date_code | scanner_id, with date_code a character
# "YYYYmmdd". This app names them site | plot | date | scanner_id, with date a
# real Date, and keeps them on session$userData.
#
# Rather than rewrite the fire-behavior and plotting code against the local
# names - which would fork it from the DST copy and make future fixes a
# hand-translation job in both directions - the translation happens here, in
# one place. Everything downstream of these functions sees DST column names.
#
# Reactivity: dst_metrics(), dst_treatment_dates() and dst_scan_calls() read
# reactiveVals, so calling them inside a reactive/observer establishes the
# usual dependency. dst_tree_inventory() is the exception - see its comment.
# ---------------------------------------------------------------------------
box::use(
  dt = data.table,
  shiny[reactiveVal],
  utils[type.convert],
)

box::use(
  app/logic/manage_data[pivot_on_model],
)

# site | plot | date | scanner_id  ->  site_name | plot | date_code | scanner_id
#
# `date` is a Date here and a character "YYYYmmdd" in the DST modules, which
# parse it back with as.Date(format = "%Y%m%d"). Any column already carrying a
# DST name is dropped first: the API payload is free to include its own `site`
# or `date` field, and a rename onto an existing name would leave the table
# with two columns of that name and make later lookups ambiguous.
.to_dst_names <- function(x) {
  if (is.null(x) || nrow(x) == 0) {
    return(dt$data.table())
  }

  out <- dt$as.data.table(dt$copy(x))

  clashes <- intersect(c("site_name", "date_code"), names(out))
  if (length(clashes) > 0) {
    out[, (clashes) := NULL]
  }

  if ("site" %in% names(out)) {
    dt$setnames(out, "site", "site_name")
  }
  if ("date" %in% names(out)) {
    out[, date_code := date]
    out[, date := NULL]
  }

  out[]
}

#' Scan metrics in DST column naming.
#'
#' @param session a shiny session object
#' @return data.table of metrics keyed site_name | plot | date_code | scanner_id
#' @export
dst_metrics <- function(session) {
  .to_dst_names(session$userData$metrics())
}

#' Additional prediction models, reshaped from this app's long table (one row
#' per model per scan) into the wide, metrics-like table the fuel and fire
#' behavior code expects (one row per scan, one column per model).
#'
#' `session$userData$extra_models` is a plain field rather than a reactiveVal,
#' so reading it does not by itself make a reactive re-run when new scans are
#' downloaded. dst_metrics() is therefore read first, purely to take a
#' dependency on the metrics reactiveVal: tab_selectionMap sets metrics and
#' then extra_models inside a single observer, so by the time this re-runs the
#' models table is already populated. If extra_models ever becomes a
#' reactiveVal, this can read it directly and the note goes away.
#'
#' @param session a shiny session object
#' @return wide data.table, one row per scan, or an empty data.table
#' @export
dst_models_wide <- function(session) {
  models <- session$userData$extra_models()
  if (is.null(models) || nrow(models) == 0) {
    return(dt$data.table())
  }

  pvt <- pivot_on_model(models)
  .to_dst_names(pvt)
}

#' Tree inventory (one row per stem) in DST column naming.
#'
#' The API returns every inventory field as a string, plus an unnamed row-index
#' column that arrives here as `V1`. The DST loader dropped that column and ran
#' type.convert() so X / Y / H / DBH / BasalA / TreeID are numeric; the same
#' is done here so app/logic/forestry.R and fvs.R see identical input.
#'
#' `session$userData$tree_inv` is a plain field, not a reactiveVal, so the
#' metrics reactiveVal is read first purely to take a dependency: the Selection
#' Map's Get Data observer sets metrics and then tree_inv in one go, so by the
#' time a dependent reactive re-runs, tree_inv is already populated (the same
#' arrangement dst_models_wide() used to rely on). A reactiveVal is also
#' accepted, so this keeps working if tree_inv is converted later.
#'
#' @param session a shiny session object
#' @return data.table keyed site_name | plot | date_code | scanner_id, or an
#'   empty data.table
#' @export
dst_tree_inventory <- function(session) {
  session$userData$metrics()

  trees <- session$userData$tree_inv
  if (is.function(trees)) {
    trees <- trees()
  }
  if (is.null(trees) || nrow(trees) == 0) {
    return(dt$data.table())
  }

  out <- dt$as.data.table(dt$copy(trees))
  if ("V1" %in% names(out)) {
    out[, V1 := NULL] # nolint: unused_declared_object_linter.
  }
  id_cols <- intersect(c("site", "plot", "date", "scanner_id"), names(out))
  value_cols <- setdiff(names(out), id_cols)
  out[, (value_cols) := lapply(.SD, type.convert, as.is = TRUE), .SDcols = value_cols]

  .to_dst_names(out)
}

#' Treatment dates as the character "YYYYmmdd" vector the series and plotting
#' code parses (this app stores them as a one-column data.table of Dates).
#'
#' @param session a shiny session object
#' @return character vector of dates, possibly empty
#' @export
dst_treatment_dates <- function(session) {
  trtmt <- session$userData$trtmt_dates()
  if (is.null(trtmt) || nrow(trtmt) == 0) {
    return(character())
  }

  out <- format(as.Date(trtmt$TreatmentDate), "%Y%m%d")
  out[!is.na(out)]
}

#' The selected scans in DST `scan_calls` shape. The DST used this table both
#' for the navbar count and to drive the Points2Pano viewer, which needs a
#' scan_name; this app has no such column, so it is assembled from the parts.
#'
#' @param session a shiny session object
#' @return data.table: site_name | plot | date_code | scan_name | scanner_id
#' @export
dst_scan_calls <- function(session) {
  sel <- .to_dst_names(session$userData$scan_selection())
  if (nrow(sel) == 0) {
    return(dt$data.table(
      site_name = character(),
      plot = character(),
      date_code = character(),
      scan_name = character(),
      scanner_id = character()
    ))
  }

  out <- sel[, list(
    site_name = as.character(site_name),
    plot = as.character(plot),
    date_code = as.Date(as.character(date_code), "%Y%m%d"),
    scanner_id = as.character(scanner_id)
  )]
  out[is.na(date_code), date_code := ""]

  dt$setcolorder(out, c("site_name", "plot", "date_code", "scan_name", "scanner_id"))
  out[]
}

#' Distinct plot coordinates for the selected scans, used to frame the Fuel
#' tool's AOI map. The DST read these from a full plot inventory loaded at
#' startup; here they ride along on the selection itself.
#'
#' @param session a shiny session object
#' @return data.table: site_name | plot | Longitude | Latitude
#' @export
dst_plot_coords <- function(session) {
  sel <- .to_dst_names(session$userData$scan_selection())
  cols <- c("site_name", "plot", "Longitude", "Latitude")
  if (nrow(sel) == 0 || !all(cols %in% names(sel))) {
    return(dt$data.table(
      site_name = character(), plot = character(),
      Longitude = numeric(), Latitude = numeric()
    ))
  }

  unique(sel[!is.na(Longitude) & !is.na(Latitude), ..cols])
}

#' Create the two session slots the DST tabs share between themselves and that
#' this app's own state store does not carry:
#'
#'   fuel_tool_values - the surface fuel bed submitted from the Fuels exports
#'                      tab, read by rothRmel when its fuel source is set to
#'                      "Fuel tool values". NULL until Submit is pressed.
#'   aoi_polygon      - the area of interest drawn on the Fuels exports map,
#'                      stored as an sf polygon. NULL until one is drawn.
#'
#' Called once from app/main.R's server, alongside the other userData slots.
#' Existing values are left alone so a second call cannot wipe them.
#'
#' @param session a shiny session object
#' @export
init_dst_slots <- function(session) {
  if (is.null(session$userData$fuel_tool_values)) {
    session$userData$fuel_tool_values <- reactiveVal(NULL)
  }
  if (is.null(session$userData$aoi_polygon)) {
    session$userData$aoi_polygon <- reactiveVal(NULL)
  }
  invisible(session)
}
