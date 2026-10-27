# Custom models

<p class="help-warning"><strong>Custom model values are predictions, not
measurements. Each model is calibrated with field data from one site, and its
predictions carry model error that this tab does not show: the error bars and
statistics describe differences between plots, not how accurate the model is.
The models are not validated outside the site, vegetation and conditions of
the data used to build them. Use them to track relative change at the
calibrated site and condition, and confirm important decisions with field
measurements. Refer to the Points2Pano image for QA/QC and raise concerns
with a data analyst when a model seems unreliable.</strong></p>

## What this tab is for

Custom models shows the outputs of predictive models built for individual
sites. Where crews have collected field data alongside the scans, analysts
train models that predict quantities the scan can't measure directly, such
as grass and forb cover, litter and duff depth, fuel counts along transects
and hardwood and pine basal area. The models are then run on every scan of
that site. Some sites may have models that only work for specific habitat
types, but not others in the same site, so multiple models must be employed.
For example, grass cover models for forested and rangeland habitats at a
single site may use different predictor variables and require separate
models.

Use the tab to follow these predicted fuels and vegetation through time and
across treatments, alongside the measured metrics on **Standard outputs**.
Three graph cards (Windows A, B and C) each show one model. A fourth card
shows the Points2Pano panorama of the scans. This allows a user to view the
model outputs in the context of the scan and provides a QA/QC assessment of
the scans. The settings in the left panel apply to all three graphs.

These graphs use data from the scans downloaded on the **Selection Map** and
the treatment dates entered on **Set Treatments**.

Custom models exist only for sites with a calibrated model. If none of the
loaded scans have predictive models for that site, the following error is
shown:

<div class="help-shot"><img src="static/help/images/custom-models-none.png" alt="Message: No custom models were run on the loaded scans. Custom models exist only for sites with a model calibrated from field data; see Help." width="285"></div>

## The screen at a glance

Move the mouse over a numbered marker, or press Tab to step through them, to
see what each part does.

<div class="help-shot"><img src="static/help/images/custom-models-overview.png" alt="The Custom models tab: plot settings and model lists on the left, three model graphs and the Points2Pano viewer on the right" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:9.9%">1<span class="help-tip"><b>Plot type.</b> How the graphs draw the data: time series, one line per plot, box and whisker, or bars.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:17.3%">2<span class="help-tip"><b>Data type.</b> Predicted values, or percent change from each plot's first scan.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:20%;top:24.4%">3<span class="help-tip"><b>Treatment date lines.</b> Shows or hides the red lines at the treatment dates.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:21.3%;top:31.2%">4<span class="help-tip"><b>Error bars.</b> SD (spread among plots), SE (precision of the mean) or Off. They don't include model error.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:20%;top:38.1%">5<span class="help-tip"><b>Window A available models.</b> The model for the upper left graph.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:20%;top:45.3%">6<span class="help-tip"><b>Window B available models.</b> The model for the upper right graph.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:20%;top:52.6%">7<span class="help-tip"><b>Window C available models.</b> The model for the lower left graph.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:36.25%;top:5.7%">8<span class="help-tip"><b>Window A graph.</b> Its title names what the model predicts, with units.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:71.9%;top:5.7%">9<span class="help-tip"><b>Window B graph.</b></span></span>
<span class="help-spot tip-right" tabindex="0" style="left:26.5%;top:50.1%">10<span class="help-tip"><b>Window C graph.</b></span></span>
<span class="help-spot tip-left" tabindex="0" style="left:54%;top:25.3%">11<span class="help-tip"><b>Treatment line.</b> A treatment date from the Set Treatments tab.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.5%;top:49.7%">12<span class="help-tip"><b>Points2Pano viewer.</b> The panorama of a selected scan, with its site, plot, date and scanner. Step through the scans with ◀ and ▶; in a narrow card the label is shortened with "…".</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:86.8%;top:87.4%">13<span class="help-tip"><b>+ Report data.</b> In the lower right of the panorama: adds a photo of the plot showing to the report.</span></span>
</div>

1. **Plot type**: how the graphs draw the data.
2. **Data type**: predicted values or percent change.
3. **Treatment date lines**: show or hide the treatment lines.
4. **Error bars**: SD, SE or none; they don't include model error.
5. **Window A available models**: model for the upper left graph.
6. **Window B available models**: model for the upper right graph.
7. **Window C available models**: model for the lower left graph.
8. to 10. The **Window A, B and C graphs**.
11. **Treatment line** at a treatment date.
12. **Points2Pano viewer**.
13. **+ Report data** for the panorama.

## Step by step

1. Download scans on the **Selection Map**, including plots at sites with
   custom models, and enter any treatment dates on **Set Treatments**.
2. Pick a model in each of the **Window A**, **B** and **C** lists. The
   three windows start on the first three models in the list.
3. Choose a **Plot type** and a **Data type**, and turn **Treatment date
   lines** and **Error bars** on or off.
4. Use the controls along the bottom of each graph to enlarge it, see its
   statistics, add it to the report or download it (see below).

## Choosing a model

<div class="help-shot"><img src="static/help/images/custom-models-list.png" alt="The Window A list open, showing model codes such as Forbsmod, Grassmod, hunhrmod and MFBDmod" width="170">
<span class="help-spot tip-left" tabindex="0" style="left:72%;top:54%">1<span class="help-tip">The lists show <b>model codes</b>. The graph title shows what each one predicts; see the table below.</span></span>
</div>

The lists show only the models run on the loaded scans, by their code. The
graph title spells out what the model predicts:

| Code | Predicts |
|---|---|
| Forbsmod | Forb cover (%) |
| Grassmod | Grass cover (%) |
| Fernmod | Fern cover (%) |
| Shrubmod | Shrub cover (%) |
| Woodymod | Live woody cover (%) |
| Snowberrymod | Snowberry cover (%) |
| Volatilemod | Volatile woody shrub cover (%) |
| MossLichenlm | Moss/lichen cover (%) |
| Littermod | Litter cover (%) |
| BLLitmod | Broadleaf litter cover (%) |
| Pinelittmod | Pine litter cover (%) |
| NeedllLittmod | Needle litter cover (%) |
| LNLitmod, Lnlittmod | Long needle litter cover (%) |
| SNLitmod | Short needle cover (%) |
| OLitmod, Otherlittmod | Other litter cover (%) |
| MFBDmod | Mean fuel bed depth (cm) |
| MLDmod | Mean litter depth (cm) |
| MDDmod | Mean duff depth (cm) |
| onehrmod | One hour fuel count (count per 40 m of transect) |
| tenhrmod | Ten hour fuel count (count per 40 m) |
| hunhrmod | Hundred hour fuel count (count per 40 m) |
| thohrmod, thouhrmod | Thousand hour fuel count (count per 40 m) |
| HWBAmod, PHWBAmod | Hardwood basal area (ft²/acre) |
| PPBAmod | Pine basal area (ft²/acre) |

A site can have models not in this table. Their graphs are titled with the
code itself.

The fuel counts predict how many pieces of each size class a crew would
tally along 40 m of transect. The **Fuels exports** tab turns them into fuel
loads.

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

The examples show basal area; the model graphs work the same way.

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

- **Values** shows the predicted values in the model's own units.
- **Percent change** shows the change from **each plot's own first scan**,
  so every plot starts at 0%. A dashed line marks 0. This puts plots with
  different starting values on the same footing, and the title and axis
  add "(% change)".

Plots whose first value is zero or missing are left out of percent change,
because change from zero can't be calculated. Cover models often predict 0
for a plot, so expect fewer plots in percent change.

## Error bars

- **SD** (standard deviation): how much individual data points vary or
  scatter around the mean.
- **SE** (standard error, SD / √n): how precisely the mean of the time step
  is known. It shrinks as more plots are scanned.
- **Off**: no error bars.

A time step with a single scan has no error bar. Neither SD nor SE includes
the model's own prediction error, so the true uncertainty is larger than the
bars show.

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
between plots, not the model's prediction error.

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
plot type, data type and other settings are recorded with it, along with an
automated description of the change over time. A message confirms the
addition, with the number of items now in the report. Arrange the report on
the **Report builder** tab.

## Points2Pano viewer

The fourth card shows the Points2Pano panorama of a selected scan: a 360°
view made from the scan's points. Use it to check the model outputs against
what the plot looks like.

- The label at the top shows the site, plot, scan date and scanner.
- Use **◀** and **▶** to step through the selected scans.
- **+ Report data**, in the lower right corner of the panorama, adds an image
  of the default view of the plot to the report.
- In a narrow card the scan label is shortened with "…". Use the card's
  **Expand** button, in the lower left corner, to see it in full.

## In the report

When a report holds any custom model figure or table, it prints a warning
that custom model values are predictions with model error that the figures
don't show, and that they are not validated outside the data used to build
them.

## Things to know

- **Predictions, not measurements.** Treat the values as estimates. Changes
  smaller than the model's typical error may not be real.
- **Each model belongs to one site.** A model is calibrated with field data
  from its own site. Models with the same code at different sites are
  different models, but a graph combines every loaded scan with that code.
  To compare sites, check them separately, for example with **Time series
  individual plot**.
- **Outside the calibration data, predictions are less reliable.** After a
  treatment, vegetation and fuels can move beyond what the model was trained
  on, for example after a severe burn. Confirm large changes with field
  measurements.
- **The settings apply to every graph on this tab.** Each tab has its own
  settings, so changing them here doesn't change cards in Standard outputs
  or rothRmel.
- **Treatment dates matter.** Without them, pre- and post-treatment scans
  can share a time step if they were collected close together. Enter them on
  **Set Treatments** before you evaluate the results.
- **No models for a site?** Models are built only where field data were
  collected with the scans. Contact the IntELiMon team
  (<spokswinski@newmexicoconsortium.org>) about calibrating models for your
  site.
