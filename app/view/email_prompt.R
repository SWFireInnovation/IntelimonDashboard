# app/view/email_prompt.R
# ---------------------------------------------------------------------------
# App-wide "Email address required" prompt.
#
# Some external services (e.g. the LANDFIRE Product Service behind the LCP
# export) need a contact email. The address is asked for once per session and
# kept in session$userData$user_email, so any later tool that needs one reuses
# it without asking again.
#
# Usage from any module server:
#   session$userData$request_email(function(email) {...}, reason = "...")
# The callback runs immediately if an email is already known, otherwise after
# the user submits a valid address in the popup. Cancelling drops the request.
# ---------------------------------------------------------------------------
box::use(
  shiny,
)

#' Loose check for something shaped like an email address.
#' @export
is_valid_email <- function(email) {
  is.character(email) && length(email) == 1 &&
    grepl("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", email)
}

email_modal <- function(ns, reason) {
  shiny$modalDialog(
    title = "Email address required",
    if (!is.null(reason)) shiny$p(reason),
    shiny$textInput(ns("email"), label = NULL, placeholder = "name@example.org", width = "100%"),
    shiny$helpText("Used only as the contact address for requests the app makes on your behalf."),
    footer = shiny$tagList(
      shiny$modalButton("Cancel"),
      shiny$actionButton(ns("submit"), "Continue", class = "btn-primary")
    )
  )
}

#' @export
server <- function(id) {
  shiny$moduleServer(id, function(input, output, session) {
    # callback waiting on the popup
    pending <- NULL

    session$userData$request_email <- function(callback, reason = NULL) {
      email <- session$userData$user_email()
      if (is_valid_email(email)) {
        return(callback(email))
      }
      pending <<- callback
      shiny$showModal(email_modal(session$ns, reason), session = session)
    }

    shiny$observeEvent(input$submit, {
      email <- trimws(input$email)
      if (!is_valid_email(email)) {
        shiny$showNotification("Please enter a valid email address.", type = "error")
        return()
      }
      session$userData$user_email(email)
      shiny$removeModal(session)

      callback <- pending
      pending <<- NULL
      if (!is.null(callback)) callback(email)
    })
  })
}
