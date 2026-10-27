box::use(
  shiny[reactiveVal, testServer],
  testthat[describe, expect_equal, it],
)

box::use(
  app/logic/report,
  app/view/tab_report[server],
)

describe("tab_report server", {
  it("keeps the comments typed under every kind of card entry", {
    photo <- report$report_item("image", "Points2Pano", "Standard outputs")
    table <- report$report_item("table", "Basal area", "Standard outputs",
                                table = data.frame(x = 1))
    testServer(server, {
      session$userData$report_items <- reactiveVal(list(photo, table))
      args <- list()
      args[[paste0("comment_", photo$id)]] <- "Taken after the burn."
      args[[paste0("comment_", table$id)]] <- "Two plots only."
      do.call(session$setInputs, args)
      expect_equal(with_inputs(photo)$comment, "Taken after the burn.")
      expect_equal(with_inputs(table)$comment, "Two plots only.")
    })
  })
})
