box::use(bslib,
  htmlwidgets[onRender],
  leaflet,
  leaflet.extras[
    addDrawToolbar, drawPolygonOptions, drawRectangleOptions, editToolbarOptions,
    removeDrawToolbar
  ],
  shiny[NS, moduleServer, outputOptions, reactive],
)

box::use(
  app/view/map_controls[update_extent],
)


# The map is rendered at startup (see `outputOptions` below), so it can be updated while its tab is
# hidden. A hidden map has no size, and fitting it leaves it shrunk in the corner once it is shown
# again. This reports whether the map is on screen (input `map_visible`) so the server holds back
# fits until it is, and puts the map back where the user left it when it is shown again.
VISIBLE_JS <- "
function(el) {
  var map = this;
  var view = null;
  function isVisible() { return el.offsetWidth > 0 && el.offsetHeight > 0; }
  var visible = isVisible();
  map.on('moveend', function() {
    if (isVisible()) view = {center: map.getCenter(), zoom: map.getZoom()};
  });
  Shiny.setInputValue(el.id + '_visible', visible);
  new ResizeObserver(function() {
    if (isVisible() === visible) return;
    visible = isVisible();
    if (visible) {
      var saved = view;
      map.invalidateSize();
      if (saved) map.setView(saved.center, saved.zoom, {animate: false});
    }
    Shiny.setInputValue(el.id + '_visible', visible);
  }).observe(el);
}"

# The map's drawing tools: rectangles and polygons, drawn into the "aoi"
# group - an area of interest on the Fuels exports tab, a selection of plots
# on the Selection Map.
add_draw_tools <- function(map) {
  addDrawToolbar(
    map,
    targetGroup = "aoi",
    rectangleOptions = drawRectangleOptions(),
    polygonOptions = drawPolygonOptions(),
    polylineOptions = FALSE,
    circleOptions = FALSE,
    markerOptions = FALSE,
    circleMarkerOptions = FALSE,
    editOptions = editToolbarOptions(edit = TRUE, remove = TRUE)
  )
}

#' Remove the shapes drawn on a map, keeping its drawing tools.
#'
#' Drawn shapes are not registered with leaflet's layer manager, so
#' clearGroup("aoi") leaves them; the draw toolbar's own clear does remove
#' them, and the toolbar is put back straight after.
#' @param proxy - a leafletProxy of a map built by `server()`.
#' @export
clear_drawn_shapes <- function(proxy) {
  removeDrawToolbar(proxy, clearFeatures = TRUE) |>
    add_draw_tools()
}

#' @export
ui <- function(id) {
  ns <- NS(id)
  leaflet$leafletOutput(ns("map"), height = "100%")
}

#' @param id module id - must match the id `ui()` was called with.
#' @param fit2pts - a reactive containing a data.table with 2 columns containing EPSG 3857 formatted location
#'        data (used to set map extent). Pass the reactive object, not the current value (no parenthases)
#' @param col_names - a list defining column names of lat and lng location data
#' @return a named list containing a leafletProxy map, and reactives of input values such as input$zoom
#' @export
server <- function(id, fit2pts, col_names = list(lat = "Latitude", lng = "Longitude")) {
  moduleServer(id, function(input, output, session) {
    #-----Base Map-------------------------------
    output$map <- leaflet$renderLeaflet({
      leaflet$leaflet(
        options = leaflet$leafletOptions(
          crs = leaflet$leafletCRS(
            crsClass = "L.CRS.EPSG3857",
            code = "EPSG:3857",
            proj4def = "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs",
            resolutions = NULL
          )
        )
      ) |>
        # Esri World Imagery (satellite basemap)
        leaflet$addProviderTiles(
          leaflet$providers$Esri.WorldImagery,
          options = leaflet$providerTileOptions(maxZoom = 20),
          group = "Satellite"
        ) |>
        # Esri World Imagery (political basemap)
        leaflet$addProviderTiles(
          leaflet$providers$Esri.WorldGrayCanvas,
          options = leaflet$providerTileOptions(maxZoom = 20),
          group = "Base Map"
        ) |>
        leaflet$addLayersControl(
          baseGroups = c("Satellite", "Base Map"),
          options    = leaflet$layersControlOptions(collapsed = FALSE),
          position   = "topright"
        ) |>
        add_draw_tools() |>
        onRender(VISIBLE_JS)
    })
    proxy_map <- leaflet$leafletProxy("map", session)

    update_extent(proxy_map, fit2pts, col_names, visible = reactive(isTRUE(input$map_visible)))

    # must be rendered at startup so the map can update during download
    outputOptions(output, "map", suspendWhenHidden = FALSE)

    # return a proxy map
    # inputs are indexed by daisy chaining name spaces:
    #       main calls tab_selectionMap$ui(ns("Selection Map"))
    #       tab_selectionMap calls widget_mapLeaflet$ui(ns('map'))
    #       widget_mapLeaflet calls leaflet$leafletOutput(ns("map"), height = 400)
    # so the id is 'Selection Map-map-map'
    # This is dependent on the parent and grandparent calls, and can be hard to track/easy to break
    # the work around is
    list(
      proxy = proxy_map,
      input = input
    )
  })
}
