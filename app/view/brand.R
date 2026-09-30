# app/view/brand.R
# ---------------------------------------------------------------------------
# Branding markup: the navbar lockup (IntELiMon mark + wordmark) and the
# federal sponsor footer. Images live in app/static/images and are served by
# Rhino under the `static/` prefix; all styling is in app/styles/main.scss
# (.imn-brand*, .imn-logo*, .imn-sponsor*).
# ---------------------------------------------------------------------------
box::use(
  shiny[div, img, span, tags],
)

# Ordered sponsor logos: USGS, FWS, USDA FS, BIA, NPS, SERDP/ESTCP. `cls`
# picks up a per-logo height tweak in main.scss for marks whose artwork is
# padded differently from the rest.
sponsors <- list(
  list(alt = "USGS", cls = "usgs", file = "sponsor_usgs.png"),
  list(alt = "U.S. Fish & Wildlife Service", cls = "", file = "sponsor_fws.png"),
  list(alt = "USDA Forest Service", cls = "", file = "sponsor_usfs.png"),
  list(alt = "Bureau of Indian Affairs", cls = "bia", file = "sponsor_bia.png"),
  list(alt = "National Park Service", cls = "", file = "sponsor_nps.png"),
  list(alt = "SERDP / ESTCP", cls = "serdp", file = "sponsor_serdp.png")
)

# Navbar brand: logo + two-line wordmark. The mark links to the IntELiMon
# home page, opened in a new tab - a same-tab navigation would end the Shiny
# session and discard the loaded scans behind an accidental click.
#' @export
brand_title <- function() {
  div(
    class = "imn-brand",
    tags$a(
      class = "imn-logo-link", href = "https://intelimon.xyz",
      target = "_blank", rel = "noopener noreferrer",
      title = "IntELiMon home page (opens in a new tab)",
      img(
        class = "imn-logo", src = "static/images/intelimon_logo.png",
        alt = "IntELiMon home page"
      )
    ),
    div(
      class = "imn-brand-text",
      span(class = "imn-brand-title", "IntELiMon"),
      span(class = "imn-brand-sub", "Decision Support Tool")
    )
  )
}

# Footer sponsor plate: frosted white pane holding the six agency logos.
#' @export
sponsor_footer <- function() {
  imgs <- lapply(sponsors, function(s) {
    img(
      class = paste("imn-sponsor", s$cls),
      src = file.path("static/images", s$file), alt = s$alt
    )
  })
  div(
    class = "imn-sponsorbar",
    div(class = "imn-sponsor-plate", imgs)
  )
}
