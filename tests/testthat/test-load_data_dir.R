box::use(
  testthat[describe, expect_equal, expect_named, expect_null, expect_true, it, test_path],
)

box::use(
  app/logic/load_data_dir,
)

# testthat$test_path is always relative to /tests/testthat/.
# test_data: scan_A.csv, scan_B.csv, notes.txt
test_data <- test_path("../test_data")

# -- get_data_path -------------------------------------------------------------

describe("get_data_path", {
  it("returns NULL when data_loc.yaml does not exist", {
    expect_null(load_data_dir$get_data_path(yaml_path = "nonexistent_path.yaml"))
  })
})

# -- list_plot_files -----------------------------------------------------------

describe("list_plot_files", {
  it("returns a named character vector containing only the two CSV fixtures", {
    result <- load_data_dir$list_plot_files(test_data)

    expect_true(is.character(result))
    expect_true("scan_A" %in% names(result))
    expect_true("scan_B" %in% names(result))
  })

  it("ignores the non-CSV fixture file (notes.txt)", {
    result <- load_data_dir$list_plot_files(test_data)

    expect_true(!("notes" %in% names(result)))
  })

  it("uses plot names (without .csv extension) as vector names", {
    result <- load_data_dir$list_plot_files(test_data)

    expect_named(result, c("scan_A", "scan_B"), ignore.order = TRUE)
  })
})

# -- load_selected_plots -------------------------------------------------------

plot_files <- c(scan_A = "scan_A.csv", scan_B = "scan_B.csv")

describe("load_selected_plots", {
  it("merges both CSVs into one data frame with a Plot_ID column", {
    result <- load_data_dir$load_selected_plots(
      data_dir       = test_data,
      selected_plots = c("scan_A", "scan_B"),
      plot_files     = plot_files
    )

    expect_true("Plot_ID" %in% names(result))
    expect_true("scan_A" %in% result$Plot_ID)
    expect_true("scan_B" %in% result$Plot_ID)
    expect_equal(nrow(result), 2L)
  })

  it("loads only the selected subset when one plot is requested", {
    result <- load_data_dir$load_selected_plots(
      data_dir       = test_data,
      selected_plots = "scan_A",
      plot_files     = plot_files
    )

    expect_equal(unique(result$Plot_ID), "scan_A")
    expect_equal(nrow(result), 1L)
  })
})
