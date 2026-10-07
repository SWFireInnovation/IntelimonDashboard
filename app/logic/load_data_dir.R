box::use(
  archive,
  dt = data.table,
  datasets[state.abb],
  fs,
  utils[read.csv2],
)

#' Read IntELiMon data files. Accepts csv's or csv's within zips.
#'
#' @param zip_path - str. Archive file path.
#' @param csv_path - str. Csv file path. If csv is in an archive, this is the path relative (within) to
#'        the .zip
#' @return data.table from csv file.
#' @export
read_1_csv <- function(zip_path, csv_path) {
  if (!is.na(zip_path)) {
    con <- archive$archive_read(zip_path, csv_path)
    data <- read.csv2(con, sep = ",")
  } else {
    data <- dt$fread(csv_path)
  }

  scan_info <- get_scan_parts(basename(csv_path))
  data[names(scan_info)] <- scan_info
  data
}

#' Bulk read a list of csv's into a data.table.
#'
#' Take a list of all identified csv files and load them. Assumes the
#' path data.table is the output of get_dir_contents. Where zip_path == NA, the csv_path is the full path to
#' a csv file. Where zip_path contains the full path to a .zip file, csv_path is a partial path to a csv
#' within the .zip file.
#'
#' @param path_dt - data.table. See get_dir_contents
#' @return data.table of all csv's read
#' @export
read_multi_scan <- function(path_dt) {
  dt$rbindlist(
    Map(
      read_1_csv,
      path_dt$zip_path,
      path_dt$csv_path
    ),
    fill = TRUE
  )
}

#' Test if a str has a .csv extention
#'
#' @param test_str a string
#' @return boolean
#' @export
is_csv <- function(test_str)  endsWith(test_str, ".csv")

#' Test if a str is a valid date in the format YYYYmmdd
#'
#' @inheritParams is_csv
#' @return boolean
#' @export
is_date <- function(test_str)  !is.na(as.Date(test_str, "%Y%m%d")) && nchar(test_str) == 8

#' Test if a str is a valid plot number (exp: 0123)
#'
#' @inheritParams is_csv
#' @return boolean
#' @export
is_plot <- function(test_str) {
  has_4_dig <- nchar(test_str) == 4
  is_digit <- grepl("^\\d+$", test_str)

  has_4_dig && is_digit
}

#' Test if a str is a valid site name starting with a valid two letter state name (exp: AZFHQ).
#'
#' @inheritParams is_csv
#' @return boolean
#' @export
is_site <- function(test_str) has_state(test_str) && nchar(test_str) == 5

#' Test if a str starts with a valid two letter state name (exp: AZ).
#'
#' @inheritParams is_csv
#' @return boolean
#' @export
has_state <- function(test_str) {
  valid_states <- c(state.abb, "DC", "PR", "VI", "GU")
  substr(test_str, 1, 2) %in% valid_states
}

#' Test if filename is a valid scan ID (exp: AZFHX_0030_20240219_1_metrics.csv)
#'
#' Tests inlcude searching for valid state name, plot format, file format, and date.
#'
#' @param filename - a string of the filename to be tested, including extension.
#' @param sep - a string containing the separator used (default '_').
#' @param lgth - int. The expected number of components of the filename.
#' @return boolean value
#' @export
is_scan_id <- function(filename, sep = "_", lgth = 5) {
  parts <- strsplit(filename, sep)

  is_scan <- c()
  for (p in 1:length(parts)) {
    part <- parts[[p]]
    is_scan[p] <- length(part) == lgth && is_site(part[1]) && is_plot(part[2]) && is_date(part[3])
  }
  is_scan
}

#' Filter a list of files, returning only those verified as scans.
#'
#' In the IntELiMon script outputs as well as the viewer downloads, each output type is
#' placed into its own directory where each scan is output into individual files appended with the output
#' type. Exp: metrics are output as ./metrics/AZCNF_0012_20241215_1_metrics.csv. This function searches for
#' the output type and returns a list of .csv files where the filename is a verified scan ID.
#'
#' @param path_list - list of valid filepaths for IntELiMon outputs or downloads
#' @param folder_type - str. the class of output searched for, such as inv or metrics
#' @param ext -  str. the ending file pattern. Should be inv.csv or metrics.csv
#' @return boolean list indexing which rows have scan files
#' @export
which_scan_files <- function(path_list, csv_type = "metrics.csv", subdir_type = "metrics") {
  #type_csv <- list.files(path, recursive = TRUE, full.names = TRUE, pattern = csv_type)
  type_csv <- endsWith(path_list, csv_type)
  type_sub_dir <- endsWith(dirname(path_list), subdir_type)
  has_scan_id <- is_scan_id(basename(path_list), sep = "_", lgth = 5)
  type_csv & type_sub_dir & has_scan_id
}

#' Filter a list of files paths for those that are valid metrics files.
#'
#' Recursively searches a directory for file outputs of type "metrics" using the get_scan_files function.
#'
#' @param path_list - list of files in a directory to search for ouptut files of type "metrics"
#' @return boolean list indexing which rows have scan files of type "metrics"
#' @export
which_metrics_files <- function(path_list) {
  which_scan_files(path_list, subdir_type = "metrics", csv_type = "metrics.csv")
}

#' @inheritParams get_metrics_files
#' @export
which_treeinv_files <- function(path_list) {
  which_scan_files(path_list, subdir_type = "Inventory", csv_type = "inv.csv")
}

#' Get a data.table of all zip files and their contents in a parent directory.
#'
#' This function finds all zip files in a parent directory, and returns a data.table with colums zip_path,
#' with the path of the zip file in the directory, and csv_path, containing the archive path of the contents.
#'
#' @param path - str. Valid file path of the parent directory
#' @param ext - str. Expecting .zip, but could allow .tar, .gzip, or other compression formats
#' @return a data.table with zip files and their contents
#' @export
get_zip_contents <- function(path, ext = ".zip") {

  if (!startsWith(ext, ".")) {
    ext <- paste0(".", ext)
  }

  zip_files <-   fs$dir_ls(path, recurse = TRUE, glob = paste0("*", ext))

  is_scan <- is_scan_id(basename(zip_files), sep = "_", lgth = 4)
  # Edge case: If no valid zip files are found, return an empty structure with names
  if (!any(is_scan)) {
    return(data.frame(csv_path = character(), zip_path = character(), stringsAsFactors = FALSE))
  }

  zip_contents <- lapply(zip_files[is_scan], function(file) {
    contents <- archive$archive(file)
    data.frame(
      csv_path = contents$path,
      zip_path = file,
      stringsAsFactors = FALSE
    )
  })

  dt$rbindlist(zip_contents)
}

#' Get a data.table of all csv files in a parent directory.
#'
#' Reutrns a data.table with 2 columns, csv_path listing the path to all csv files in the parent directory and
#' zip_path, which will be NA for all rows in the data.table. For csv files that could be inside of a zip
#' file, see get_zip_contents.
#'
#' @param path - str. A valid directory to search for csv files
#' @return a data.table with the path to all csv files in the parent directory.
#' @export
get_csvs <- function(path) {
  # Unit: microseconds
  #              expr    min      lq      mean  median     uq    max neval
  #        list.files 1120.7 1201.95 1333.8062 1271.85 1439.5 2455.9  1000
  #         fs$dir_ls  796.9  863.90  958.5321  926.25 1039.6 1533.3
  data.frame(csv_path = as.character(fs$dir_ls(path, recurse = TRUE, glob = "*.csv")),
    zip_path = NA_character_,
    stringsAsFactors = FALSE
  )
}

#' Get a data.table with the path to all csv or zip files in a parent directory and columns for scan id.
#'
#' Returns a data.table with 2 columns, csv_path which is the path to a csv file in the parent directory or
#' the relative path to a csv file in an archive and zip_path, which is a path to a zip file containing the
#' csv or NA. Columns with site, plot, date, scanner_id are appended to allow indexing of paths.
#'
#'@inheritParams get_csvs
#' @export
get_dir_contents <- function(path) {
  contents <- dt$rbindlist(list(get_zip_contents(path, ext = "zip"), get_csvs(path)))

  is_scan <- is_scan_id(basename(contents$csv_path))
  scan_info <- get_scan_parts(basename(contents$csv_path[is_scan]))
  contents[is_scan, (names(scan_info)) := scan_info]

  contents
}

#' Returns a list of properly formatted scan information such as site, plot and date from a str.
#'
#'Submit a str in the standard file format of AZFTA_0001_20261007_1_metric.csv, and this function splits it
#' into a named list and manages the data formats. Will also accept a list of strings (uses dt$tstrsplit).
#'
#' @param scan_str - a str or list of str containing site data
#' @param sep - a str defining the delimeter that separates the scan components
#' @return a named list with site, plot scanner_id and date
#' @export
get_scan_parts <- function(scan_str, sep = "_") {
  str_list <- dt$tstrsplit(scan_str, sep,
                           fixed = TRUE,
                           keep = 1:4,
                           names = c("site", "plot", "date", "scanner_id")
  )

  str_list$site <- as.character(str_list$site)
  str_list$plot <- as.character(str_list$plot)
  str_list$scanner_id <- as.integer(str_list$scanner_id)
  str_list$date <- as.Date(as.character(str_list$date), "%Y%m%d")

  str_list
}
#' Build a data.table of all scan outputs in the user's directory with columns for site, plot, date, and
#' scanner_id.
#'
#' Takes a data.table returned from get_dir_contents.
#'
#' From the input data.table, breaks down the valid filenames into a table of all scans. This
#' can be used in conjuntion with session$userData$all_scans() to generate a selection table for users.
#'
#' @param all_paths - a data.table with the path to all csv files in the parent directory.
#' @return a data.table of scan names
#' @export
build_scan_dt <- function(all_paths) {
  # filter for metrics files
  filter_metrics <- which_metrics_files(all_paths$csv_path)
  metric_paths <- all_paths[filter_metrics]

  scan_names <- basename(metric_paths$csv_path)
  scan_dt <- dt$setDT(get_scan_parts(scan_names))

  scan_dt[, ":="(
                 scanner_name = NA_character_,
                 Longitude = NA_real_,
                 Latitude = NA_real_,
                 Agency = as.character("MyPC")
  )]

  scan_dt
}

#' Generic output reader that filters all_paths by apply which_function and then calls read_multi_scan
.read_output <- function(all_paths, which_func) {
  if (nrow(all_paths) == 0) {
    return()
  }
  filter_ouptut <- which_func(all_paths$csv_path)
  output_paths <- all_paths[filter_ouptut]
  read_multi_scan(output_paths)
}


#' @export
read_treeinv <- function(all_paths) {
  .read_output(all_paths, which_treeinv_files)
}

#' @export
read_metrics <- function(all_paths) {
  .read_output(all_paths, which_metrics_files)
}