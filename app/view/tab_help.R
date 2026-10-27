# ---------------------------------------------------------------------------
# Help tab: the user manual. Each topic is a Markdown file in app/static/help
# named NN-topic.md (NN sets the order); its first "# " heading is the label in
# the topic list. Pages are rendered once when the UI is built. See
# app/static/help/README.md for how to write a page. The search box above the
# topic list is handled in the browser by app/static/js/help_search.js.
# ---------------------------------------------------------------------------

box::use(
  bslib[nav_panel, navset_pill_list],
  commonmark[markdown_html],
  here[here],
  htmltools[tagQuery],
  shiny[HTML, NS, div, moduleServer, tags],
  tools[file_path_sans_ext],
)

HELP_DIR <- here("app", "static", "help")

# Topic files in display order; README.md and other unnumbered files are skipped
help_files <- function(help_dir = HELP_DIR) {
  sort(list.files(help_dir, pattern = "^[0-9]{2}-.+\\.md$", full.names = TRUE))
}

# Label for a topic: the first "# " heading, else the file name minus its number
help_title <- function(lines, file) {
  heading <- grep("^# +", lines, value = TRUE)
  if (length(heading) > 0) return(trimws(sub("^# +", "", heading[[1]])))
  sub("^[0-9]{2}-", "", file_path_sans_ext(basename(file)))
}

# Markdown to HTML. Web links open in a new tab: leaving the page would end
# the Shiny session and discard the loaded scans. {{APP_VERSION}} in a page is
# replaced with the app version (from version.yml, read in app/main.R).
help_html <- function(lines, version = "") {
  lines <- gsub("{{APP_VERSION}}", version, lines, fixed = TRUE)
  html <- markdown_html(lines, extensions = TRUE)
  gsub('<a href="(https?://[^"]*)"', '<a href="\\1" target="_blank" rel="noopener noreferrer"', html)
}

help_page <- function(file, version = "") {
  lines <- readLines(file, encoding = "UTF-8", warn = FALSE)
  nav_panel(
    title = help_title(lines, file),
    div(class = "help-page", HTML(help_html(lines, version)))
  )
}

# Search box for the topic column. Filtering and highlighting happen in the
# browser (app/static/js/help_search.js), so typing never round-trips to R.
# The input has no id, so Shiny doesn't bind it as an input.
help_search <- function() {
  div(
    class = "help-search",
    tags$input(
      type = "search", class = "form-control form-control-sm help-search-input",
      placeholder = "Search help", `aria-label` = "Search help", autocomplete = "off"
    ),
    div(class = "help-search-empty", hidden = NA, "No matching topics")
  )
}

#' @export
ui <- function(id, version = "") {
  ns <- NS(id) # nolint: object_usage_linter

  topics <- do.call(
    navset_pill_list,
    c(lapply(help_files(), help_page, version = version), list(widths = c(2, 10), well = FALSE))
  )
  nav_panel(
    title = "Help",
    div(
      class = "help-layout",
      # the search box sits at the top of the topic column, above the pills
      tagQuery(topics)$find("ul.nav")$before(help_search())$allTags()
    ),
    tags$script(src = "static/js/help_search.js")
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {})
}
