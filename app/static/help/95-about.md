# About

## IntELiMon

The Interagency Ecosystem Lidar Monitoring Program (IntELiMon) is a framework
for monitoring forests, shrublands and grasslands with terrestrial laser
scanning (TLS). A portable lidar scanner records the three-dimensional
structure of a plot in under five minutes, and an automated pipeline converts
each scan into standardized forestry, fuels, ecological and fire metrics.
Because every plot is scanned and processed with the same protocol, results
are comparable across sites, agencies and years, and before and after
treatments such as prescribed fire or thinning (Murphy et al., 2024).

The IntELiMon Decision Support Tool is the dashboard for these results. It
retrieves processed metrics from the IntELiMon API or from local files,
groups scans into time steps around treatment dates, and derives graphs, fuel
loadings, landscape files and fire behavior estimates from them.

Project website: [intelimon.xyz](https://intelimon.xyz)

## Field data collection

Each plot is recorded with **a single scan from plot center**, taken with a
Leica BLK360 mounted on a tripod approximately 1.5 m above the ground. A
reflective target on a pole approximately 12 m north of plot center records
the orientation of the scan. Scanning requires less than five minutes.

Scans are paired with transect sampling, which is used to calibrate and
validate the models that predict fuels and vegetation from the point cloud:

| Measurement | Method |
|---|---|
| Plot | 10 m radius, with two perpendicular 20 m transects through plot center (N-S and E-W) |
| Ground cover | Point intercept at 1 m intervals, 40 points per plot (each point = 2.5% cover) |
| Woody debris | Planar intercept tallies of 1, 10, 100 and 1000 hour fuels along the transects |
| Fuel bed, litter and duff depth | Four points, 4.5 m from plot center on each transect arm |
| Overstory | Trees of 10 cm DBH and larger, tallied by species in four quadrants |

Transect sampling requires approximately 30 to 60 minutes per plot. The full
protocol is described in Pokswinski et al. (2021).

## Processing and analysis

Scans are named by site, plot, date and scanner, checked for completeness,
and transferred to the USGS Earth Resources Observation and Science (EROS)
Center, where the processing pipeline runs (Pokswinski et al., 2026). The
pipeline performs the following steps for each scan:

1. **Point cloud preparation.** The cloud is cropped to a 15 m radius around
   the scanner, ground points are classified, noise is removed and heights
   are normalized to height above ground.
2. **Structure by height stratum.** Vegetation volume and leaf area are
   calculated for four strata: ground cover (0-1 m), understory (1-3 m),
   midstory (3-9 m) and overstory (above 9 m).
3. **Occlusion analysis.** Empty space is distinguished from space hidden
   behind vegetation, so that occluded areas are not interpreted as open
   canopy.
4. **Tree inventory.** Stems are detected and fitted to estimate DBH and
   height. Plot basal area, stems per acre and tree counts are corrected for
   trees obscured from the scanner.
5. **Canopy description.** Canopy base height, canopy cover and gap fraction
   are calculated.
6. **Surface fuel classification.** Shrubs, fine fuels and fine and coarse
   woody debris are classified.
7. **Predictive modeling.** Models trained on paired field and TLS data
   estimate quantities such as fuel cover, time-lag fuel counts, fuel and duff
   depths and hardwood and pine basal area. These outputs appear in the
   **Custom models** tab.

## Data access

Processed results are available through an online viewer and a programmatic
API; the Decision Support Tool uses the API. Related resources include
LANDFIRE layers queried by plot footprint, integration with FastFuels and
BurnPro3D for fire and fuel modeling, and **Points2Pano** panoramas of each
plot for comparison before and after treatment. IntELiMon open data are
released under the CC0-1.0 license.

## Supported by

- U.S. Geological Survey (USGS)
- U.S. Fish & Wildlife Service
- USDA Forest Service
- Bureau of Indian Affairs
- National Park Service
- SERDP / ESTCP

## Version

{{APP_VERSION}}

## References

Works cited in these help pages and in the tool's calculations.

Anderson, H. E. (1982). Aids to determining fuel models for estimating fire
behavior. Gen. Tech. Rep. INT-122. Ogden, UT: U.S. Department of Agriculture,
Forest Service, Intermountain Forest and Range Experiment Station. 22 p.
<https://doi.org/10.2737/INT-GTR-122>

Andrews, P. L. (2012). Modeling wind adjustment factor and midflame wind
speed for Rothermel's surface fire spread model. Gen. Tech. Rep.
RMRS-GTR-266. Fort Collins, CO: U.S. Department of Agriculture, Forest
Service, Rocky Mountain Research Station.

Andrews, P. L. (2018). The Rothermel surface fire spread model and associated
developments: a comprehensive explanation. Gen. Tech. Rep. RMRS-GTR-371. Fort
Collins, CO: U.S. Department of Agriculture, Forest Service, Rocky Mountain
Research Station. 121 p. <https://doi.org/10.2737/RMRS-GTR-371>

Avery, T. E., & Burkhart, H. E. (2002). *Forest measurements* (5th ed.).
New York: McGraw-Hill.

Bailey, R. L., & Dell, T. R. (1973). Quantifying diameter distributions with
the Weibull function. *Forest Science*, 19(2), 97-104.

Brown, J. K. (1974). Handbook for inventorying downed woody material. Gen.
Tech. Rep. INT-16. Ogden, UT: U.S. Department of Agriculture, Forest Service,
Intermountain Forest and Range Experiment Station. 24 p.

Byram, G. M. (1959). Combustion of forest fuels. In K. P. Davis (Ed.),
*Forest fire: control and use* (pp. 61-89). New York: McGraw-Hill.

Curtis, R. O. (1982). A simple index of stand density for Douglas-fir.
*Forest Science*, 28(1), 92-94.

Curtis, R. O., & Marshall, D. D. (2000). Why quadratic mean diameter?
*Western Journal of Applied Forestry*, 15(3), 137-139.

Dixon, G. E. (comp.) (2002). Essential FVS: a user's guide to the Forest
Vegetation Simulator. Internal Report. Fort Collins, CO: U.S. Department of
Agriculture, Forest Service, Forest Management Service Center. 226 p.

Finney, M. A. (1998). FARSITE: Fire Area Simulator, model development and
evaluation. Res. Pap. RMRS-RP-4. Ogden, UT: U.S. Department of Agriculture,
Forest Service, Rocky Mountain Research Station.

Finney, M. A. (2006). An overview of FlamMap fire modeling capabilities.
In *Fuels management: how to measure success* (pp. 213-220). Proc.
RMRS-P-41. Fort Collins, CO: U.S. Department of Agriculture, Forest
Service, Rocky Mountain Research Station.

Jennings, S. B., Brown, N. D., & Sheil, D. (1999). Assessing forest
canopies and understorey illumination: canopy closure, canopy cover and
other measures. *Forestry*, 72(1), 59-74.

Murphy, M. C., Loudermilk, E. L., Pokswinski, S., et al. (2024). Terrestrial
3D laser scanning for ecosystem and fire effects monitoring. Gen. Tech. Rep.
SRS-277. Asheville, NC: U.S. Department of Agriculture, Forest Service,
Southern Research Station. 19 p. <https://doi.org/10.2737/SRS-GTR-277>

National Wildfire Coordinating Group (NWCG). NWCG Glossary of Wildland
Fire, PMS 205. <https://www.nwcg.gov/publications/pms205> (accessed
2026-10-16).

Neyman, J., & Scott, E. L. (1958). Statistical approach to problems of
cosmology. *Journal of the Royal Statistical Society: Series B*, 20(1), 1-43.

Ottmar, R. D., Sandberg, D. V., Riccardi, C. L., & Prichard, S. J.
(2007). An overview of the Fuel Characteristic Classification System:
quantifying, classifying, and creating fuelbeds for resource planning.
*Canadian Journal of Forest Research*, 37(12), 2383-2393.

Pokswinski, S., Gallagher, M. R., Skowronski, N. S., et al. (2021). A
simplified and affordable approach to forest monitoring using single
terrestrial laser scans and transect sampling. *MethodsX*, 8, 101484.
<https://doi.org/10.1016/j.mex.2021.101484>

Pokswinski, S., Nelson, K., Maxwell, A., et al. (2026). IntELiMon: an
automated framework for standardized terrestrial lidar processing in
multi-disciplinary ecosystem monitoring. *Forestry: An International Journal
of Forest Research*, 99(5), cpag083.
<https://doi.org/10.1093/forestry/cpag083>

Reineke, L. H. (1933). Perfecting a stand-density index for even-aged
forests. *Journal of Agricultural Research*, 46(7), 627-638.

Reinhardt, E. D., & Crookston, N. L. (Tech. Eds.) (2003). The Fire and Fuels
Extension to the Forest Vegetation Simulator. Gen. Tech. Rep. RMRS-GTR-116.
Ogden, UT: U.S. Department of Agriculture, Forest Service, Rocky Mountain
Research Station. 209 p.

Rollins, M. G. (2009). LANDFIRE: a nationally consistent vegetation,
wildland fire, and fuel assessment. *International Journal of Wildland
Fire*, 18(3), 235-249.

Rothermel, R. C. (1972). A mathematical model for predicting fire spread in
wildland fuels. Res. Pap. INT-115. Ogden, UT: U.S. Department of Agriculture,
Forest Service, Intermountain Forest and Range Experiment Station. 40 p.

Rothermel, R. C. (1991). Predicting behavior and size of crown fires in the
Northern Rocky Mountains. Res. Pap. INT-438. Ogden, UT: U.S. Department of
Agriculture, Forest Service, Intermountain Research Station. 46 p.

Scott, J. H., & Burgan, R. E. (2005). Standard fire behavior fuel models: a
comprehensive set for use with Rothermel's surface fire spread model. Gen.
Tech. Rep. RMRS-GTR-153. Fort Collins, CO: U.S. Department of Agriculture,
Forest Service, Rocky Mountain Research Station. 72 p.
<https://doi.org/10.2737/RMRS-GTR-153>

Scott, J. H., & Reinhardt, E. D. (2001). Assessing crown fire potential by
linking models of surface and crown fire behavior. Res. Pap. RMRS-RP-29. Fort
Collins, CO: U.S. Department of Agriculture, Forest Service, Rocky Mountain
Research Station. 59 p. <https://doi.org/10.2737/RMRS-RP-29>

Van Wagner, C. E. (1968). The line intersect method in forest fuel
sampling. *Forest Science*, 14(1), 20-26.

Van Wagner, C. E. (1977). Conditions for the start and spread of crown fire.
*Canadian Journal of Forest Research*, 7(1), 23-34.
<https://doi.org/10.1139/x77-004>

Watson, D. J. (1947). Comparative physiological studies on the growth of
field crops: I. Variation in net assimilation rate and leaf area between
species and varieties, and within and between years. *Annals of Botany*,
11(1), 41-76.

## Contact

Questions, problems and suggestions: <spokswinski@newmexicoconsortium.org>
