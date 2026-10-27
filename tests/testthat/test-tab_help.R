box::use(
  testthat[describe, expect_equal, expect_false, expect_true, it],
)

box::use(
  app/view/tab_help,
)

impl <- attr(tab_help, "namespace")

describe("help_files", {
  it("lists numbered topic pages in order and skips the README", {
    files <- basename(impl$help_files())
    expect_true(length(files) > 0)
    expect_equal(files, sort(files))
    expect_false("README.md" %in% files)
  })
})

describe("help_title", {
  it("uses the first top-level heading", {
    lines <- c("Intro text", "# Selection Map", "## Steps", "# Later heading")
    expect_equal(impl$help_title(lines, "03-selection-map.md"), "Selection Map")
  })

  it("falls back to the file name without its number", {
    expect_equal(impl$help_title(c("## Only a subheading"), "x/12-my-topic.md"), "my-topic")
  })
})

describe("ui", {
  it("renders every topic page", {
    html <- as.character(tab_help$ui("help"))
    for (f in impl$help_files()) {
      title <- impl$help_title(readLines(f, warn = FALSE), f)
      expect_true(grepl(title, html, fixed = TRUE))
    }
  })

  it("shows the app version on the About page", {
    html <- as.character(tab_help$ui("help", version = "9.9.9-test"))
    expect_true(grepl("9.9.9-test", html, fixed = TRUE))
    expect_false(grepl("{{APP_VERSION}}", html, fixed = TRUE))
  })
})

describe("help_search", {
  it("puts the search box in the topic column, before the topic list", {
    html <- as.character(tab_help$ui("help"))
    search_at <- regexpr("help-search-input", html, fixed = TRUE)
    nav_at <- regexpr("nav-stacked", html, fixed = TRUE)
    expect_true(search_at > 0 && search_at < nav_at)
    expect_true(grepl("static/js/help_search.js", html, fixed = TRUE))
  })
})

describe("help_html", {
  it("opens web links in a new tab and leaves page anchors alone", {
    html <- impl$help_html(c("[site](https://intelimon.xyz) and [top](#about)"))
    expect_true(grepl(
      '<a href="https://intelimon.xyz" target="_blank" rel="noopener noreferrer">', html,
      fixed = TRUE
    ))
    expect_true(grepl('<a href="#about">', html, fixed = TRUE))
  })

  it("fills in the app version placeholder", {
    html <- impl$help_html(c("Version {{APP_VERSION}}"), version = "1.2.3")
    expect_true(grepl("Version 1.2.3", html, fixed = TRUE))
    expect_false(grepl("APP_VERSION", html, fixed = TRUE))
  })
})
