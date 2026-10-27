# ---------------------------------------------------------------------------
# Static lookup tables shared across the view modules. Pure data, no Shiny.
# Fuel-specific constants live in app/logic/fuel.R; API-specific constants
# (base_url) live in app/logic/api_client.R.
# ---------------------------------------------------------------------------

# convert column names from IntELiMon output data to nicely styled labels
COLNAME2LABEL <- c(
  mGCvol = "Ground cover volume (0-1m; mGCvol)",
  mUSvol = "Understory volume (1-3m; mUSvol)",
  mMSvol = "Midstory volume (3-9m; mMSvol)",
  mOSvol = "Overstory volume (>9m; mOSvol)",
  Basalarea  = "Basal area (Basalarea)",
  MDBH       = "Mean DBH (MDBH)",
  StemsPacre = "Stems per acre (StemsPacre)",
  TreesN     = "Number of trees (TreesN)",
  nonocarea  = "Unoccluded area (nonocarea)",
  MeanTH     = "Mean tree height (MeanTH)",
  MaxTH      = "Maximum tree height (MaxTH)",
  CBH         = "Canopy base height (CBH)",
  canopyCover = "Canopy cover (canopyCover)",
  gapFraction = "Gap fraction (1 - canopyCover)",
  LAI         = "Leaf area index (LAI)",
  OLAI        = "Overstory (>9m) LAI (OLAI)",
  MLAI        = "Midstory (3-9m) LAI (MLAI)",
  ULAI        = "Understory (1-3m) LAI (ULAI)",
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
  fire_type_num = "Crown fire type (0/1/2)",
  BLLitmod      = "Broadleaf litter cover (%)",
  Fernmod       = "Fern cover (%)",
  Forbsmod      = "Forb cover (%)",
  Grassmod      = "Grass cover (%)",
  HWBAmod       = "Hardwood basal area (ft\u00B2/acre)",
  LNLitmod      = "Long needle litter cover (%)",
  Littermod     = "Litter cover (%)",
  Lnlittmod     = "Long needle litter cover (%)",
  MDDmod        = "Mean duff depth (cm)",
  MFBDmod       = "Mean fuel bed depth (cm)",
  MLDmod        = "Mean litter depth (cm)",
  MossLichenlm  = "Moss/lichen cover (%)",
  NeedllLittmod = "Needle litter cover (%)",
  OLitmod       = "Other litter cover (%)",
  Otherlittmod  = "Other litter cover (%)",
  PHWBAmod      = "Hardwood basal area (ft\u00B2/acre)",
  PPBAmod       = "Pine basal area (ft\u00B2/acre)",
  Pinelittmod   = "Pine litter cover (%)",
  SNLitmod      = "Short needle cover (%)",
  Shrubmod      = "Shrub cover (%)",
  Snowberrymod  = "Snowberry cover (%)",
  Volatilemod   = "Volatile woody shrub cover (%)",
  Woodymod      = "Live woody cover (%)",
  hunhrmod      = "Hundred hour fuel count (count/40 m)",
  onehrmod      = "One hour fuel count (count/40 m)",
  tenhrmod      = "Ten hour fuel count (count/40 m)",
  thohrmod      = "Thousand hour fuel count (count/40 m)",
  thouhrmod     = "Thousand hour fuel count (count/40 m)"
)

# Treatment types offered on the Set Treatments tab.
TREATMENT_TYPES <- c(
  "Prescribed fire", "Thinning", "Piling and burning", "Mastication", "Herbicide", "Grazing",
  "Planting and seeding", "Disking and plowing"
)

# What the report calls one and several treatments of each type, for its
# overview: "Two prescribed fires took place during the reporting period."
TREATMENT_NOUNS <- list(
  "Prescribed fire" = c("prescribed fire", "prescribed fires"),
  "Thinning" = c("thinning", "thinnings"),
  "Piling and burning" = c("pile burn", "pile burns"),
  "Mastication" = c("mastication treatment", "mastication treatments"),
  "Herbicide" = c("herbicide application", "herbicide applications"),
  "Grazing" = c("grazing treatment", "grazing treatments"),
  "Planting and seeding" = c("planting or seeding treatment", "planting or seeding treatments"),
  "Disking and plowing" = c("disking or plowing treatment", "disking or plowing treatments")
)

# How the report says each treatment was done, completed with " on <date>":
# "Herbicide was applied on 2025-05-15". Combined treatments are joined with
# "and": "The stand was thinned and fuels were piled and burned on ...".
TREATMENT_ACTIONS <- c(
  "Prescribed fire" = "a prescribed fire was carried out",
  "Thinning" = "the stand was thinned",
  "Piling and burning" = "fuels were piled and burned",
  "Mastication" = "vegetation was masticated",
  "Herbicide" = "herbicide was applied",
  "Grazing" = "livestock grazed the area",
  "Planting and seeding" = "plants were established by planting or seeding",
  "Disking and plowing" = "the ground was disked or plowed"
)
