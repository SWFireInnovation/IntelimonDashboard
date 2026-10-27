# rothRmel

<p class="help-warning"><strong>The fire models in the rothRmel tab should be
used for change tracking and treatment success purposes only. These models
have not been verified for use with custom fuel beds generated from TLS, and
the Rothermel-based calculations are not validated for planning. The fuels
behind them are predictions from site-level models, so the results inherit
those models' uncertainty. Use them to compare potential fire behavior through
time at the same plots under the same weather, and confirm important decisions
with field observations and validated fire behavior tools.
Refer to the Points2Pano image for QA/QC and raise concerns with a data
analyst when results seem unreliable.</strong></p>

## What this tab is for

rothRmel estimates potential surface and crown fire behavior for every loaded
scan, using the Rothermel (1972) surface fire spread model and the Van Wagner
(1977) crown fire model. Because each scan carries its own surface fuels and canopy,
the results show how potential fire behavior changes through time, for
example before and after a prescribed burn or a thinning. This makes the tab
a way to report treatment success: whether a treatment lowered spread rate,
intensity, flame length or the chance of crown fire.

The weather and fuel moisture you enter in the left panel are held the same
for every scan, so the differences between time steps come from the fuels and
canopy measured at each plot.

Three graph cards each show one fire behavior metric. A fourth card shows the
Points2Pano panorama of the scans. This allows a user to view the results in
the context of the scan and provides a QA/QC assessment of the scans. The
settings in the left panel apply to all three graphs.

These graphs use data from the scans downloaded on the **Selection Map**, the
treatment dates entered on **Set Treatments** and, if you choose, the fuel
loadings submitted from **Fuels exports**.

## The screen at a glance

Move the mouse over a numbered marker, or press Tab to step through them, to
see what each part does.

<div class="help-shot"><img src="static/help/images/rothrmel-overview.png" alt="The rothRmel tab: fire behavior inputs on the left, three fire behavior graphs and the Points2Pano viewer on the right" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:9.9%">1<span class="help-tip"><b>Surface fuel source.</b> Each scan's own fuels (Scan level fuels) or the loadings submitted from Fuels exports (Fuel tool values).</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:21.6%;top:17.9%">2<span class="help-tip"><b>Fuel source note.</b> Where the surface fuels come from, or what was submitted.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:28%">3<span class="help-tip"><b>Plot type.</b> How the graphs draw the data: time series, one line per plot, box and whisker, or bars.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:35.4%">4<span class="help-tip"><b>Data type.</b> Values in the metric's own units, or percent change from each plot's first scan.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:20%;top:42.5%">5<span class="help-tip"><b>Treatment date lines.</b> Shows or hides the red lines at the treatment dates.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:21.3%;top:49.1%">6<span class="help-tip"><b>Error bars.</b> SD, SE or Off.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:58.3%">7<span class="help-tip"><b>Card 1 metric.</b> The fire behavior metric for the upper left graph.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:65.7%">8<span class="help-tip"><b>Card 2 metric.</b> The metric for the upper right graph.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:73%">9<span class="help-tip"><b>Card 3 metric.</b> The metric for the lower left graph.</span></span>
<span class="help-spot tip-right tip-up" tabindex="0" style="left:18.75%;top:79.4%">10<span class="help-tip"><b>Wind &amp; slope.</b> The first of the weather and fuel moisture inputs. Scroll the panel for the rest.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:31.25%;top:5.7%">11<span class="help-tip"><b>Card 1 graph.</b> Here, surface rate of spread.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:66.25%;top:5.7%">12<span class="help-tip"><b>Card 2 graph.</b> Here, surface fireline intensity.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:35%;top:50.1%">13<span class="help-tip"><b>Card 3 graph.</b> Here, the torching index.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:54.1%;top:21%">14<span class="help-tip"><b>Treatment line.</b> A treatment date from the Set Treatments tab.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.5%;top:49.7%">15<span class="help-tip"><b>Points2Pano viewer.</b> The panorama of a selected scan, with its site, plot, date and scanner. Step through the scans with ◀ and ▶; in a narrow card the label is shortened with "…".</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:86.8%;top:87.4%">16<span class="help-tip"><b>+ Report data.</b> In the lower right of the panorama: adds a photo of the plot showing to the report.</span></span>
</div>

1. **Surface fuel source**: scan level fuels or fuel tool values.
2. **Fuel source note**: where the fuels come from.
3. **Plot type**: how the graphs draw the data.
4. **Data type**: values or percent change.
5. **Treatment date lines**: show or hide the treatment lines.
6. **Error bars**: SD, SE or none.
7. **Card 1 metric**: metric for the upper left graph.
8. **Card 2 metric**: metric for the upper right graph.
9. **Card 3 metric**: metric for the lower left graph.
10. **Wind & slope**: the first weather input; scroll for the rest.
11. to 13. The **Card 1, 2 and 3 graphs**.
14. **Treatment line** at a treatment date.
15. **Points2Pano viewer**.
16. **+ Report data** for the panorama.

## Step by step

1. Download scans on the **Selection Map** and enter any treatment dates on
   **Set Treatments**.
2. Choose the **Surface fuel source**. For **Fuel tool values**, first set
   up and submit the fuels on the **Fuels exports** tab.
3. Enter the **wind**, **slope**, **fuel moisture** and **canopy** inputs for
   the conditions you want to compare, for example typical burning or
   wildfire weather for the site.
4. Pick a metric for each of the three cards, and choose a **Plot type** and
   **Data type**.
5. Compare the time steps before and after each treatment line.
6. Use the controls along the bottom of each graph to enlarge it, see its
   statistics, add it to the report or download it (see below).

## Surface fuel source

**Scan level fuels** (the default) builds a surface fuel bed for each scan
from the site's custom models:

- 1-, 10- and 100-hour dead fuel loads from the predicted time lag counts,
  using Brown's (1974) planar intersect equations;
- fuel bed depth from the predicted mean fuel bed depth; and
- live herbaceous and woody loads and the dead moisture of extinction from
  the left panel.

**Fuel tool values** uses the loadings submitted from the **Fuels exports**
tab instead. Each scan keeps its own loadings, so the results still change
through time. Live loads and the moisture of extinction come from the fuel
model chosen there. Each scan keeps its own canopy for the crown fire
metrics, unless you edited canopy base height or canopy bulk density on the
Fuels exports **Canopy fuels** card; an edited value replaces every scan's.

If nothing has been submitted, the panel and the cards say so:

<div class="help-shot"><img src="static/help/images/rothrmel-not-submitted.png" alt="Fuel tool values selected with nothing submitted: a red note in the panel and a message on every card" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:14%">1<span class="help-tip"><b>Fuel tool values</b> selected.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:20.6%;top:20.6%">2<span class="help-tip"><b>Nothing submitted.</b> Go to Fuels exports and click Submit fuels to rothRmel.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:57.5%;top:10.3%">3<span class="help-tip">Each card waits for submitted fuels, or a switch back to Scan level fuels.</span></span>
</div>

After you submit, a green box describes the loadings in use:

<div class="help-shot"><img src="static/help/images/rothrmel-tool-values.png" alt="Fuel tool values in use: a green box describes the submitted loadings, and the graphs are redrawn with them" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:14%">1<span class="help-tip"><b>Fuel tool values</b> selected.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22%;top:23%">2<span class="help-tip">The <b>submitted loadings</b>: their mean, point in time, fuel source and number of scans.</span></span>
</div>

Submit again on Fuels exports after any change there; rothRmel uses the last
values submitted.

## Fire behavior inputs

<div class="help-shot"><img src="static/help/images/rothrmel-inputs.png" alt="The lower part of the fire behavior inputs: dead fuel moisture, live fuel and canopy" width="170">
<span class="help-spot tip-left" tabindex="0" style="left:88%;top:9.3%">1<span class="help-tip"><b>Dead fuel moisture</b> of the 1-, 10- and 100-hour fuels.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:88%;top:33%">2<span class="help-tip"><b>Dead moisture of extinction</b>: above it, fire doesn't spread. Fuel tool values use the fuel model's own value.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:88%;top:51.5%">3<span class="help-tip"><b>Live fuel moisture</b> of herbaceous and woody plants.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:88%;top:65%">4<span class="help-tip"><b>Live fuel loads</b>, used with Scan level fuels.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:88%;top:81%">5<span class="help-tip"><b>Foliar moisture content</b> of the canopy, used for crown fire.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:88%;top:91%">6<span class="help-tip">A note naming the fire models used.</span></span>
</div>

Scroll the left panel below the card metrics for these inputs. They apply to
every scan:

| Input | Default | Meaning |
|---|---|---|
| 20-ft wind speed (mi/h) | 10 | Wind 20 ft above the vegetation |
| Wind adjustment factor | 0.3 | Share of the 20-ft wind reaching mid-flame height; lower under a closed canopy |
| Slope (%) | 0 | Slope of the ground |
| 1-, 10-, 100-hour moisture (%) | 6, 7, 8 | Moisture of the dead fuel size classes |
| Dead moisture of extinction (%) | 25 | Dead fuel moisture above which fire doesn't spread (with Fuel tool values, the fuel model's own value is used when there is one) |
| Herbaceous, woody moisture (%) | 90, 90 | Moisture of the live fuels |
| Herbaceous, woody load (tons/acre) | 0, 0 | Live fuel loads (Scan level fuels only) |
| Foliar moisture content (%) | 100 | Moisture of the canopy foliage, used for crown fire initiation |

With Fuel tool values and a dynamic fuel model, part of the live herbaceous
load is cured into dead fuel as the herbaceous moisture drops, as in the
standard fuel models.

## The metrics

| Group | Metric | What it describes |
|---|---|---|
| Surface fire | Rate of spread (ch/hr or m/min) | How fast the surface fire front advances |
| | Fireline intensity (kW/m) | Heat released per unit length of the fire front (Byram 1959) |
| | Flame length (ft or m) | Length of the flames at the front, from fireline intensity |
| | Reaction intensity (BTU/ft²/min) | Heat released per unit area of the flaming zone |
| | Heat per unit area (BTU/ft²) | Heat released per unit area as the front passes |
| Crown fire | Crown-initiation intensity I₀ (kW/m) | Surface fireline intensity needed to ignite the canopy, from canopy base height and foliar moisture (Van Wagner 1977) |
| | Critical active-crown ROS R₀ (m/min) | Crown spread rate needed for an active crown fire, from canopy bulk density (Van Wagner) |
| | Torching index (mi/h) | 20-ft wind speed at which surface fire would ignite the canopy (Scott and Reinhardt 2001) |
| | Crowning index (mi/h) | 20-ft wind speed at which an active crown fire could be sustained (Scott and Reinhardt 2001) |
| | Crown fire type (0/1/2) | 0 surface fire, 1 passive crown fire (torching), 2 active crown fire |

For the torching and crowning indices, **higher is better**: a stronger wind
is needed before the canopy burns. A treatment that raises them has lowered
the crown fire hazard. An index reads 0 when the threshold is already met with
no wind, and has no value when it isn't reached at any wind up to 100 mi/h.

Crown fire spread uses Rothermel's (1991) method, from standard fuel model 10
at 40% of the 20-ft wind. Crown metrics use each scan's canopy base height and
the LANDFIRE canopy bulk density at the plot. A plot with no trees detected
has no canopy, so its fire type is always surface fire and its crown metrics
are empty.

## How scans are grouped: time steps

The graphs and statistics group scans into **time steps**, one for each round
of scanning. The scans are taken in date order, and a new time step starts
when:

1. a **treatment date** falls between two scan dates, so pre- and
   post-treatment scans are never mixed;
2. a plot already scanned in the current step is **scanned again**, which
   marks a new round of scanning; or
3. more than **30 days** pass since the previous scan.

Each time step is labeled with the average date of its scans. These are
the **Scan grouping** numbers on the Set Treatments tab; change them there to
regroup scans, and the graphs and the report follow.

## Plot types

| Time series | Time series individual plot |
|---|---|
| ![Time series: the mean of each time step joined by a line, with error bars and a red treatment line](static/help/images/plot-type-timeseries.png) | ![One line per plot, colored by site and plot, with a legend](static/help/images/plot-type-individual.png) |
| **Box and Whisker** | **Bar** |
| ![A box and whisker for each time step, with each scan drawn as a point](static/help/images/plot-type-boxplot.png) | ![A bar for the mean of each time step, with error bars](static/help/images/plot-type-bar.png) |

The examples show basal area; the fire behavior graphs work the same way.

- **Time series**: the mean of each time step, joined by a line. Error bars
  show the spread or precision of each mean.
- **Time series individual plot**: one line for each plot, colored by
  site and plot, so you can follow each plot through time. Points are spread
  slightly sideways so scans on the same date don't hide each other (not
  recommended for very large numbers of plots).
- **Box and Whisker**: for each time step, the box covers the middle half
  of the values, the line inside it is the median and the whiskers reach
  the furthest values within 1.5 times the box's height. Each scan is drawn
  as a point, including any beyond the whiskers.
- **Bar**: the mean of each time step as a bar, with error bars.

## Data type: values or percent change

<div class="help-shot"><img src="static/help/images/data-type-percent.png" alt="A graph as percent change from each plot's first scan, with a dashed zero line" width="290"></div>

- **Values** shows the metric in its own units.
- **Percent change** shows the change from **each plot's own first scan**,
  so every plot starts at 0%. A dashed line marks 0. This puts plots with
  different starting values on the same footing, and the title and axis
  add "(% change)".

Plots whose first value is zero or missing are left out of percent change,
because change from zero can't be calculated. Fire behavior is often zero
before a treatment, for example where there is no dead fuel to carry fire,
so expect fewer plots in percent change.

## Error bars

- **SD** (standard deviation): how much individual data points vary or
  scatter around the mean.
- **SE** (standard error, SD / √n): how precisely the mean of the time step
  is known. It shrinks as more plots are scanned.
- **Off**: no error bars.

A time step with a single scan has no error bar. Neither SD nor SE includes
the uncertainty of the fire models or of the predicted fuels.

## Card controls

Move the mouse over a graph to show its controls along the bottom edge.

<div class="help-shot"><img src="static/help/images/standard-outputs-card-controls.png" alt="A graph card with its controls showing: Expand, Graph and Statistics, + Report data and Download" width="290">
<span class="help-spot tip-right tip-up" tabindex="0" style="left:7.6%;top:91%">1<span class="help-tip"><b>Expand.</b> Shows the card full screen. Press <b>Close</b> to return.</span></span>
<span class="help-spot tip-right tip-up" tabindex="0" style="left:22%;top:80%">2<span class="help-tip"><b>Graph / Statistics.</b> Switches between the graph and a table of statistics.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:67%;top:80%">3<span class="help-tip"><b>+ Report data.</b> Adds what the card shows to the report.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:88%;top:80%">4<span class="help-tip"><b>Download.</b> The data as CSV, or the graph as an SVG or PNG image.</span></span>
</div>

1. **Expand**: shows the card full screen; press **Close** to return.
2. **Graph / Statistics**: switches to a table with one row per time step
   (n, min, max, mean, median, mode and SD).
3. **+ Report data**: adds the graph or table to the report, with its
   settings and an automated description.
4. **Download**: **CSV data** (one row per scan) to open in a spreadsheet or
   statistical analysis software, or the graph as an **SVG** or **PNG**
   image on a white background.

### Statistics

<div class="help-shot"><img src="static/help/images/card-statistics-view.png" alt="The Statistics view: one row per time step with n, min, max, mean, median, mode and SD" width="290"></div>

The Statistics view lists one row per time step:

| Column | Meaning |
|---|---|
| Time step | The average date of the scans in the step |
| n | Number of scans |
| Min, Max | Smallest and largest value |
| Mean, Median | Average and middle value |
| Mode | Most frequent value, to 3 significant figures; — when no value repeats |
| SD | Standard deviation; — for a step with a single scan |

The table follows the **Data type**: with percent change selected, it
describes percent change. Like the error bars, it describes differences
between plots, not the uncertainty of the fire models.

### Download

<div class="help-shot"><img src="static/help/images/card-download-menu.png" alt="The Download menu open with CSV data, SVG image and PNG image" width="290"></div>

- **CSV data**: one row per scan (site, plot, date, time step and value),
  whatever plot type is showing. Open it in a spreadsheet or statistical
  analysis software to run your own analysis.
- **SVG image** and **PNG image**: the graph redrawn on a white background
  for documents and slides. SVG stays sharp at any size; PNG is an image at
  200 dpi.

### + Report data

<div class="help-shot"><img src="static/help/images/card-report-added.png" alt="Message: Figure added to the report (8 items): Basal area (Basalarea)" width="250"></div>

Click **+ Report data** to add the card to the report. It adds whatever the
card is showing: the graph, or the statistics table in Statistics view. The
plot type, data type and the fire behavior inputs (surface fuel source, wind,
wind adjustment factor, slope and fuel and foliar moisture) are recorded
with it, along with an automated description of the change over time. A
message confirms the addition, with the number of items now in the report.
Arrange the report on the **Report builder** tab.

## Points2Pano viewer

The fourth card shows the Points2Pano panorama of a selected scan: a 360°
view made from the scan's points. Use it to check the fire behavior results
against what the plot looks like, for example whether a high torching hazard
matches low, dense canopy.

- The label at the top shows the site, plot, scan date and scanner.
- Use **◀** and **▶** to step through the selected scans.
- **+ Report data**, in the lower right corner of the panorama, adds an image
  of the default view of the plot to the report.
- In a narrow card the scan label is shortened with "…". Use the card's
  **Expand** button, in the lower left corner, to see it in full.

## In the report

When a report holds any rothRmel figure or table, it:

- prints the warning that the fire models are for change tracking and
  treatment success only, and have not been verified for custom fuel beds
  generated from TLS;
- explains the fire model and, with Scan level fuels, Brown's fuel loads in
  "About these data"; and
- lists the methods' references at the end of the report.

## Methods and references

The formulas below are the ones the app calculates, with the coefficients
taken from its code. Units are US customary unless noted: loads in lb/ft²,
depths in ft, surface-area-to-volume ratios (SAV) in ft²/ft³, moistures as
fractions, wind in ft/min and spread rates in ft/min.

| Part | Method | Formula |
|---|---|---|
| Surface fire spread | Rothermel (1972), implemented as described by Andrews (2018) | R = I_R · ξ · (1 + φ_w + φ_s) / (ρ_b · ε · Q_ig); see the full equations below |
| Reaction intensity | Rothermel (1972) | I_R = Γ′ · (w_n · h · η_M · η_s), summed over dead and live fuel |
| Heat per unit area | Byram (1959) residence time | HPA = I_R · t_r, with t_r = 384 / σ (min) |
| Fireline intensity | Byram (1959) | I_B = HPA · R / 60 (BTU/ft/s); kW/m = BTU/ft/s × 3.46414 |
| Flame length | Byram (1959) | L = 0.45 · I_B^0.46 (ft) |
| Crown fire initiation | Van Wagner (1977) | I₀ = (0.010 · CBH · (460 + 25.9 · FMC))^1.5 (kW/m; CBH in m, FMC in %) |
| Active crown fire threshold | Van Wagner (1977) | R₀ = 3.0 / CBD (m/min; CBD in kg/m³) |
| Crown fire spread | Rothermel (1991), from standard fuel model 10 (Anderson, 1982) | R_crown = 3.34 · R_FM10, with fuel model 10 burning at a midflame wind of 0.4 × the 20-ft wind (m/min) |
| Crown fire type | Van Wagner (1977) | 0 (surface) if I_B < I₀; 1 (passive) if I_B ≥ I₀ and R_crown < R₀; 2 (active) if I_B ≥ I₀ and R_crown ≥ R₀ |
| Torching index | Scott and Reinhardt (2001) | The 20-ft wind (mi/h) at which I_B = I₀, found by a numerical search from 0 to 100 mi/h |
| Crowning index | Scott and Reinhardt (2001) | The 20-ft wind (mi/h) at which R_crown = R₀, found the same way |
| Dead fuel loads from time lag counts | Brown (1974) | W = 11.64 · n · d² · s · a · c / (N · L) (tons/acre); see the constants below |
| Cured herbaceous fuel | Scott and Burgan (2005) dynamic fuel models | Share cured = 1.333 − 1.11 · M_herb, limited to 0 to 1 (M_herb as a fraction) |

<details class="help-formulas">
<summary>Show the full Rothermel surface fire equations</summary>

Each fuel class i (1-, 10- and 100-hour, cured herbaceous, live herbaceous
and live woody) has a load w₀ᵢ, SAV σᵢ and moisture Mᵢ. Classes are grouped
into dead and live categories.

| Quantity | Formula |
|---|---|
| Particle density, heat content, mineral content | ρ_p = 32 lb/ft³; h = 8,000 BTU/lb; S_T = 0.0555; S_e = 0.010 |
| Class surface area | Aᵢ = σᵢ · w₀ᵢ / ρ_p |
| Weighting factors | fᵢ = Aᵢ / A_category; f_dead = A_dead / A_total; f_live = A_live / A_total |
| Characteristic SAV | σ = f_dead · Σ fᵢσᵢ(dead) + f_live · Σ fᵢσᵢ(live) |
| Bulk density | ρ_b = Σ w₀ᵢ / δ (δ = fuel bed depth, ft) |
| Packing ratio | β = ρ_b / ρ_p |
| Optimum packing ratio | β_op = 3.348 · σ^−0.8189 |
| Maximum reaction velocity | Γ′_max = σ^1.5 / (495 + 0.0594 · σ^1.5) |
| Reaction velocity | Γ′ = Γ′_max · (β/β_op)^A · exp(A · (1 − β/β_op)), with A = 133 · σ^−0.7913 |
| Net fuel load | w_n = Σ w₀ᵢ · (1 − S_T), per category |
| Category moisture | M_f = Σ fᵢ · Mᵢ, per category |
| Live moisture of extinction | M_x,live = 2.9 · W′ · (1 − M_f,dead fine / M_x,dead) − 0.226, at least M_x,dead; W′ = Σ w₀ᵢ·exp(−138/σᵢ) (dead) / Σ w₀ᵢ·exp(−500/σᵢ) (live) |
| Moisture damping | η_M = 1 − 2.59·r + 5.11·r² − 3.52·r³, with r = M_f / M_x (at most 1) |
| Mineral damping | η_s = 0.174 · S_e^−0.19 (at most 1) |
| Reaction intensity | I_R = Γ′ · Σ w_n · h · η_M · η_s over dead and live (BTU/ft²/min) |
| Propagating flux ratio | ξ = exp((0.792 + 0.681 · σ^0.5) · (β + 0.1)) / (192 + 0.2595 · σ) |
| Wind factor | φ_w = C · U^B · (β/β_op)^−E, with C = 7.47 · exp(−0.133 · σ^0.55), B = 0.02526 · σ^0.54, E = 0.715 · exp(−0.000359 · σ) |
| Midflame wind | U = wind adjustment factor × 20-ft wind (ft/min), limited to 0.9 · I_R |
| Slope factor | φ_s = 5.275 · β^−0.3 · tan²θ (tan θ = slope % / 100) |
| Effective heating number | εᵢ = exp(−138 / σᵢ) |
| Heat of preignition | Q_ig,i = 250 + 1116 · Mᵢ (BTU/lb) |
| Heat sink | ρ_b · Σ_category f_category · Σ fᵢ · εᵢ · Q_ig,i |
| Rate of spread | R = I_R · ξ · (1 + φ_w + φ_s) / heat sink (ft/min); ch/hr = ft/min × 60/66; m/min = ft/min × 0.3048 |

Fuel model 10 for crown spread: 1-hour 3.01, 10-hour 2.0, 100-hour 5.01 and
live woody 2.0 tons/acre, depth 1.0 ft, dead moisture of extinction 25%. SAV
values: 1-hour 2,000, 10-hour 109, 100-hour 30, herbaceous and woody 1,500
ft²/ft³.

</details>

<details class="help-formulas">
<summary>Show Brown's planar intersect constants</summary>

W = 11.64 · n · d² · s · a · c / (N · L), with n the count of pieces, N the
number of sampling planes (1), L the transect length (40 m = 131.2 ft) and c
the slope correction (1, not applied).

| Class | d² (squared mean diameter, in²) | s (specific gravity) | a (non-horizontal correction) |
|---|---|---|---|
| 1-hour (0 to 0.25 in) | 0.0151 | 0.48 | 1.13 |
| 10-hour (0.25 to 1 in) | 0.289 | 0.48 | 1.13 |
| 100-hour (1 to 3 in) | 2.76 | 0.40 | 1.13 |
| 1000-hour (over 3 in, sound) | 22.30 | 0.40 | 1.00 |

</details>

- Anderson, H. E. (1982). Aids to determining fuel models for estimating fire
  behavior. Gen. Tech. Rep. INT-122. USDA Forest Service.
- Andrews, P. L. (2018). The Rothermel surface fire spread model and
  associated developments: a comprehensive explanation. Gen. Tech. Rep.
  RMRS-GTR-371. USDA Forest Service.
- Brown, J. K. (1974). Handbook for inventorying downed woody material. Gen.
  Tech. Rep. INT-16. USDA Forest Service.
- Byram, G. M. (1959). Combustion of forest fuels. In K. P. Davis (Ed.),
  *Forest fire: control and use* (pp. 61-89). McGraw-Hill.
- Rothermel, R. C. (1972). A mathematical model for predicting fire spread in
  wildland fuels. Res. Pap. INT-115. USDA Forest Service.
- Rothermel, R. C. (1991). Predicting behavior and size of crown fires in the
  Northern Rocky Mountains. Res. Pap. INT-438. USDA Forest Service.
- Scott, J. H., & Burgan, R. E. (2005). Standard fire behavior fuel models:
  a comprehensive set for use with Rothermel's surface fire spread model.
  Gen. Tech. Rep. RMRS-GTR-153. USDA Forest Service.
- Scott, J. H., & Reinhardt, E. D. (2001). Assessing crown fire potential by
  linking models of surface and crown fire behavior. Res. Pap. RMRS-RP-29.
  USDA Forest Service.
- Van Wagner, C. E. (1977). Conditions for the start and spread of crown
  fire. *Canadian Journal of Forest Research*, 7(1), 23-34.

## Things to know

- **For change tracking, not prediction.** Compare the same plots under the
  same inputs through time. Don't read the values as a forecast of how a
  real fire would behave.
- **Scan level fuels need custom models.** Without a predicted fuel bed
  depth, a scan has no fire behavior and the graphs have no value for it.
  For sites without custom models, set up fuels on **Fuels exports** with
  the LANDFIRE derived source and use **Fuel tool values**.
- **No dead fuel, no spread.** A scan whose fuel bed has no dead fine fuel
  gives zero spread and intensity. That is a result, not missing data.
- **Weather is the same for every scan.** Change the inputs to compare
  conditions, for example moderate and extreme weather, and note them when
  you report the results; the report records them with each graph.
- **Live loads default to zero.** With Scan level fuels, enter live
  herbaceous and woody loads if the plots carry them; otherwise only dead
  fuel is modeled.
- **The settings apply to every graph on this tab.** Each tab has its own
  settings, so changing them here doesn't change cards in Standard outputs
  or Custom models.
- **Treatment dates matter.** Without them, pre- and post-treatment scans
  can share a time step if they were collected close together. Enter them on
  **Set Treatments** before you evaluate the results.
- **Means pool every loaded plot.** The time series, bar and statistics
  combine all loaded scans in each time step, across sites and units. Load
  only the plots you want to compare, or use **Time series individual plot**
  to see each plot separately.
