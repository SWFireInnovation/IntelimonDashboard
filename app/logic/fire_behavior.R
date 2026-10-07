# app/logic/fire_behavior.R
# ---------------------------------------------------------------------------
# Fire behavior model: Rothermel (1972) surface spread + Byram (1959)
# intensity/flame length + Van Wagner (1977) crown fire, with Scott &
# Reinhardt (2001) torching/crowning indices. Pure functions; no Shiny.
#
# Implemented from the primary equations (Andrews 2018, RMRS-GTR-371; Van
# Wagner 1977) in NATIVE US customary units internally, converting at the
# boundaries. No external fire-model package is used, so every term is
# inspectable here. Because it is hand-implemented and untested against a
# reference here, VALIDATE outputs against BehavePlus for a standard fuel
# model before any operational use.
#
# Per scan, the surface fuel bed is built from the lidar/Brown-derived loads
# (1/10/100-hr time-lag) and mean fuel bed depth; canopy terms (CBH, CBD) come
# from the scan metrics. Wind, slope, moistures, foliar moisture and live
# loads are supplied uniformly by the caller (the tab sidebar), so variation
# across scans reflects the changing fuel/canopy structure - which is the
# point: it lets treatment effects show up as fire-behavior trends over time.
# ---------------------------------------------------------------------------
box::use(
  data.table[data.table, rbindlist],
  stats[uniroot],
)

box::use(
  app/logic/fuel[BROWN_CLASSES, brown_class_load],
  app/logic/fuel_bed[bed_for_scan, merge_scan_models],
)

# ---- constants ------------------------------------------------------------
RHO_P <- 32 # oven-dry particle density (lb/ft^3)
S_T <- 0.0555 # total mineral content
S_E <- 0.010 # effective (silica-free) mineral content
HEAT <- 8000 # low heat content (BTU/lb)

# Standard surface-area-to-volume ratios (ft^2/ft^3): 1h,10h,100h,herb,woody
SAV <- c(d1 = 2000, d10 = 109, d100 = 30, herb = 1500, woody = 1500)

# Unit conversions
TONSAC_TO_LBFT2 <- 2000/43560 # tons/acre -> lb/ft^2  (0.045914)
CM_TO_FT <- 0.0328084
MPH_TO_FTMIN <- 88
FTMIN_TO_MMIN <- 0.3048
BTUFTS_TO_KWM <- 3.46414 # BTU/ft/s -> kW/m
FT_TO_M <- 0.3048
FTMIN_TO_CHHR <- 60/66 # ft/min -> chains/hour (1 chain = 66 ft)

# Standard fuel model 10 (Anderson 1982), used for the crown-fire spread rate
# (Rothermel 1991): loads in tons/acre, depth in ft, Mx as fraction.
FM10 <- list(
  load_tonsac = c(d1 = 3.01, d10 = 2.0, d100 = 5.01, herb = 0, woody = 2.0),
  depth_ft    = 1.0,
  mx_dead     = 0.25
)

# ---- Rothermel surface spread core ----------------------------------------
# All inputs US customary. load/sav/mf hold the dead classes followed by the
# two live ones (herb, woody): length 5 (1h, 10h, 100h, herb, woody) or 6 with
# a dead herbaceous class after 100h for cured grass (see cure_live_herb).
# Returns a list with ros_ft_min, I_R (BTU/ft^2/min), sigma, I_B (BTU/ft/s),
# I_B_kw (kW/m), flame_ft, hpa (BTU/ft^2).
roth_core <- function(load_lbft2, sav, mf, delta_ft, mx_dead,
                      midflame_ftmin, slope_frac,
                      heat = HEAT, rho_p = RHO_P) {
  zero <- list(
    ros_ft_min = 0, I_R = 0, sigma = 0,
    I_B = 0, I_B_kw = 0, flame_ft = 0, hpa = 0
  )

  if (is.na(delta_ft) || delta_ft <= 0) {
    return(zero)
  }
  load_lbft2[is.na(load_lbft2)] <- 0
  if (sum(load_lbft2) <= 0) {
    return(zero)
  }

  n_class <- length(load_lbft2)
  dead <- seq_len(n_class - 2)
  live <- (n_class - 1):n_class

  # Surface-area weighting
  Aij <- sav * load_lbft2/rho_p
  A_dead <- sum(Aij[dead])
  A_live <- sum(Aij[live])
  A_T <- A_dead + A_live
  if (A_T <= 0) {
    return(zero)
  }

  f_dead <- A_dead/A_T
  f_live <- A_live/A_T
  f_ij <- numeric(n_class)
  if (A_dead > 0) f_ij[dead] <- Aij[dead]/A_dead
  if (A_live > 0) f_ij[live] <- Aij[live]/A_live

  sav_dead <- sum(f_ij[dead] * sav[dead])
  sav_live <- sum(f_ij[live] * sav[live])
  sigma <- f_dead * sav_dead + f_live * sav_live
  if (sigma <= 0) {
    return(zero)
  }

  # Bulk density, packing ratios
  w_o_total <- sum(load_lbft2)
  rho_b <- w_o_total/delta_ft
  beta <- rho_b/rho_p
  beta_op <- 3.348 * sigma ^ (-0.8189)
  rpr <- beta/beta_op

  # Reaction velocity
  gamma_denom <- 495 + 0.0594 * sigma ^ 1.5
  gamma_max <- sigma ^ 1.5/gamma_denom
  Acoef <- 133 * sigma ^ (-0.7913)
  gamma <- gamma_max * rpr ^ Acoef * exp(Acoef * (1 - rpr))

  # Net loads per category
  wn_dead <- sum(load_lbft2[dead]) * (1 - S_T)
  wn_live <- sum(load_lbft2[live]) * (1 - S_T)

  # Category moisture (area-weighted within category)
  mf_dead <- if (A_dead > 0) sum(f_ij[dead] * mf[dead]) else 0
  mf_live <- if (A_live > 0) sum(f_ij[live] * mf[live]) else 0

  # Dynamic live moisture of extinction (Rothermel 1972)
  if (A_live > 0 && sum(load_lbft2[live]) > 0) {
    Wd <- sum(load_lbft2[dead] * exp(-138/sav[dead]))
    Wl <- sum(load_lbft2[live] * exp(-500/sav[live]))
    ratio <- if (Wl > 0) Wd/Wl else 0
    mf_dead_fine <- if (Wd > 0) {
      sum(load_lbft2[dead] * exp(-138/sav[dead]) * mf[dead])/Wd
    } else {
      0
    }
    mx_live <- 2.9 * ratio * (1 - mf_dead_fine/mx_dead) - 0.226
    mx_live <- max(mx_live, mx_dead)
  } else {
    mx_live <- mx_dead
  }

  # Damping coefficients
  eta_M <- function(mfc, mxc) {
    if (mxc <= 0) {
      return(0)
    }
    rm <- min(mfc/mxc, 1)
    max(0, 1 - 2.59 * rm + 5.11 * rm ^ 2 - 3.52 * rm ^ 3)
  }
  etaM_dead <- eta_M(mf_dead, mx_dead)
  etaM_live <- eta_M(mf_live, mx_live)
  etaS <- min(1, 0.174 * S_E ^ (-0.19))

  rx_dead <- wn_dead * heat * etaM_dead * etaS
  rx_live <- wn_live * heat * etaM_live * etaS
  I_R <- gamma * (rx_dead + rx_live) # BTU/ft^2/min

  # Propagating flux ratio
  xi <- exp((0.792 + 0.681 * sqrt(sigma)) * (beta + 0.1))/
    (192 + 0.2595 * sigma)

  # Wind coefficient (with Rothermel's effective wind-speed limit)
  C <- 7.47 * exp(-0.133 * sigma ^ 0.55)
  B <- 0.02526 * sigma ^ 0.54
  E <- 0.715 * exp(-3.59e-4 * sigma)
  U <- max(0, midflame_ftmin)
  U_max <- 0.9 * I_R # ft/min
  if (U > U_max) U <- U_max
  phi_w <- if (U > 0) C * U ^ B * rpr ^ (-E) else 0

  # Slope coefficient
  phi_s <- 5.275 * beta ^ (-0.3) * slope_frac ^ 2

  # Heat sink
  eps <- exp(-138/sav)
  Qig <- 250 + 1116 * mf
  heat_sink_dead <- f_dead * sum(f_ij[dead] * eps[dead] * Qig[dead])
  heat_sink_live <- f_live * sum(f_ij[live] * eps[live] * Qig[live])
  rbeQ <- rho_b * (heat_sink_dead + heat_sink_live)

  R <- if (rbeQ > 0) I_R * xi * (1 + phi_w + phi_s)/rbeQ else 0 # ft/min

  # Byram intensity and flame length
  t_r <- 384/sigma # residence time (min)
  hpa <- I_R * t_r # heat per unit area (BTU/ft^2)
  I_B <- hpa * R/60 # BTU/ft/s
  flame_ft <- if (I_B > 0) 0.45 * I_B ^ 0.46 else 0

  list(
    ros_ft_min = R, I_R = I_R, sigma = sigma,
    I_B = I_B, I_B_kw = I_B * BTUFTS_TO_KWM,
    flame_ft = flame_ft, hpa = hpa
  )
}

# FM10 surface ROS (ft/min) at a given midflame wind - the basis for the
# Rothermel (1991) crown-fire spread estimate.
fm10_ros_ft_min <- function(mf, mx_dead_env, midflame_ftmin, slope_frac) {
  load <- FM10$load_tonsac * TONSAC_TO_LBFT2
  roth_core(
    load, SAV, mf, FM10$depth_ft, FM10$mx_dead,
    midflame_ftmin, slope_frac
  )$ros_ft_min
}

# ---- dynamic fuel models ----------------------------------------------------
# Scott & Burgan (2005) dynamic models cure part of their live herbaceous load
# into a dead herbaceous class as the herb dries: the share cured falls
# linearly from all of it at 30% herb moisture to none at 120%.
herb_cured_fraction <- function(m_herb_pct) {
  min(1, max(0, 1.333 - 1.11 * m_herb_pct / 100))
}

# Split the live herb load of a 5-class bed into dead (cured) and live herb,
# returning the 6-class bed roth_core takes: 1h, 10h, 100h, dead herb, live
# herb, live woody. The dead herb keeps the herb SAV and takes the 1-hour
# moisture. A static bed (cured = 0) gets an empty dead herb class.
cure_live_herb <- function(load_tonsac, sav, mf, cured) {
  herb <- load_tonsac[["herb"]]
  list(
    load_tonsac = c(load_tonsac[c("d1", "d10", "d100")],
                    dherb = herb * cured, herb = herb * (1 - cured), woody = load_tonsac[["woody"]]),
    sav = c(sav[1:3], dherb = sav[[4]], sav[4:5]),
    mf = c(mf[1:3], mf[1], mf[4:5])
  )
}

# Canopy metrics of a scan without canopy: surface fire only. The crown
# thresholds and indices stay missing, since 0 would read as "torches or
# crowns at any wind".
NO_CANOPY <- list(
  crown_Io = NA_real_, crown_Ro = NA_real_, torching_idx = NA_real_, crowning_idx = NA_real_,
  fire_type_num = 0
)

# ---- one scan -------------------------------------------------------------
# `row` is a named list/1-row frame holding whatever metric/model columns the
# scan has. `env` carries the uniform sidebar settings. Returns a named list
# of fire-behavior outputs (NA where the fuel bed can't be built).
scan_fire_row <- function(row, env) {
  gv <- function(col) {
    if (col %in% names(row)) {
      suppressWarnings(as.numeric(row[[col]]))
    } else {
      NA_real_
    }
  }

  # Surface fuel bed. Either the per-scan lidar/Brown bed (default) or the
  # loadings submitted from the Fuels exports tab (env$bed), which carries
  # one row per scan (app/logic/fuel_bed.R), so the submitted loadings are
  # still tracked through time. A scan the submission doesn't hold uses the
  # submitted means.
  bed <- bed_for_scan(env$bed, row)
  sav_use <- SAV
  if (!is.null(bed)) {
    load_tonsac <- c(
      d1    = bed$load_tonsac[["d1"]],
      d10   = bed$load_tonsac[["d10"]],
      d100  = bed$load_tonsac[["d100"]],
      herb  = bed$load_tonsac[["herb"]],
      woody = bed$load_tonsac[["woody"]]
    )
    delta_ft <- bed$depth_ft
    if (!is.null(bed$sav)) sav_use <- bed$sav
  } else {
    d1 <- brown_class_load(gv("onehrmod"), BROWN_CLASSES$onehr)
    d10 <- brown_class_load(gv("tenhrmod"), BROWN_CLASSES$tenhr)
    d100 <- brown_class_load(gv("hunhrmod"), BROWN_CLASSES$hunhr)
    depth_cm <- gv("MFBDmod")

    load_tonsac <- c(
      d1 = ifelse(is.na(d1), 0, d1),
      d10 = ifelse(is.na(d10), 0, d10),
      d100 = ifelse(is.na(d100), 0, d100),
      herb = env$live_herb_load,
      woody = env$live_woody_load
    )
    delta_ft <- depth_cm * CM_TO_FT
  }
  load_tonsac[is.na(load_tonsac)] <- 0
  load_lbft2 <- load_tonsac * TONSAC_TO_LBFT2

  na_out <- list(
    ros_ch_hr = NA_real_, ros_m_min = NA_real_, rxn_int = NA_real_,
    fli_kw_m = NA_real_, flame_ft = NA_real_, flame_m = NA_real_,
    hpa = NA_real_, crown_Io = NA_real_, crown_Ro = NA_real_,
    torching_idx = NA_real_, crowning_idx = NA_real_, fire_type_num = NA_real_
  )
  # No fuel bed depth is missing data. A bed with no dead fuel is a real
  # result: Rothermel needs dead fine fuel to carry fire, so it doesn't spread.
  if (is.na(delta_ft) || delta_ft <= 0) {
    return(na_out)
  }
  no_dead_fuel <- sum(load_lbft2[1:3]) <= 0

  mf <- c(env$m1, env$m10, env$m100, env$m_herb, env$m_woody)/100

  # dynamic fuel models cure part of the live herb into dead herbaceous fuel
  cured <- if (isTRUE(bed$dynamic)) herb_cured_fraction(env$m_herb) else 0
  cured_bed <- cure_live_herb(load_tonsac, sav_use, mf, cured)
  load_lbft2 <- cured_bed$load_tonsac * TONSAC_TO_LBFT2
  sav_use <- cured_bed$sav
  mf <- cured_bed$mf
  mx_dead_pct <- if (!is.null(bed) && !is.null(bed$mx_dead_pct)) {
    bed$mx_dead_pct
  } else {
    env$mx_dead
  }

  waf <- env$waf
  slope_frac <- env$slope_pct/100
  wind_ftmin <- env$wind_mph * MPH_TO_FTMIN

  # Surface fire at the input wind
  surf <- if (no_dead_fuel) {
    list(ros_ft_min = 0, I_R = 0, I_B_kw = 0, flame_ft = 0, hpa = 0)
  } else {
    roth_core(
      load_lbft2, sav_use, mf, delta_ft, mx_dead_pct/100,
      waf * wind_ftmin, slope_frac
    )
  }

  surface <- list(
    ros_ch_hr = surf$ros_ft_min * FTMIN_TO_CHHR,
    ros_m_min = surf$ros_ft_min * FTMIN_TO_MMIN,
    rxn_int   = surf$I_R,
    fli_kw_m  = surf$I_B_kw,
    flame_ft  = surf$flame_ft,
    flame_m   = surf$flame_ft * FT_TO_M,
    hpa       = surf$hpa
  )

  # No canopy - no trees measured (maximum tree height, tree count or stems
  # per acre of 0) - means no torching or crowning, whatever CBH or cover the
  # scan reports: the fire type is surface fire.
  if (any(c(gv("MaxTH"), gv("TreesN"), gv("StemsPacre")) %in% 0)) {
    return(c(surface, NO_CANOPY))
  }

  # Canopy terms. Per-scan by default; a submitted bed may override them when
  # the user edited canopy values in the Fuel tool.
  cbh_m <- gv("CBH")
  cbd <- gv("LF_CBD")/100 # data stored as kg/m^3 x100
  if (!is.null(bed)) {
    if (!is.null(bed$cbh_m) && !is.na(bed$cbh_m)) cbh_m <- bed$cbh_m
    if (!is.null(bed$cbd) && !is.na(bed$cbd)) cbd <- bed$cbd
  }
  fmc <- env$fmc # foliar moisture content (%)

  # Van Wagner critical surface intensity for crown initiation (kW/m)
  I_o <- if (!is.na(cbh_m) && cbh_m > 0) {
    (0.010 * cbh_m * (460 + 25.9 * fmc)) ^ 1.5
  } else {
    NA_real_
  }

  # Critical crown spread rate for active crowning (m/min)
  R_o <- if (!is.na(cbd) && cbd > 0) 3.0/cbd else NA_real_

  # Rothermel (1991) crown spread rate (m/min): 3.34 x FM10 ROS at crown wind
  # exposure (0.4 x 20-ft wind).
  mf5 <- c(env$m1, env$m10, env$m100, env$m_herb, env$m_woody)/100 # FM10's classes
  crown_fm10_ros <- fm10_ros_ft_min(mf5, env$mx_dead/100, 0.4 * wind_ftmin, slope_frac)
  crown_ros_m <- 3.34 * crown_fm10_ros * FTMIN_TO_MMIN

  # Fire type: 0 surface, 1 passive (torching), 2 active crown
  fire_type <- 0
  if (!is.na(I_o) && surf$I_B_kw >= I_o) {
    fire_type <- if (!is.na(R_o) && crown_ros_m >= R_o) 2 else 1
  }

  # Torching index: 20-ft wind (mph) where surface I_B == I_o (never, with no
  # surface fire)
  torching <- NA_real_
  if (!is.na(I_o) && !no_dead_fuel) {
    fI <- function(w_mph) {
      roth_core(
        load_lbft2, sav_use, mf, delta_ft, mx_dead_pct/100,
        waf * w_mph * MPH_TO_FTMIN, slope_frac
      )$I_B_kw - I_o
    }
    torching <- solve_wind(fI)
  }

  # Crowning index: 20-ft wind (mph) where crown ROS == R_o
  crowning <- NA_real_
  if (!is.na(R_o)) {
    fR <- function(w_mph) {
      3.34 * (fm10_ros_ft_min(
        mf5, mx_dead_pct/100,
        0.4 * w_mph * MPH_TO_FTMIN, slope_frac
      ) *
        FTMIN_TO_MMIN) - R_o
    }
    crowning <- solve_wind(fR)
  }

  c(surface, list(
    crown_Io      = I_o,
    crown_Ro      = R_o,
    torching_idx  = torching,
    crowning_idx  = crowning,
    fire_type_num = fire_type
  ))
}

# Find the 20-ft wind (mph) at which f(wind) crosses zero, monotonic increasing.
# Returns 0 if already >= 0 at no wind, NA if never reached within 0-100 mph.
solve_wind <- function(f, lo = 0.01, hi = 100) {
  f_lo <- tryCatch(f(lo), error = function(e) NA_real_)
  f_hi <- tryCatch(f(hi), error = function(e) NA_real_)
  if (is.na(f_lo) || is.na(f_hi)) {
    return(NA_real_)
  }
  if (f_lo >= 0) {
    return(0)
  } # threshold met even with ~no wind
  if (f_hi < 0) {
    return(NA_real_)
  } # not reached within range
  tryCatch(
    uniroot(f, lower = lo, upper = hi)$root,
    error = function(e) NA_real_
  )
}

#' Compute per-scan fire behavior for every scan in the metrics table.
#'
#' @param metrics_dt      state$metrics()
#' @param models_wide_dt  state$additional_models_wide()
#' @param env             list of sidebar settings (see scan_fire_row)
#' @return data.table: site_name|plot|date_code|scanner_id + fire metric cols
#' @export
scan_fire_behavior <- function(metrics_dt, models_wide_dt, env) {
  if (nrow(metrics_dt) == 0) {
    return(data.table())
  }

  key <- c("site", "plot", "date", "scanner_id")
  # Bring in the model columns (fuel loads, depth) if present
  m <- merge_scan_models(metrics_dt, models_wide_dt)

  rows <- lapply(seq_len(nrow(m)), function(i) {
    fb <- scan_fire_row(as.list(m[i]), env)
    c(as.list(m[i, key, with = FALSE]), fb)
  })

  rbindlist(rows, use.names = TRUE, fill = TRUE)
}
