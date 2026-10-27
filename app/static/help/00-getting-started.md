# Getting started

The IntELiMon Decision Support Tool provides access to data from the
**Interagency Ecosystem Lidar Monitoring Program (IntELiMon)**. Its purpose is
to translate the complex structural data produced by terrestrial laser
scanning (TLS) into actionable intelligence: metrics, graphs and model inputs
that support treatment planning, the evaluation of treatment effects and fire
behavior modeling. Beyond visualizing data, the tool provides pathways to
deeper analysis and to integration with other tools, including landscape
files for fire modeling, treelists for forest growth simulation and fire
behavior calculations for tracking change and treatment success.

<p class="help-warning"><strong>The fire models in the rothRmel tab should be
used for change tracking and treatment success purposes only. These models
have not been verified for use with custom fuel beds generated from
TLS.</strong></p>

## Rationale for TLS monitoring

Long-term monitoring records the outcomes of management actions, measures
progress toward objectives and indicates which long-term goals are attainable.
Conventional field methods rely on trained crews and rigorous protocols, and
their data quality and repeatability are frequently limited (Murphy et al.,
2024). TLS complements these methods by capturing the three-dimensional
structure of a plot at high resolution. A portable, push-button scanner,
calibrated with initial transect sampling, records forestry, fuels and
ecological features in under five minutes per plot. Because every scan is
collected and processed with the same protocol, the resulting data, terms and
methods are consistent across sites, agencies and jurisdictions.

IntELiMon processes each scan into hundreds of forestry, fuels and ecological
metrics. The Decision Support Tool brings these metrics together for selected
plots, places scans in time relative to treatments, and derives trends, fuel
loadings, stand data and fire behavior estimates without direct handling of
point clouds.

## Typical workflow

1. **Load My Data** _(local installations only)_. Loading of IntELiMon output
   files from a folder on your own computer, so data never leave it (for
   example, for tribal data sovereignty). Running IntELiMon locally on raw
   point clouds will be added here.
2. **Selection Map.** Plot selection and download of scan data (online
   version pulls data from the IntELiMon API, local versions install data
   from the API and provided local directory).
3. **Set Treatments.** Entry of treatment dates and editing management units,
   which separate pre- and post-treatment scans and allow users to group
   scans/plots by management unit.
4. **Standard outputs.** Core structural metrics by plot and over time. These
   outputs are automatically calculated in all raw TLS scans by IntELiMon and
   provide out-of-the-box utility to all scans.
5. **Custom models.** Comparison of field-calibrated predictive model
   outputs. These are site-level predictive models created by users or
   analysts for specific site-level predictions.
6. **Fuels exports.** Review of scanned fuels, landscape files for fire
   modeling and submission of fuels to rothRmel. Canopy fuel metrics are
   derived from scans which can be used to create GeoTIFF or LCP files for
   external fire modeling or custom editing of 3-dimensional physics-based
   fire models.
7. **Forestry exports.** Stand metrics, thinning prescriptions and export to
   the Forest Vegetation Simulator (FVS).
8. **rothRmel.** Surface and crown fire behavior estimates for each scan over
   time using Rothermel (1972, 1991) and Van Wagner (1977) formulae. This tab
   is for evaluating change in potential fire behavior through time. These
   Rothermel-based calculations are not validated for planning, rather
   reporting potential treatment success or change over time.
9. **Report builder.** Data and figure outputs from previous tabs can be used
   to generate customizable reports for users to communicate management
   relevance.

## Notes

- Loaded data persist only for the current session. Reloading the page or
  navigating away clears them, so downloads and exports should be completed
  beforehand.
- The help pages are searchable from the box above the topic list.

## Contact

Questions, problems and suggestions: <spokswinski@newmexicoconsortium.org>

## References

Murphy, M. C., Loudermilk, E. L., Pokswinski, S., et al. (2024). Terrestrial
3D laser scanning for ecosystem and fire effects monitoring. Gen. Tech. Rep.
SRS-277. Asheville, NC: U.S. Department of Agriculture, Forest Service,
Southern Research Station. 19 p. <https://doi.org/10.2737/SRS-GTR-277>

Rothermel, R. C. (1972). A mathematical model for predicting fire spread in
wildland fuels. Res. Pap. INT-115. Ogden, UT: U.S. Department of Agriculture,
Forest Service, Intermountain Forest and Range Experiment Station. 40 p.

Rothermel, R. C. (1991). Predicting behavior and size of crown fires in the
Northern Rocky Mountains. Res. Pap. INT-438. Ogden, UT: U.S. Department of
Agriculture, Forest Service, Intermountain Research Station. 46 p.

Van Wagner, C. E. (1977). Conditions for the start and spread of crown fire.
*Canadian Journal of Forest Research*, 7(1), 23-34.
<https://doi.org/10.1139/x77-004>
