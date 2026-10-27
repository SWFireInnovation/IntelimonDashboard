box::use(
  testthat[describe, expect_false, expect_true, it],
)

box::use(
  app/view/email_prompt,
)

describe("is_valid_email", {
  it("accepts ordinary addresses", {
    expect_true(email_prompt$is_valid_email("name@example.org"))
    expect_true(email_prompt$is_valid_email("first.last+fire@sub.agency.gov"))
  })

  it("rejects missing, blank and malformed values", {
    expect_false(email_prompt$is_valid_email(NULL))
    expect_false(email_prompt$is_valid_email(""))
    expect_false(email_prompt$is_valid_email("name@"))
    expect_false(email_prompt$is_valid_email("name example@org.com"))
    expect_false(email_prompt$is_valid_email("name@example"))
    expect_false(email_prompt$is_valid_email(c("a@b.org", "c@d.org")))
  })
})
