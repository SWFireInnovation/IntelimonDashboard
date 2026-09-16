# ---------------------------------------------------------------------------
# Static lookup tables shared across the view modules. Pure data, no Shiny.
# Fuel-specific constants live in app/logic/fuel.R; API-specific constants
# (base_url) live in app/logic/api_client.R.
# ---------------------------------------------------------------------------

# convert column names from IntELiMon output data to nicely styled labels
COLNAME2LABEL <- c(
  mGCvol = "Ground cover volume (mGCvol)",
  mUSvol = "Understory volume (mUSvol)",
  mMSvol = "Midstory volume (mMSvol)",
  mOSvol = "Overstory volume (mOSvol)",
  Basalarea  = "Basal area (Basalarea)",
  MDBH       = "Mean DBH (MDBH)",
  StemsPacre = "Stems per acre (StemsPacre)",
  TreesN     = "Number of trees (TreesN)",
  MeanTH     = "Mean tree height (MeanTH)",
  MaxTH      = "Maximum tree height (MaxTH)",
  CBH         = "Canopy base height (CBH)",
  canopyCover = "Canopy cover (canopyCover)",
  gapFraction = "Gap fraction (1 - canopyCover)",
  LAI         = "Leaf area index (LAI)",
  OLAI        = "Overstory LAI (OLAI)",
  MLAI        = "Midstory LAI (MLAI)",
  ULAI        = "Understory LAI (ULAI)",
  ros_ch_hr     = "Surface rate of spread (ch/hr)",
  ros_m_min     = "Surface rate of spread (m/min)",
  fli_kw_m      = "Surface fireline intensity (kW/m)",
  flame_ft      = "Surface flame length (ft)",
  flame_m       = "Surface flame length (m)",
  rxn_int       = "Reaction intensity (BTU/ft\u00B2/min)",
  hpa           = "Heat per unit area (BTU/ft\u00B2)",
  crown_Io      = "Crown-initiation intensity I\u2080 (kW/m)",
  crown_Ro      = "Critical active-crown ROS R\u2080 (m/min)",
  torching_idx  = "Torching index (mi/h)",
  crowning_idx  = "Crowning index (mi/h)",
  fire_type_num = "Crown fire type (0/1/2)"
)
