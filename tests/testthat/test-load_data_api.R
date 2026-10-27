box::use(
  data.table[is.data.table],
  here[here],
  httr2,
  testthat[expect_error, expect_identical, expect_true, skip_if_not, test_that],
)

box::use(
  api = app/logic/load_data_api,
)

#---------------URL testing ---------------------------------------------------
# Non-exported bindings (like .api_base_url) are reached via the module's
# namespace attribute, per AGENTS.md's convention for testing box modules.
impl <- attr(api, "namespace")

# get_api_base_url() is lazy, so importing the module above always
# succeeds regardless of whether a key is configured - only tests that
# actually call it need to skip when no key is available.
has_key <- nzchar(Sys.getenv("API_PATH_KEY")) || file.exists(here(".env"))

test_that("get_api_base_url() decrypts to a well-formed URL", {
  skip_if_not(has_key, "No API_PATH_KEY / .env available locally or in CI.")
  expect_true(startsWith(api$get_api_base_url(), "http"))
})

test_that("get_api_base_url() provides same url on repeat calls and savesit to cache", {
  skip_if_not(has_key, "No API_PATH_KEY / .env available locally or in CI.")
  first  <- api$get_api_base_url()
  cached <- impl$.cache$.api_base_url
  second <- api$get_api_base_url()
  expect_identical(first, second)
  # Confirms the cache environment was actually written to
  expect_true(!is.null(cached))
  expect_identical(cached, second)
})

test_that("get_api_base_url() errors clearly when no key is configured", {
  # Only safe to exercise this path when nothing local would supply a key -
  # otherwise readRenviron(".env")/Sys.getenv() would just succeed anyway.
  expect_error(api$get_api_base_url(key = "WRONG_key"), "WRONG_key")
})

##---------------Generic API testing ------------------------------------------
test_that("is_request_successful() reflects the response's error state", {
  ok_resp  <- structure(list(status_code = 200), class = "httr2_response")
  err_resp <- structure(list(status_code = 500), class = "httr2_response")
  expect_true(api$is_request_successful(ok_resp))
  expect_true(!api$is_request_successful(err_resp))
})

test_that("resp2dt() returns an empty table for an empty response", {
  # e.g. the tree inventory of a plot with no stems comes back as []
  for (body in c("[]", "{}")) {
    resp <- httr2$response(
      200,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw(body)
    )
    out <- api$resp2dt(resp)
    expect_true(is.data.table(out))
    expect_identical(nrow(out), 0L)
  }
})

test_that("build_points2pano_url_sdsc() hides the site list and map", {
  expect_identical(
    api$build_points2pano_url_sdsc("CATNF", "6022", as.Date("2024-07-31")),
    paste0(
      "https://burnpro3d.sdsc.edu/points2pano/?plot=CATNF_6022&ts=20240731",
      "&m=Basalarea&hplc=y&hm=y"
    )
  )
})

test_that("api_request() raises a clear error when the server can't be reached", {
  # nothing listens on the discard port, so the connection is refused at once
  e <- tryCatch(
    api$api_request("/agencies", request_base_url = "http://127.0.0.1:9"),
    error = function(e) e
  )
  expect_true(api$is_api_unreachable(e))
  expect_true(startsWith(conditionMessage(e), api$API_UNREACHABLE_MSG))
})
