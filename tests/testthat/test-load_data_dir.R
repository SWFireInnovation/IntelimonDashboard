box::use(
  data.table[fread, fwrite],
  testthat,
  utils[zip],
)

box::use(
  disk = app/logic/load_data_dir,
)

# --- TEST DATASET ----------------------------------------------------------
# testthat$test_path is always relative to /tests/testthat/.
# test_data: IntELiMon_viewer_dwnld.zip. This contains a testing set of example cases in the format served
# by the IntELiMon viewer
# handled by helper-data_files.R

# select a single test scan
this_scan <- test_scans[[1]]
this_zip <- paste0(this_scan, ".zip")
this_metric <- paste0("metrics/", this_scan, "_metrics.csv")
these_parts <- strsplit(this_scan, "_", fixed = TRUE)[[1]]
this_site <- these_parts[[1]]
this_date <- as.Date(these_parts[[3]], "%Y%m%d")
this_yr <- substr(these_parts[[3]], 1, 4)


# The same scans, stored three ways.
SOURCES <- list(
  zipped = local_viewer_download,
  loose = local_script_output,
  mixed = local_mixed_download
)

#' Assemble scan labels from a table with a column for each part
#' @param tbl - a data.table with columns: site, plot, date, scanner_id
#' @return a list of strings where each column value is sparated by a "_"
assemble_scan_labels <- function(tbl) {
  sort(paste(tbl$site, tbl$plot, format(tbl$date, "%Y%m%d"), tbl$scanner_id, sep = "_"))
}

name_loaded_agency <- "MyPC"

# -- VALIDATION functions ------------------------------------------------------
# -- is_csv -------------------------------
test_that("is_csv checks the extension and is vectorised", {
  testthat$expect_equal(disk$is_csv(c("a.csv", "b.txt", "csv", "c.csv.bak")), c(TRUE, FALSE, FALSE, FALSE))
})

# -- is_date ------------------------------
test_that("is_date accepts valid dates in format YYYYmmdd only", {
  # TRUE
  # feb 1 with 8 digits
  testthat$expect_true(disk$is_date("20240201"))
  # leap day
  testthat$expect_true(disk$is_date("20240229"))

  # FALSE
  # not a leap year
  testthat$expect_false(disk$is_date("20230229"))
  # no month 13 or day 40
  testthat$expect_false(disk$is_date("20241340"))
  # feb 1 with 7 digits
  testthat$expect_false(disk$is_date("2024021"))
  # 9 digits
  testthat$expect_false(disk$is_date("202402199"))
  testthat$expect_false(disk$is_date("abcdefgh"))
})

# -- is_plot ------------------------------
test_that("is_plot requires exactly four integers", {
  # TRUE
  testthat$expect_true(disk$is_plot("0030"))
  testthat$expect_true(disk$is_plot("8002"))
  # FALSE
  testthat$expect_false(disk$is_plot("030"))
  testthat$expect_false(disk$is_plot("00300"))
  testthat$expect_false(disk$is_plot("00a1"))
  testthat$expect_false(disk$is_plot(""))
})

# -- has_state / is_site ------------------

test_that("has_state validates state and terrtestthat$itory prefixes (case-senstestthat$itively)", {
  testthat$expect_equal(disk$has_state(c("AZKNF", "COAB1", "DCABC", "PRXYZ", "GUXYZ", "VIXYZ")), rep(TRUE, 6))
  testthat$expect_equal(disk$has_state(c("ZZKNF", "azknf", "1ZKNF")), rep(FALSE, 3))
})

test_that("is_site needs a state prefix and exactly five characters", {
  # TRUE
  testthat$expect_true(disk$is_site("AZKNF"))

  # FALSE
  # too short
  testthat$expect_false(disk$is_site("AZKN"))
  # too long
  testthat$expect_false(disk$is_site("AZKNXX"))
  # not a state
  testthat$expect_false(disk$is_site("ZZFHX"))
})

# -- is_scan_id ---------------------------

test_that("is_scan_id accepts properly formatted *.zip (4 parts) or *metrics.csv (5 part; default)", {
  testthat$expect_true(disk$is_scan_id("AZFHX_0030_20240219_1_metrics.csv", lgth = 5))
  testthat$expect_true(disk$is_scan_id("AZFHX_0030_20240219_1.zip", lgth = 4))
  # five parts testthat$expected by default
  testthat$expect_false(disk$is_scan_id("AZFHX_0030_20240219_1.zip"))
  testthat$expect_false(disk$is_scan_id("AZFHX_0030_20240219_1.csv"))
})


test_that("is_scan_id rejects each kind of malformed name", {
  bad <- c(
    # no scan info
    "readme.csv",
    # a part missing (scanner_ID)
    "AZFHX_0030_20240219_metrics.csv",
    # a part too many
    "AZFHX_0030_20240219_1_metrics_myedits.csv",
    # not a state
    "ZZFHX_0030_20240219_1_metrics.csv",
    # site too short
    "AZFH_0030_20240219_1_metrics.csv",
    # plot too short
    "AZFHX_030_20240219_1_metrics.csv",
    # impossible date
    "AZFHX_0030_20241340_1_metrics.csv"
  )
  testthat$expect_equal(disk$is_scan_id(bad), rep(FALSE, length(bad)))
})

test_that("is_scan_id is vectorised and keeps input order", {
  out <- disk$is_scan_id(c("bad.csv", "AZFHX_0030_20240219_1_metrics.csv", "bad.csv"))

  testthat$expect_equal(out, c(FALSE, TRUE, FALSE))
})

test_that("is_scan_id works if the separator is changed", {
  testthat$expect_true(disk$is_scan_id("AZFHX-0030-20240219-1-metrics.csv", sep = "-"))
})

# -- GET FILE INFORMATION ------------------------------------------------------
# -- get_scan_parts -----------------------

test_that("get_scan_parts splits multiple file names into correctly labled parts and data types", {
  out <- disk$get_scan_parts(c("AZFHX_0030_20240219_1_metrics.csv", "COAR8_0001_20240301_2_inv.csv"))

  testthat$expect_named(out, c("site", "plot", "date", "scanner_id"))
  testthat$expect_equal(out$site, c("AZFHX", "COAR8"))
  testthat$expect_equal(out$plot, c("0030", "0001"))
  testthat$expect_equal(out$date, as.Date(c("2024-02-19", "2024-03-01")))
  testthat$expect_equal(out$scanner_id, c(1L, 2L))
})

test_that("get_scan_parts returns an empty list when testthat$it isn't given any valid files (empty list)", {
  out <- disk$get_scan_parts(list())

  testthat$expect_named(out, c("site", "plot", "date", "scanner_id"))
})


# -- which_metrics_files / which_treeinv_files --
# Files are identified by two characteristics: 1) suffix; 2) parent directory name
paths <- c(
  # TRUE: metrics
  "c:/user/bia/TLS/metrics/metrics/AZABC_0030_20240219_1_metrics.csv",
  # path relative inside a zip
  "metrics/COAR8_0001_20240301_2_metrics.csv",

  # TRUE: tree inventory
  "c:/user/bia/TLS/metrics/Inventory/AZABC_0030_20240219_1_inv.csv",
  # path relative inside a zip
  "Inventory/AZABC_0030_20240219_1_inv.csv",

  # FALSE: ALL
  # wrong folder
  "/data/other/AZFHX_0030_20240219_1_metrics.csv",
  # not a scan id
  "/data/metrics/summary_metrics.csv",
  # not a csv
  "/data/metrics/AZFHX_0030_20240219_1_metrics.txt"
)
test_that("which_metrics_files picks scan metrics csvs by folder, suffix and filename", {
  testthat$expect_equal(disk$which_metrics_files(paths), c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE))
})

test_that("which_treeinv_files picks scan inventory csvs by folder, suffix and filename", {
  testthat$expect_equal(disk$which_treeinv_files(paths), c(FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE))
})

# -- Get File lists -----------------------
# -- csvs ----------------

test_that("get_csvs finds csvs recursively, skips other files, and leaves zip_path NA", {

  out <- disk$get_csvs(local_script_output())


  testthat$expect_equal(nrow(out), n_csvs * n_test_scans) # 1 metrics + 1 inventory + 1 Shrubs csvs
  testthat$expect_equal(sum(endsWith(out$csv_path, "_metrics.csv")), n_test_scans)
  testthat$expect_equal(sum(endsWith(out$csv_path, "_inv.csv")), n_test_scans)
  testthat$expect_false(any(grepl("[.]tif$", out$csv_path)))
  testthat$expect_true(all(is.na(out$zip_path)))
  testthat$expect_true(all(file.exists(out$csv_path)))
})

test_that("get_csvs does not look inside zips and returns an empty df if only-zips/no-csv's", {
  out <- disk$get_csvs(local_viewer_download())

  testthat$expect_equal(nrow(out), n_no_data_csvs)
  testthat$expect_named(out, c("csv_path", "zip_path"))
})

test_that("get_csvs on a folder with no csvs returns zero rows without erroring", {
  out <- disk$get_csvs(local_tempdir())

  testthat$expect_equal(nrow(out), 0L)
  testthat$expect_named(out, c("csv_path", "zip_path"))
})

# -- get_zip_contents ----------------
test_that("get_zip_contents doesn't decompress zips whose name is not a scan id and returns an empty table", {
  a_csv <- disk$get_csvs(local_script_output())$csv_path[[1]]
  root <- local_tempdir()
  zip(file.path(root, "backup.zip"), a_csv, flags = "-q")

  out <- disk$get_zip_contents(root)

  testthat$expect_equal(nrow(out), 0L)
  testthat$expect_named(out, c("csv_path", "zip_path"))
})

test_that("get_zip_contents returns an empty table when there are no zips at all", {
  out <- disk$get_zip_contents(local_tempdir())

  testthat$expect_equal(nrow(out), 0L)
  testthat$expect_named(out, c("csv_path", "zip_path"))
})

test_that("get_zip_contents finds all zips in nested directories and searches for csvs within each zip.", {
  out <- disk$get_zip_contents(local_viewer_download())

  testthat$expect_equal(length(out$zip_path), n_test_scans * n_contents)
  testthat$expect_equal(sum(disk$which_metrics_files(out$csv_path)), n_test_scans) # one metrics csv per zip
  testthat$expect_equal(sum(disk$which_treeinv_files(out$csv_path)), n_test_scans)
  testthat$expect_true(all(file.exists(unique(out$zip_path))))
})

# -- get_dir_contents ----------------

test_that("get_dir_contents on a viewer download lists the files inside every scan zip", {
  out <- disk$get_dir_contents(local_viewer_download())

  n_files_from_zip <-  n_test_scans * n_contents + n_no_data_csvs
  n_found_files <- n_files_from_zip + n_no_data_csvs

  testthat$expect_equal(length(unique(out$zip_path)), n_test_scans + n_no_data_csvs)
  testthat$expect_equal(length(out$zip_path), n_files_from_zip)
  testthat$expect_setequal(unique(out$site[!is.na(out$site)]), test_sites)
})

test_that("get_dir_contents adds typed scan info columns for scan files, NA for the rest", {
  out <- disk$get_dir_contents(local_viewer_download())

  testthat$expect_type(out$site, "character")
  testthat$expect_type(out$plot, "character")
  testthat$expect_s3_class(out$date, "Date")
  testthat$expect_type(out$scanner_id, "integer")

  is_data <- disk$which_treeinv_files(out$csv_path) | disk$which_metrics_files(out$csv_path)
  testthat$expect_false(all(is.na(out$site[is_data])))

  is_scan <- disk$is_scan_id(basename(out$csv_path))
  testthat$expect_true(all(is.na(out$site[!is_scan])))
})

test_that("get_dir_contents accurately attches the correct site information", {

  out <- disk$get_dir_contents(local_viewer_download())
  metrics <- out[out$csv_path == this_metric]
  testthat$expect_equal(metrics$site, this_site)
  testthat$expect_equal(metrics$plot, these_parts[[2]])
  testthat$expect_equal(metrics$date, this_date)
  testthat$expect_equal(metrics$scanner_id, as.integer(these_parts[[4]]))

})

test_that("get_dir_contents on script output lists csv files only", {
  out <- disk$get_dir_contents(local_script_output())

  testthat$expect_true(all(is.na(out$zip_path)))
  testthat$expect_equal(length(out$csv_path), n_csvs * n_test_scans)
  testthat$expect_equal(sum(disk$which_metrics_files(out$csv_path)), n_test_scans)
})

test_that("get_dir_contents on a mixed folder returns both loose csvs and zipped files", {
  out <- disk$get_dir_contents(local_mixed_download(keep_zip = TRUE))

  na_zip <- is.na(out$zip_path)

  zip_contents <- n_contents * n_test_scans
  # add only the csvs from the unzipped scan plus the no_data.csv
  all_contents <- zip_contents + n_csvs + n_no_data_csvs

  testthat$expect_equal(length(out$zip_path[!na_zip]), zip_contents)
  testthat$expect_equal(length(out$zip_path), all_contents)

  testthat$expect_true(any(na_zip))
  testthat$expect_true(!all(na_zip))
})

test_that("get_dir_contents on an empty folder returns zero rows", {
  testthat$expect_equal(nrow(disk$get_dir_contents(local_tempdir())), 0L)
})

# -- GET DATA FROM FILES ------------------------------------------------
# -- build_scan_dt ----------------
test_that("build_scan_dt finds the same scans however they are stored", {
  for (get_path_fnc in SOURCES) {
    file_path <- get_path_fnc()
    out <- disk$build_scan_dt(disk$get_dir_contents(file_path))

    testthat$expect_setequal(assemble_scan_labels(out), test_scans)
  }
})

test_that("build_scan_dt is a correctly formatted data.table with expected column names and data types", {
  out <- disk$build_scan_dt(disk$get_dir_contents(local_viewer_download()))

  # is testthat$it a data.table with correct columns?
  testthat$expect_s3_class(out, "data.table")
  testthat$expect_named(
    out,
    c("site", "plot", "date", "scanner_id", "scanner_name", "Longitude", "Latitude", "Agency"),
    ignore.order = TRUE
  )

  # are there NA's or a standard input for unknown information in the local files on disk?
  out_na <- is.na(out)
  testthat$expect_true(all(out_na[, c("Longitude", "Latitude", "scanner_name")]))
  testthat$expect_equal(out$Agency, rep(name_loaded_agency, 10))

  # check data types
  testthat$expect_type(out$site, "character")
  testthat$expect_type(out$plot, "character")
  testthat$expect_s3_class(out$date, "Date")
  testthat$expect_type(out$scanner_id, "integer")
  testthat$expect_type(out$Longitude, "double")
  testthat$expect_type(out$Latitude, "double")
})

test_that("build_scan_dt returns no rows when a folder has scans but no metrics files", {
  paths <- disk$get_dir_contents(local_viewer_download())

  out <- disk$build_scan_dt(paths[!disk$which_metrics_files(paths$csv_path)])

  testthat$expect_equal(nrow(out), 0L)
})

# -- read_1_csv ----------------

test_that("read_1_csv reads one scan identically from testthat$its zip and from a loose file", {
  download <- local_viewer_download()

  # load a test scan
  inner_zip <- file.path(download, this_site, this_yr, this_zip)
  zipped <- disk$read_1_csv(inner_zip, this_metric)
  loose <- disk$read_1_csv(
    NA_character_,
    file.path(local_script_output(), this_metric)
  )

  testthat$expect_s3_class(zipped, "data.table")
  testthat$expect_s3_class(loose, "data.table")
  # compare the columns that matter: the two readers name the unnamed index columns differently
  testthat$expect_equal(zipped[, ..DASHBOARD_COLUMNS], loose[, ..DASHBOARD_COLUMNS])
  testthat$expect_equal(zipped$site, loose$site, this_site)
  testthat$expect_equal(zipped$plot, loose$plot, these_parts[[2]])
  testthat$expect_equal(zipped$plot, loose$plot, this_date)
  testthat$expect_equal(zipped$scanner_id, loose$scanner_id, as.integer(these_parts[[4]]))
})

# -- read_multi_scan -------------------------------------------------------------------------------

test_that("read_multi_scan stacks .zips and .csv files into one table", {
  paths <- disk$get_dir_contents(local_mixed_download())

  out <- disk$read_multi_scan(paths[disk$which_metrics_files(paths$csv_path)])

  testthat$expect_setequal(assemble_scan_labels(out), test_scans)
  testthat$expect_equal(nrow(out), n_test_scans)
})

test_that("read_multi_scan fills a column that is missing from one file", {

  root <- local_script_output()
  one <- file.path(root, this_metric)
  older <- fread(one)
  # delete data
  older[, LAI := NULL]
  # overwrtestthat$ite the file
  # as if wrtestthat$itten by an older version of the script
  fwrite(older, one)
  paths <- disk$get_dir_contents(root)

  out <- disk$read_multi_scan(paths[disk$which_metrics_files(paths$csv_path)])

  testthat$expect_equal(nrow(out), n_test_scans)
  is_older <- out$plot == these_parts[[2]] & out$date == this_date
  testthat$expect_true(is.na(out$LAI[is_older]))
  testthat$expect_false(anyNA(out$LAI[!is_older]))
})

test_that("read_multi_scan returns an empty table for no paths", {
  paths <- disk$get_dir_contents(local_viewer_download())

  testthat$expect_equal(nrow(disk$read_multi_scan(paths[0])), 0L)
})

# -- read_metrics / read_treeinv / .read_output ----------------------------------------------------

test_that("read_metrics loads data from diff file structures with 1 scan per row and all required cols", {
  for (get_path_fnc in SOURCES) {
    file_path <- get_path_fnc()
    out <- disk$read_metrics(disk$get_dir_contents(file_path))

    testthat$expect_setequal(assemble_scan_labels(out), test_scans)
    testthat$expect_equal(setdiff(DASHBOARD_COLUMNS, names(out)), character())
  }
})

test_that("read_treeinv reads the same number of trees from multiple file structures", {
  # count how many trees loaded from all scans using three different source file structures
  counts <- vapply(
    SOURCES, function(make) nrow(disk$read_treeinv(disk$get_dir_contents(make()))), integer(1)
  )

  # must be more than 0 trees
  testthat$expect_gt(counts[["zipped"]], 0L)

  testthat$expect_equal(counts[["loose"]], counts[["zipped"]])
  testthat$expect_equal(counts[["mixed"]], counts[["zipped"]])
})

test_that("read_treeinv has at least one row for every scan, plus DBH and Height", {
  out <- disk$read_treeinv(disk$get_dir_contents(local_viewer_download()))

  testthat$expect_setequal(unique(assemble_scan_labels(out)), test_scans)
  # tree inventory currently has DBH, H, BasalA, X, Y, Error
  testthat$expect_true("DBH" %in% names(out))
  testthat$expect_true("H" %in% names(out))
})

test_that("a scan present in multiple file paths is only read once", {
  zipped_paths <- disk$get_dir_contents(local_viewer_download())
  mixed_paths <- disk$get_dir_contents(local_mixed_download(keep_zip = TRUE))

  metrics_zipped <- disk$read_metrics(zipped_paths)
  metrics_mixed <- disk$read_metrics(mixed_paths)

  second_copy_of_first_scan <- this_scan
  testthat$expect_equal(nrow(metrics_mixed), n_test_scans)
  testthat$expect_equal(nrow(metrics_zipped), n_test_scans)
  testthat$expect_equal(sum(assemble_scan_labels(metrics_mixed) == second_copy_of_first_scan), 1L)
})

test_that("read_metrics and read_treeinv return an empty data.table when given no paths", {
  paths <- disk$get_dir_contents(local_script_output())

  out_metrics <- disk$read_metrics(paths[0])
  out_inv <- disk$read_treeinv(paths[0])

  testthat$expect_s3_class(out_metrics, "data.table")
  testthat$expect_s3_class(out_inv, "data.table")
  testthat$expect_true(nrow(out_metrics) == 0)
  testthat$expect_true(nrow(out_inv) == 0)
})

test_that("read_metrics returns no rows when no path matches", {
  paths <- disk$get_dir_contents(local_script_output())

  testthat$expect_equal(nrow(disk$read_metrics(paths[disk$which_treeinv_files(paths$csv_path)])), 0L)
})

# -- Wrong folder ----------------------------------------------------------------------------------

test_that("a folder holding the still-zipped download finds no scans instead of crashing", {
  # What happens when a user selects the folder containing the downloaded zip without unzipping testthat$it.
  # The outer zip is not named like a scan, so testthat$it is ignored.
  folder <- local_tempdir()
  file.copy(viewer_download_zip(), folder)

  paths <- disk$get_dir_contents(folder)

  testthat$expect_equal(nrow(disk$get_zip_contents(folder)), 0L)
  testthat$expect_equal(nrow(paths), 0L)
  testthat$expect_equal(nrow(disk$build_scan_dt(paths)), 0L)
})
