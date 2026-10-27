box::use(
  shiny[testServer],
  testthat[describe, expect_true, it],
)

box::use(
  app/main[server],
  app/view/tab_load_data[load_data_server = server],
  app/view/tab_selectionMap[selection_map_server = server],
)

# testthat$test_path is always relative to /tests/testthat/.
# test_data: scan_A.csv, scan_B.csv, notes.txt
testdata <- test_path("../test_data")

# -- main server ---------------------------------------------------------------

describe("main server", {
  it("initialises without error", {
    testServer(server, {
      expect_true(TRUE)
    })
  })
})
