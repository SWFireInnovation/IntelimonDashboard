box::use(
  purrr[map_df],
  tools[file_path_sans_ext],
  utils[read.csv],
  yaml[read_yaml],
)

#' @export
get_data_path <- function(yaml_path = "../data_loc.yaml") {
  if (file.exists(yaml_path)) {
    intelimon_out <- read_yaml(yaml_path)$data_dir
    file.path(intelimon_out, "metrics")
  } else {
    NULL
  }
}

#' @export
list_plot_files <- function(data_dir) {
  file_names <- list.files(data_dir, pattern = "\\.csv$")
  plot_names <- file_path_sans_ext(file_names)
  names(file_names) <- plot_names
  file_names
}

#' @export
load_selected_plots <- function(data_dir, selected_plots, plot_files) {
  # Map user selection back to actual file names and build full paths
  selected_files <- plot_files[selected_plots]
  full_paths <- file.path(data_dir, selected_files)

  names(full_paths) <- selected_plots

  # Read all selected files and merge them into a single data frame
  map_df(full_paths, \(x) read.csv(x), .id = "Plot_ID")
}
