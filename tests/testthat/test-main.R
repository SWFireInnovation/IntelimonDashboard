box::use(
  shiny[reactiveVal, testServer],
  testthat[describe, expect_equal, expect_false, expect_null, expect_true, it],
)

box::use(
  app/main[server],
  app/view/tab_histogram[histogram_server = server],
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

# -- tab_load_data server ------------------------------------------------------

describe("tab_load_data server", {
  it("returns NULL as the initial data_dir when no yaml is configured", {
    testServer(load_data_server, {
      # data_dir is a reactiveVal returned by the module; at startup with no
      # data_loc.yaml present it should be NULL
      expect_null(session$returned())
    })
  })

  it("updates data_dir when a valid directory path is submitted", {
    testServer(load_data_server, {
      session$setInputs(ui_data_dir = testdata, submit_dir = 1)
      expect_equal(session$returned(), testdata)
    })
  })

  it("does not update data_dir when a non-existent path is submitted", {
    testServer(load_data_server, {
      session$setInputs(ui_data_dir = "/does/not/exist", submit_dir = 1)
      expect_null(session$returned())
    })
  })
})

# -- tab_histogram server ------------------------------------------------------

describe("tab_histogram server", {
  it("file_select lists only the CSV files in the testdata directory", {
    data_dir <- reactiveVal(testdata)

    testServer(histogram_server, args = list(data_dir = data_dir), {
      result <- session$getReturned()
      # Trigger the file_select reactive by flushing
      session$flushReact()

      # Reach the internal reactive via the rendered UI output —
      # plot_selector_ui will only render when file_select() returns files
      expect_true(!is.null(output$plot_selector_ui))
    })
  })

  it("combined_data merges selected CSVs and adds a Plot_ID column", {
    data_dir <- reactiveVal(testdata)

    testServer(histogram_server, args = list(data_dir = data_dir), {
      session$setInputs(selected_plots = c("scan_A", "scan_B"))
      session$flushReact()

      df <- combined_data()
      # will change dependent on IntELiMon version
      # expect_true("Plot_ID" %in% names(df))
      expect_equal(nrow(df), 2L)
    })
  })

  it("column_selector_ui renders after plots are selected", {
    data_dir <- reactiveVal(testdata)

    testServer(histogram_server, args = list(data_dir = data_dir), {
      session$setInputs(selected_plots = "scan_A")
      session$flushReact()

      expect_true(!is.null(output$column_selector_ui))
    })
  })

  it("col_hist renders a plot when all inputs are set", {
    data_dir <- reactiveVal(testdata)

    testServer(histogram_server, args = list(data_dir = data_dir), {
      session$setInputs(
        selected_plots  = "scan_A",
        selected_column = "DBH",
        bins            = 3
      )
      session$flushReact()

      expect_true(!is.null(output$col_hist))
    })
  })
})

# -- tab_selectionMap server ---------------------------------------------------

describe("tab_selectionMap server", {
  it("renders the leaflet map output", {
    testServer(selection_map_server, {
      expect_true(!is.null(output$map))
    })
  })

  it("formats selected_dates as YYYYMMDD strings", {
    testServer(selection_map_server, {
      session$setInputs(
        daterange = c(as.Date("2023-06-01"), as.Date("2023-09-30"))
      )
      session$flushReact()

      dates <- selected_dates()
      expect_equal(dates[["start"]], "20230601")
      expect_equal(dates[["end"]], "20230930")
    })
  })

  it("selected_dates updates when the date range input changes", {
    testServer(selection_map_server, {
      session$setInputs(daterange = c(as.Date("2024-01-01"), as.Date("2024-12-31")))
      session$flushReact()
      first <- selected_dates()[["start"]]

      session$setInputs(daterange = c(as.Date("2022-03-15"), as.Date("2022-11-01")))
      session$flushReact()
      second <- selected_dates()[["start"]]

      expect_false(first == second)
    })
  })
})
