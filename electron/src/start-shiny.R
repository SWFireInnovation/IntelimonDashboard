# Copyright (c) 2018 Dirk Schumacher, Noam Ross, Rich FitzJohn

# Script that starts the shiny webserver
# Parameters are supplied using environment variables

# Electron use 1124 port
# so Shiny should not use 1124 port
## Nope, this is not needed 250506

# Check if 'shiny' package is installed in R_LIB_PATHS
r_lib_paths <- Sys.getenv("R_LIB_PATHS")

if (!nzchar(r_lib_paths)) {
  stop("R_LIB_PATHS is not available. Please set the correct library path.")
}

.libPaths(r_lib_paths) # Temporarily set library paths to R_LIB_PATHS

result <- tryCatch(
  requireNamespace("shiny", quietly = FALSE),
  error = function(e) {
    cat("[DEBUG] load error:", conditionMessage(e), "\n")
    FALSE
  },
  warning = function(w) {
    cat("[DEBUG] load warning:", conditionMessage(w), "\n")
    FALSE
  }
)

if (!result) {
  stop("Shiny failed to load. See debug above.")
}

if (!requireNamespace("shiny", quietly = TRUE)) {
  stop("The 'shiny' package is not installed in R_LIB_PATHS: ", .libPaths())
}

shiny_dir <- Sys.getenv("RE_SHINY_PATH")

if (!nzchar(shiny_dir) || !dir.exists(shiny_dir)) {
  stop("RE_SHINY_PATH is not set or does not exist: '", shiny_dir, "'")
}

shiny::runApp(
  appDir = shiny_dir,
  host = "127.0.0.1",
  launch.browser = FALSE,
  port = as.integer(Sys.getenv("RE_SHINY_PORT", unset = "1124"))
)
