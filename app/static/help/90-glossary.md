# Glossary

Terms, acronyms and metric names used across the app and its reports. Fire
and fuels definitions in quotation marks are from the NWCG Glossary of
Wildland Fire, a U.S. government publication. Other definitions are written
for this page from the references named in brackets, listed in full at
the end. The code in brackets after a metric name, such as (MDBH), is the
column name in IntELiMon output files and downloads.

Use the search box above the topic list to find a term.

## Acronyms and abbreviations

| Abbreviation | Meaning |
|---|---|
| AOI | Area of interest |
| API | Application programming interface: the service the app downloads IntELiMon data from |
| BA | Basal area |
| BTU | British thermal unit, a unit of heat (about 1,055 joules) |
| CBD | Canopy bulk density |
| CBH | Canopy base height |
| CC | Canopy cover |
| CI | Crowning index |
| CR | Crown ratio |
| CSV | Comma-separated values, a plain-text table file |
| DBH | Diameter at breast height |
| EROS | USGS Earth Resources Observation and Science Center, where scans are processed |
| FBFM, FBFM13, FBFM40 | Fire behavior fuel model; the Anderson 13 and Scott and Burgan 40 sets |
| FCCS | Fuel Characteristic Classification System |
| FFE | Fire and Fuels Extension to FVS |
| FMC | Foliar moisture content |
| FVS | Forest Vegetation Simulator |
| I₀ | Crown-initiation intensity |
| IFTDSS | Interagency Fuel Treatment Decision Support System |
| IntELiMon | Interagency Ecosystem Lidar Monitoring Program |
| LAI | Leaf area index; OLAI, MLAI and ULAI for the overstory, midstory and understory |
| LCP | Landscape file for FlamMap and FARSITE |
| LF | LANDFIRE, as in the LF_FBFM40 and LF_CBD columns |
| QA/QC | Quality assurance and quality control |
| QMD | Quadratic mean diameter |
| R₀ | Critical spread rate for active crown fire |
| RD | Relative density |
| ROS | Rate of spread |
| SAV | Surface-area-to-volume ratio |
| SD | Standard deviation |
| SDI | Stand density index |
| SE | Standard error |
| TI | Torching index |
| TLS | Terrestrial laser scanning |
| TPA | Trees per acre (stems per acre) |
| USGS | U.S. Geological Survey |
| WAF | Wind adjustment factor |

## A

**Active crown fire**: "A fire in which a solid flame develops in the crowns
of trees, but the surface and crown phases advance as a linked unit dependent
on each other." [NWCG] In rothRmel, fire type 2: surface fire intensity
reaches the crown-initiation intensity and the crown spread rate reaches the
critical rate R₀ (Van Wagner, 1977).

**Aerial fuels**: "Standing and supported live and dead combustibles not in
direct contact with the ground and consisting mainly of foliage, twigs,
branches, stems, cones, bark, and vines." [NWCG]

**Area of interest (AOI)**: An area drawn or set by the user to limit an
analysis or export, such as the rectangle that widens the fuel raster on
Fuels exports or the simulated area on Forestry exports.

**Assignment rule**: On Forestry exports, the rule that gives the entered
species to the detected stems: at random in the ratio entered, by size class,
or in spatial clusters. Species are not measured by the scanner.

## B

**Bare ground**: The share of a plot with no vegetation or litter cover,
predicted by a site's custom model (BGmod).

**Basal area (Basalarea)**: The cross-sectional area of tree stems measured
at breast height, summed over a stand and expressed per unit ground area
(ft²/acre or m²/ha). A common measure of stand density. [Avery and Burkhart,
2002]

**Box and whisker plot (box plot)**: A graph summarizing a set of values by
its median, its lower and upper quartiles (the box) and its more extreme
values (the whiskers). [Wiktionary] In the app, whiskers reach the furthest
values within 1.5 times the box's height, and each scan is drawn as a point.

**Brown's equations (planar intersect method)**: A way of estimating the
weight of downed woody fuel from counts of pieces crossing a sampling plane
along a transect, by size class. [Brown, 1974; Van Wagner, 1968]

**Bulk density**: "Weight per unit volume. For fuels, this is usually
expressed as pounds per cubic foot." [NWCG] See *canopy bulk density*.

## C

**Calibration (model)**: Adjusting or fitting a model by comparison with a
standard, here field measurements collected with the scans. [Wiktionary,
WordNet] Custom models are calibrated with field data from their own site.

**Canopy**: The layer of a forest formed by the crowns of the tallest trees;
"the stratum containing the crowns of the tallest vegetation present (living
or dead), usually above 20 feet." [NWCG; Wiktionary]

**Canopy base height (CBH)**: The lowest height above the ground at which
there is enough canopy fuel to carry fire vertically into the canopy. [Scott
and Reinhardt, 2001] IntELiMon measures it from the scan's point cloud, in
meters.

**Canopy bulk density (CBD)**: The mass of available canopy fuel per unit
canopy volume (kg/m³). [Scott and Reinhardt, 2001] The app uses LANDFIRE's
value at each plot, stored as kg/m³ × 100.

**Canopy cover (canopyCover)**: The proportion of the ground covered by the
vertical projection of tree crowns. [Jennings et al., 1999] IntELiMon
reports it as a fraction of the plot (0 to 1); the app shows it as a
percent. Compare *crown cover*.

**Chain**: "Unit of measure in land survey, equal to 66 feet (20 M) (80 chains
equal 1 mile)." [NWCG] Rate of spread is given in chains per hour (ch/hr).

**Critical active-crown rate of spread (R₀)**: The crown fire spread rate
needed for an active crown fire, R₀ = 3.0 / CBD (m/min). [Van Wagner, 1977]

**Crown**: The upper part of a tree, with its branches and foliage.
[Wiktionary]

**Crown cover**: "The ground area covered by the crown of a tree as delimited
by the vertical projection of its outermost perimeter." [NWCG]

**Crown fire**: "A fire that advances from top to top of trees or shrubs more
or less independent of a surface fire." [NWCG] See *passive* and *active
crown fire*.

**Crown fire type**: In rothRmel, 0 for surface fire, 1 for passive crown
fire (torching) and 2 for active crown fire. [Van Wagner, 1977; Scott and
Reinhardt, 2001]

**Crown ratio (CR)**: "The ratio of live crown to tree height." [NWCG] The app
calculates each tree's crown ratio as (height − canopy base height) / height.

**Crown-initiation intensity (I₀)**: The surface fireline intensity needed to
ignite the canopy, from canopy base height and foliar moisture content
(kW/m). [Van Wagner, 1977]

**Crowning index (CI)**: The 20-ft wind speed at which an active crown fire
can be sustained. Higher values mean a lower crown fire hazard. [Scott and
Reinhardt, 2001]

**Cured (herbaceous fuel)**: Herbaceous plants that have dried and behave as
dead fuel. In Scott and Burgan (2005) dynamic fuel models, part of the live
herbaceous load is moved to dead fuel as herbaceous moisture drops.

**Custom model (predictive model)**: A site-level statistical model, trained
on field measurements paired with scans, that predicts a quantity the
scanner can't measure directly, such as grass cover or fuel bed depth. Its
values are predictions with model error.

## D

**Data type**: On the graph tabs, whether values are shown in the metric's own
units or as percent change from each plot's first scan.

**Dead fuels**: "Fuels with no living tissue in which moisture content is
governed almost entirely by absorption or evaporation of atmospheric
moisture." [NWCG]

**Detection probability**: The chance that the scanner detects a stem of a
given size. Small stems are more likely to be hidden. See *size bias*.

**Diameter at breast height (DBH)**: The diameter of a tree stem measured at
breast height, 4.5 ft (1.37 m) above the ground in the United States. [Avery
and Burkhart, 2002] Mean DBH (MDBH) is in inches.

**Duff**: "The layer of decomposing organic materials lying below the litter
layer of freshly fallen twigs, needles, and leaves and immediately above the
mineral soil." [NWCG] Mean duff depth (MDDmod) is predicted in centimeters.

**Dynamic fuel model**: A fuel model whose live herbaceous load is partly
transferred to dead fuel as it cures. [Scott and Burgan, 2005]

## E

**Error bars**: Lines on a graph showing the spread or precision of a mean.
[Wiktionary] In the app, ±1 SD or ±1 SE around each time step's mean.

## F

**FARSITE**: A fire growth simulation model that projects fire spread across
a landscape. [Finney, 1998] It uses LCP landscape files.

**FastFuels**: A U.S. Forest Service platform for three-dimensional fuels
data used in physics-based fire models. Its download button is not yet
available in the app.

**Fern**: A flowerless, seedless vascular plant with fronds that reproduces
by spores. [WordNet] Fern cover is predicted by some custom models (Fernmod).

**Fire and Fuels Extension (FFE)**: The FVS extension that simulates fuel
dynamics and potential fire behavior and effects. [Reinhardt and Crookston,
2003]

**Fire behavior**: "The manner in which a fire reacts to the influences of
fuel, weather, and topography." [NWCG]

**Fireline intensity**: "The rate of heat release per unit time per unit
length of fire front." [NWCG; Byram, 1959] Reported in kW/m.

**Flame length**: "The distance between the flame tip and the midpoint of the
flame depth at the base of the flame (generally the ground surface), an
indicator of fire intensity." [NWCG] Calculated from fireline intensity
after Byram (1959).

**FlamMap**: A fire behavior mapping and analysis program that calculates
potential fire behavior across a landscape. [Finney, 2006] It uses LCP
landscape files.

**Foliar moisture content (FMC)**: The moisture content of live canopy
foliage, as a percent of dry weight; used to calculate crown-initiation
intensity. [Van Wagner, 1977]

**Forb**: "A plant with an herbaceous (soft, rather than permanent woody)
stem, that is not a grass or grasslike plant." [NWCG]

**Forest Vegetation Simulator (FVS)**: The U.S. Forest Service forest growth
model that projects stand development from a tree list, with regional
variants. [Dixon, 2002]

**Fuel bed depth**: "Average height of surface fuels contained in the
combustion zone of a spreading fire front." [NWCG] Mean fuel bed depth
(MFBDmod) is predicted in centimeters.

**Fuel Characteristic Classification System (FCCS)**: A system that
describes wildland fuelbeds by their strata and fuel characteristics.
[Ottmar et al., 2007] LANDFIRE FCCS fuelbeds are added to the IFTDSS GeoTIFF.

**Fuel loading**: "The amount of fuel present expressed quantitatively in
terms of weight of fuel per unit area." [NWCG] The app reports it in tons
per acre.

**Fuel model**: "Simulated fuel complex for which all fuel descriptors
required for the solution of a mathematical rate of spread model have been
specified." [NWCG] The app uses the Anderson (1982) 13 and Scott and Burgan
(2005) 40 standard fire behavior fuel models.

**Fuel size class**: "A category used to describe the diameter of down dead
woody fuels." [NWCG] See *timelag fuels*.

**Fuel treatment**: "Manipulation or removal of fuels to reduce the
likelihood of ignition and/or to lessen potential damage and resistance to
control." [NWCG]

## G

**Gap fraction (gapFraction)**: The share of the plot open to the sky, 1 −
canopy cover. [Jennings et al., 1999]

**GeoTIFF**: An image file that stores map data together with its geographic
coordinates. The fuel raster export writes one for IFTDSS.

**Graminoid**: A grass or grasslike plant, such as a sedge or rush.
[Wiktionary] Grass cover is predicted by some custom models (Grassmod).

**Ground cover volume (mGCvol)**: Vegetation volume from 0 to 1 m above the
ground, from the scan.

**Ground fuel**: "All combustible materials below the surface litter,
including duff, tree or shrub roots, punky wood, peat, and sawdust." [NWCG]

## H

**Heat per unit area**: "Total amount of heat released per unit area as the
flaming front of the fire passes, expressed as Btu/square foot." [NWCG]

**Herbaceous**: Of a non-woody plant or plant part. [WordNet] Live
herbaceous fuels are grasses and forbs.

## I

**IFTDSS (Interagency Fuel Treatment Decision Support System)**: A
web-based system for planning and analyzing fuel treatments, which accepts
custom landscapes as GeoTIFFs.

**IntELiMon (Interagency Ecosystem Lidar Monitoring Program)**: The program
that collects single TLS scans at monitoring plots and processes them into
standardized forestry, fuels and ecological metrics. [Murphy et al., 2024;
Pokswinski et al., 2026]

## L

**Ladder fuels**: "Fuels which provide vertical continuity between strata,
thereby allowing fire to carry from surface fuels into the crowns of trees or
shrubs with relative ease." [NWCG]

**LANDFIRE**: A national program producing consistent maps of vegetation,
fuels and fire regimes for the United States. [Rollins, 2009] The app uses
its fuel models, canopy bulk density and landscape layers.

**Leaf area index (LAI)**: The one-sided green leaf area per unit of
horizontal ground area. [Watson, 1947] IntELiMon reports total LAI and LAI
for the overstory (above 9 m), midstory (3 to 9 m) and understory (1 to 3 m).

**Lidar**: A measuring system that locates objects like radar but uses laser
light. [WordNet; Wiktionary] See *terrestrial laser scanning*.

**Litter**: "The top layer of forest floor, composed of loose debris of dead
sticks, branches, twigs, and recently fallen leaves or needles; little
altered in structure by decomposition." [NWCG]

**Live fuels**: "Living plants, such as trees, grasses, and shrubs, in which
the seasonal moisture content cycle is controlled largely by internal
physiological mechanisms." [NWCG]

## M

**Management unit**: A named group of plots managed together, such as a burn
unit, assigned on Set Treatments.

**Mean**: The average of a set of values. [WordNet]

**Median**: The middle value of an ordered set of values, or the average of
the two middle values. [WordNet; Wiktionary]

**Midflame wind speed**: The wind at the middle of the flame height, used by
the Rothermel model: the 20-ft wind times the wind adjustment factor.
[Andrews, 2012]

**Midstory volume (mMSvol)**: Vegetation volume from 3 to 9 m above the
ground, from the scan.

**Mode**: The most frequent value in a set. In the app's statistics, values
are compared to 3 significant figures.

**Moisture of extinction**: "The fuel moisture content, weighed over all the
fuel classes, at which the fire will not spread." [NWCG]

## N

**n**: Sample size—the number of individual data points or observations
included in a sample.

**Neyman-Scott process**: A clustered random point pattern in which offspring
points are scattered around randomly placed parent points; used to place
simulated stems. [Neyman and Scott, 1958]

**Non-burnable fuel model**: A fuel model that carries no fire, such as
water, rock or urban areas. [Scott and Burgan, 2005]

## O

**Occlusion**: Blocking of the view of part of a scene by something in front
of it. [Wiktionary] In TLS, trunks and vegetation hide what lies behind them
from the scanner. See *unoccluded area*.

**Overstory**: The upper layer of a plant community. [Wiktionary] In
IntELiMon, vegetation above 9 m (overstory volume, mOSvol).

## P

**Packing ratio**: "The fraction of a fuel bed occupied by fuels, or the fuel
volume divided by bed volume." [NWCG]

**Passive crown fire (torching)**: "A fire in the crowns of trees in which
trees or groups of trees torch, ignited by the passing front of the fire."
[NWCG] In rothRmel, fire type 1.

**Percent change**: The change from each plot's first scan, as a percent of
that first value.

**Plot**: A fixed sampling location, scanned from its center. IntELiMon plots
have a 10 m radius for field sampling and are scanned to 15 m.

**Point cloud**: A set of points in three-dimensional space that together
describe the shape of objects; the raw output of a laser scan. [Wiktionary]

**Points2Pano**: A 360° panorama image made from a scan's point cloud, used
to view and check each plot.

**Prescribed fire**: "A wildland fire originating from a planned ignition in
accordance with applicable laws, policies, and regulations to meet specific
objectives." [NWCG]

**Prescription (forestry)**: On Forestry exports, a planned thinning: from
below, from above, by species or by spacing.

## Q

**Quadratic mean diameter (QMD)**: The diameter of the tree of average basal
area: the square root of the mean of the squared diameters. [Wiktionary;
Curtis and Marshall, 2000]

## R

**Rate of spread (ROS)**: "The relative activity of a fire in extending its
horizontal dimensions." [NWCG] rothRmel reports the forward spread rate of
the head of a surface fire, in chains per hour or m/min.

**Reaction intensity**: "The rate of heat release, per unit area of the
flaming fire front." [NWCG]

**Relative density (RD)**: A stand density measure equal to basal area
divided by the square root of quadratic mean diameter. [Curtis, 1982]

**Remeasurement**: Measuring again; in the app, the visit number of a scan:
0 for the first scan of a plot, 1 for its next scan and so on, however close
together the scans are. [Wiktionary]

**Residence time**: "The time, in seconds, required for the flaming front of
a fire to pass a stationary point at the surface of the fuel." [NWCG]

**Residual basal area**: The basal area left after a thinning; the target of
the thin from below and thin from above prescriptions.

**Rothermel model**: The surface fire spread model of Rothermel (1972), the
basis of most U.S. fire behavior systems. [Andrews, 2018]

## S

**Self-thinning**: Mortality from competition as a stand grows denser; the
app treats it as likely above 55% of maximum stand density index. [Reineke,
1933]

**Shrub**: "A woody perennial plant differing from a perennial herb by its
persistent and woody stem; and from a tree by its low stature and habit of
branching from the base." [NWCG]

**Site index**: The average height of the dominant trees of a stand at a
reference age, used to describe site productivity. [Avery and Burkhart,
2002] An input to FVS.

**Size bias**: The tendency of a single scan to miss more small stems than
large ones, so small diameter classes are under-counted.

**Slope**: "The rise or fall in terrain measured in feet per 100 feet of
horizontal distance measurement, expressed as a percentage." [NWCG]

**Stand**: A group of trees uniform enough in composition, structure and
site to be managed as a unit.

**Stand density index (SDI)**: A density measure that expresses the number of
trees per unit area as the equivalent number of trees with a 10-inch
quadratic mean diameter. [Reineke, 1933]

**Standard deviation (SD)**: A measure of how spread out values are around
their mean; the square root of the variance. [WordNet; Wiktionary]

**Standard error (SE)**: The standard deviation of an estimate, such as a
mean; for a mean, SD divided by the square root of the number of values. It
shows how precisely the mean is known.

**Stem map**: A map of the positions of the trees on a plot.

**Stems per acre (StemsPacre)**: The number of trees per acre.

**Stocking**: The ratio of the actual density of trees in an area to the
density that would make full use of the site. [Wiktionary] The app expresses
it as a share of a maximum stand density index of 450.

**Surface-area-to-volume ratio (SAV)**: The surface area of a fuel particle
divided by its volume (ft²/ft³); fine fuels have high values. [Andrews, 2018]

**Surface fire**: "Fire that burns loose debris on the surface, which
includes dead branches, leaves, and low vegetation." [NWCG]

**Surface fuel**: "Fuels lying on or near the surface of the ground,
consisting of leaf and needle litter, dead branch material, downed logs,
bark, tree cones, and low stature living plants." [NWCG]

## T

**Terrestrial laser scanning (TLS)**: Lidar scanning from a fixed position on
the ground, recording the three-dimensional structure around the scanner as
a point cloud. [Murphy et al., 2024]

**Thinning**: Removing trees to improve the growth of the ones left or to
change stand structure. [Wiktionary]

**Time series**: A series of values of a variable at successive times.
[WordNet]

**Time step**: In the app, a group of scans from one round of scanning. A new
time step starts at a treatment date, when a plot is scanned again or after
30 days without scans. Set by the Scan grouping column on the Set
Treatments tab, where it can be changed.

**Timelag**: "Time needed under specified conditions for a fuel particle to
lose about 63 percent of the difference between its initial moisture content
and its equilibrium moisture content." [NWCG]

**Timelag fuels (1-, 10-, 100-, 1000-hour)**: Dead fuels grouped by how fast
they respond to moisture, by diameter: 1-hour fuels are less than about
1/4 inch, 10-hour fuels 1/4 to 1 inch, 100-hour fuels 1 to 3 inches and
1000-hour fuels 3 to 8 inches. [NWCG; Brown, 1974] Custom models predict
their counts per 40 m of transect.

**Torching**: "The burning of the foliage of a single tree or a small group
of trees, from the bottom up." [NWCG]

**Torching index (TI)**: The 20-ft wind speed at which a surface fire would
ignite the canopy. Higher values mean a lower crown fire hazard. [Scott and
Reinhardt, 2001]

**Transect**: A line along which a researcher counts and records
observations. [Wiktionary] IntELiMon plots have two perpendicular 20 m
transects through plot center.

**Treatment date**: The date of a treatment such as a prescribed burn or
thinning, entered on Set Treatments with its treatment type. Scans after it
start a new time step.

**Treatment type**: What was done on a treatment date, picked on Set
Treatments: Prescribed fire, Thinning, Piling and burning, Mastication, Herbicide, Grazing, Planting and seeding, and Disking and plowing. The report builder uses it to describe the
treatments.

## U

**Understory**: The layer of plants growing beneath the forest canopy above
the forest floor. [Wiktionary] In IntELiMon, vegetation from 1 to 3 m
(understory volume, mUSvol).

**Unoccluded area (nonocarea)**: The part of a plot visible to the scanner,
in m². Dividing stem counts and basal area by it corrects them for trees
hidden from the scanner. [Pokswinski et al., 2026]

## W

**Weibull distribution**: A flexible probability distribution often used to
describe tree diameter distributions; the app fits one to the scanned stems
to simulate stem maps. [Bailey and Dell, 1973]

**Wind adjustment factor (WAF)**: The ratio of midflame wind speed to the
20-ft wind speed; lower under a closed canopy. [Andrews, 2012]

**20-ft wind speed**: "Wind, in miles per hour, measured at 20 feet above
ground, or above the average height of vegetation, and averaged over at
least a 10-minute period." [NWCG]

## References

- Anderson, H. E. (1982). Aids to determining fuel models for estimating fire
  behavior. Gen. Tech. Rep. INT-122. USDA Forest Service.
- Andrews, P. L. (2012). Modeling wind adjustment factor and midflame wind
  speed for Rothermel's surface fire spread model. Gen. Tech. Rep.
  RMRS-GTR-266. USDA Forest Service.
- Andrews, P. L. (2018). The Rothermel surface fire spread model and
  associated developments: a comprehensive explanation. Gen. Tech. Rep.
  RMRS-GTR-371. USDA Forest Service.
- Avery, T. E., & Burkhart, H. E. (2002). *Forest measurements* (5th ed.).
  McGraw-Hill.
- Bailey, R. L., & Dell, T. R. (1973). Quantifying diameter distributions
  with the Weibull function. *Forest Science*, 19(2), 97-104.
- Brown, J. K. (1974). Handbook for inventorying downed woody material. Gen.
  Tech. Rep. INT-16. USDA Forest Service.
- Byram, G. M. (1959). Combustion of forest fuels. In K. P. Davis (Ed.),
  *Forest fire: control and use* (pp. 61-89). McGraw-Hill.
- Curtis, R. O. (1982). A simple index of stand density for Douglas-fir.
  *Forest Science*, 28(1), 92-94.
- Curtis, R. O., & Marshall, D. D. (2000). Why quadratic mean diameter?
  *Western Journal of Applied Forestry*, 15(3), 137-139.
- Dixon, G. E. (comp.) (2002). Essential FVS: a user's guide to the Forest
  Vegetation Simulator. Internal Report. USDA Forest Service, Forest
  Management Service Center.
- Finney, M. A. (1998). FARSITE: Fire Area Simulator, model development and
  evaluation. Res. Pap. RMRS-RP-4. USDA Forest Service.
- Finney, M. A. (2006). An overview of FlamMap fire modeling capabilities. In
  *Fuels management: how to measure success* (pp. 213-220). Proc.
  RMRS-P-41. USDA Forest Service.
- Jennings, S. B., Brown, N. D., & Sheil, D. (1999). Assessing forest
  canopies and understorey illumination: canopy closure, canopy cover and
  other measures. *Forestry*, 72(1), 59-74.
- Murphy, M. C., Loudermilk, E. L., Pokswinski, S., et al. (2024).
  Terrestrial 3D laser scanning for ecosystem and fire effects monitoring.
  Gen. Tech. Rep. SRS-277. USDA Forest Service.
- National Wildfire Coordinating Group (NWCG). NWCG Glossary of Wildland
  Fire, PMS 205. https://www.nwcg.gov/publications/pms205 (accessed
  2026-10-16).
- Neyman, J., & Scott, E. L. (1958). Statistical approach to problems of
  cosmology. *Journal of the Royal Statistical Society: Series B*, 20(1),
  1-43.
- Ottmar, R. D., Sandberg, D. V., Riccardi, C. L., & Prichard, S. J. (2007).
  An overview of the Fuel Characteristic Classification System:
  quantifying, classifying, and creating fuelbeds for resource planning.
  *Canadian Journal of Forest Research*, 37(12), 2383-2393.
- Pokswinski, S., Nelson, K., Maxwell, A., et al. (2026). IntELiMon: an
  automated framework for standardized terrestrial lidar processing in
  multi-disciplinary ecosystem monitoring. *Forestry*, 99(5), cpag083.
- Reineke, L. H. (1933). Perfecting a stand-density index for even-aged
  forests. *Journal of Agricultural Research*, 46(7), 627-638.
- Reinhardt, E. D., & Crookston, N. L. (Tech. Eds.) (2003). The Fire and
  Fuels Extension to the Forest Vegetation Simulator. Gen. Tech. Rep.
  RMRS-GTR-116. USDA Forest Service.
- Rollins, M. G. (2009). LANDFIRE: a nationally consistent vegetation,
  wildland fire, and fuel assessment. *International Journal of Wildland
  Fire*, 18(3), 235-249.
- Rothermel, R. C. (1972). A mathematical model for predicting fire spread in
  wildland fuels. Res. Pap. INT-115. USDA Forest Service.
- Scott, J. H., & Burgan, R. E. (2005). Standard fire behavior fuel models: a
  comprehensive set for use with Rothermel's surface fire spread model. Gen.
  Tech. Rep. RMRS-GTR-153. USDA Forest Service.
- Scott, J. H., & Reinhardt, E. D. (2001). Assessing crown fire potential by
  linking models of surface and crown fire behavior. Res. Pap. RMRS-RP-29.
  USDA Forest Service.
- Van Wagner, C. E. (1968). The line intersect method in forest fuel
  sampling. *Forest Science*, 14(1), 20-26.
- Van Wagner, C. E. (1977). Conditions for the start and spread of crown
  fire. *Canadian Journal of Forest Research*, 7(1), 23-34.
- Watson, D. J. (1947). Comparative physiological studies on the growth of
  field crops: I. Variation in net assimilation rate and leaf area between
  species and varieties, and within and between years. *Annals of Botany*,
  11(1), 41-76.
- Wiktionary, the free dictionary. https://en.wiktionary.org (accessed
  2026-10-16).
- WordNet 3.0. Princeton University (2006), via dict.org (accessed
  2026-10-16).
