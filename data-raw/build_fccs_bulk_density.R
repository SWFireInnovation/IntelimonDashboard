# data-raw/build_fccs_bulk_density.R
# ---------------------------------------------------------------------------
# Builds app/data/fccs_bulk_density.csv: a crosswalk from every LANDFIRE FCCS
# raster code to litter and live (shrub + herb) bulk densities in kg/m^3, so a
# measured depth can be scaled to a loading (see app/logic/fccs.R).
#
# LANDFIRE FCCS codes are either a fuelbed number (e.g. 22) or a disturbed
# variant, fuelbed * 10000 + disturbance code (e.g. 220112 = fuelbed 22 after
# disturbance 112).
#
# Sources:
#   LANDFIRE Consume loadings (one row per LANDFIRE FCCS code, tons/acre,
#   depths in inches) - litter depth + loading, shrub and herb loadings and
#   percent live. These are LANDFIRE's own values for its FCCS layer.
#   FERA FCCS calculator summaries (fuelbed version 284, baseline and
#   disturbed) - shrub and herb heights (feet), which the Consume table lacks.
#   A disturbed code missing from the summaries falls back to its undisturbed
#   fuelbed's heights (height_source = "baseline"); codes with no heights at
#   all keep NA live bulk densities (height_source = "none").
#
# Bulk density = loading / depth (stand-level, per unit ground area):
#   litter        litter_loading / litter_depth
#   live          sum(load * perc_live) over shrub + herb strata, divided by
#                 the load-weighted mean shrub/herb height
#   shrub_herb    same, with total (live + dead) shrub and herb loadings
#
# Run from the project root:  Rscript data-raw/build_fccs_bulk_density.R
# ---------------------------------------------------------------------------
box::use(
  data.table[data.table, fifelse, fread, fwrite, rbindlist, tstrsplit],
)

SOURCES <- list(
  consume = "https://www.landfire.gov/sites/default/files/CSV/LF_ConsumeLoadings.csv",
  fera_baseline = paste0(
    "https://raw.githubusercontent.com/pnwairfire/fera-landfiredisturbance/",
    "master/run_landfire/baseline284/fccs_summary.csv"
  ),
  fera_disturbed = paste0(
    "https://raw.githubusercontent.com/pnwairfire/fera-landfiredisturbance/",
    "master/run_landfire/deliverables284/fccs_summary.csv"
  )
)

# tons/acre -> kg/m^2, inches -> m, feet -> m
TPA_TO_KGM2 <- 907.18474 / 4046.8564224
IN_TO_M <- 0.0254
FT_TO_M <- 0.3048

# "FB_0022_FCCS_112.xml" -> 220112; "FB_0022_FCCS.xml" -> 22
filename_to_code <- function(filename) {
  parts <- tstrsplit(gsub(".xml", "", filename, fixed = TRUE), "_", fixed = TRUE)
  fuelbed <- as.integer(parts[[2]])
  if (length(parts) < 4) {
    return(fuelbed)
  }
  disturbance <- as.integer(parts[[4]])
  fifelse(is.na(disturbance), fuelbed, fuelbed * 10000L + disturbance)
}

# live part of a primary + secondary stratum (percent live is 0-100)
live_load <- function(primary, primary_pct, secondary, secondary_pct) {
  (primary * primary_pct + secondary * secondary_pct) / 100
}

bulk_density <- function(load_kgm2, depth_m) {
  fifelse(load_kgm2 == 0, 0, fifelse(depth_m > 0, load_kgm2 / depth_m, NA_real_))
}

consume <- fread(SOURCES$consume)
heights <- rbindlist(lapply(c(SOURCES$fera_baseline, SOURCES$fera_disturbed), function(url) {
  s <- fread(url)
  data.table(
    code = filename_to_code(s$Filename),
    fuelbed_name = s$Fuelbed_name,
    shrub_height_ft = s$Depth_shrub,
    herb_height_ft = s$Depth_herb
  )
}))
heights <- unique(heights, by = "code")

xw <- consume[, .(
  fccs = FCCS,
  fuelbed = fifelse(FCCS >= 10000L, FCCS %/% 10000L, FCCS),
  disturbance = fifelse(FCCS >= 10000L, FCCS %% 10000L, NA_integer_),
  litter_depth_in = litter_depth,
  litter_load_tpa = litter_loading,
  shrub_load_tpa = shrubs_primary_loading + shrubs_secondary_loading,
  shrub_live_load_tpa = live_load(
    shrubs_primary_loading, shrubs_primary_perc_live,
    shrubs_secondary_loading, shrubs_secondary_perc_live
  ),
  herb_load_tpa = nw_primary_loading + nw_secondary_loading,
  herb_live_load_tpa = live_load(
    nw_primary_loading, nw_primary_perc_live,
    nw_secondary_loading, nw_secondary_perc_live
  )
)]

# heights: exact code first, then the undisturbed fuelbed
exact <- heights[match(xw$fccs, heights$code)]
baseline <- heights[match(xw$fuelbed, heights$code)]
xw[, `:=`(
  height_source = fifelse(!is.na(exact$code), "exact",
    fifelse(!is.na(baseline$code), "baseline", "none")
  ),
  fuelbed_name = fifelse(!is.na(exact$code), exact$fuelbed_name, baseline$fuelbed_name),
  shrub_height_ft = fifelse(!is.na(exact$code), exact$shrub_height_ft, baseline$shrub_height_ft),
  herb_height_ft = fifelse(!is.na(exact$code), exact$herb_height_ft, baseline$herb_height_ft)
)]

# load-weighted mean of the shrub and herb heights (ft)
weighted_height <- function(shrub_load, herb_load, shrub_height, herb_height) {
  # a stratum with no load contributes nothing, even if its height is unknown
  shrub_part <- fifelse(shrub_load > 0, shrub_load * shrub_height, 0)
  herb_part <- fifelse(herb_load > 0, herb_load * herb_height, 0)
  total <- shrub_load + herb_load
  fifelse(total > 0, (shrub_part + herb_part) / total, 0)
}

xw[, `:=`(
  litter_bd_kgm3 = bulk_density(litter_load_tpa * TPA_TO_KGM2, litter_depth_in * IN_TO_M),
  live_depth_ft = weighted_height(
    shrub_live_load_tpa, herb_live_load_tpa, shrub_height_ft, herb_height_ft
  ),
  live_load_tpa = shrub_live_load_tpa + herb_live_load_tpa,
  shrub_herb_depth_ft = weighted_height(
    shrub_load_tpa, herb_load_tpa, shrub_height_ft, herb_height_ft
  ),
  shrub_herb_load_tpa = shrub_load_tpa + herb_load_tpa
)]
xw[, `:=`(
  live_bd_kgm3 = bulk_density(live_load_tpa * TPA_TO_KGM2, live_depth_ft * FT_TO_M),
  shrub_herb_bd_kgm3 = bulk_density(shrub_herb_load_tpa * TPA_TO_KGM2, shrub_herb_depth_ft * FT_TO_M)
)]

num_cols <- names(xw)[vapply(xw, is.double, logical(1))]
xw[, (num_cols) := lapply(.SD, round, 5), .SDcols = num_cols]

dir.create("app/data", showWarnings = FALSE)
fwrite(xw[order(fccs)], "app/data/fccs_bulk_density.csv")
message(
  "Wrote ", nrow(xw), " FCCS codes; heights: ",
  paste(names(table(xw$height_source)), table(xw$height_source), sep = " = ", collapse = ", ")
)
