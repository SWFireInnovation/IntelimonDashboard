box::use(
  testthat[test_path],
  utils[unzip],
  withr[local_tempdir],
)

box::use(
  app/logic/load_data_dir[is_scan_id],
)

# -- COLUMNS NEEDED FROM DATA ------------------------------------------------
# Every column the dashboard dropdowns plot (gapFraction is derived from canopyCover).
DASHBOARD_COLUMNS <- c(
  "Basalarea", "MDBH", "StemsPacre", "MeanTH", "MaxTH",
  "mGCvol", "mUSvol", "mMSvol", "mOSvol",
  "CBH", "canopyCover", "LAI", "OLAI", "MLAI", "ULAI"
)

# -- TEST DATASET ------------------------------------------------------------
test_scans <- c(
  # across states and forest types
  # not all plots each year
  "AZTS8_0601_20221018_1", "AZTS8_0623_20240625_1", "AZTS8_0601_20250203_1",
  # plots ovelap with two years above, but with different plots in those years
  "GATST_8009_20240403_2", "GATST_8009_20251121_2",
  # multiple scans in the same day, and within a month
  "NJTST_0095_20240103_1", "NJTST_0095_20240103_2", "NJTST_0095_20240131_1",
  # plot extremely close to plot above
  "NJTST_0218_20240304_2", "NJTST_0218_20240408_2"
)

test_sites <- c("AZTS8", "GATST", "NJTST", "AZCNF", "GACHF", "NJPIP")

n_test_scans <- length(test_scans)
n_test_sites <- length(test_sites)
# no_data.csv with 0 lines of data included to mimic meta-data or definition files
n_no_data_csvs <- 1L

# --- IntELiMon metadata-------------------------------------------------------
# define the basic structure of IntELiMon outputs. Downloads mimic the raw script outputs
n_csvs <- 3L
n_subdir <- 6L
n_tif <- 3L
n_jpg <- 1L
n_contents <- n_csvs + n_tif + n_jpg

#' Path of the committed download, still zipped.
#' @return the path of the data file.
viewer_download_zip <- function() {
  test_path("..", "test_data", "IntELiMon_viewer_dwnld.zip")
}

# Every function below returns a folder that is deleted when the calling test ends.

#' Provide a local mock up of the download a user unzips from the IntELiMon Viewer with nested foldders
#' containing individual scan labeled <site>_<year>_<scan>.zip
#'
#' @param .env -  an r environment. Expects parent.frame() to create a mock or chached folder.
#' @return a path to a temporary directory that will be deleted when the calling test ends.
local_viewer_download <- function(.env = parent.frame()) {
  root <- local_tempdir(.local_envir = .env)
  unzip(viewer_download_zip(), exdir = root)
  root
}

#' Provide a local mock up of the outputs from the IntELiMon R script run locally. These are the the same
#' as the scan zips above unpacked: metrics/, Inventory/, Shrubs/, Fuels/, dtm/, chm/
#'
#' @inheritParams local_viewer_download
local_script_output <- function(.env = parent.frame()) {
  download <- local_viewer_download(.env)
  out <- local_tempdir(.local_envir = .env)
  zips <- list.files(download, "[.]zip$", recursive = TRUE, full.names = TRUE)
  zips <- zips[is_scan_id(basename(zips), sep = "_", lgth = 4)]
  for (scan_zip in zips) {
    unzip(scan_zip, exdir = out)
  }

  out
}

#' Unzip the first scan only and leave others zipped. This will create a mix of unpacked directories and
#' zip files containing directories, as well as allowing a scan to be duplicated if keep_zip = TRUE.
#'
#' Provide a testing structure of valid scans in a mix of zipped and unzipped formats, and allow for testing
#' on duplicated scans.
#'
#' @param keep_zip - a boolean value. If False, no scans are duplicated, if TRUE, the first
#' @inheritParams local_viewer_download
local_mixed_download <- function(keep_zip = FALSE, .env = parent.frame()) {
  root <- local_viewer_download(.env)
  first_zip <- sort(list.files(root, "[.]zip$", recursive = TRUE, full.names = TRUE))[1]
  unzip(first_zip, exdir = root)
  if (!keep_zip) file.remove(first_zip)
  root
}
