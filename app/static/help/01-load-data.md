# Load My Data

## What this tab is for

**Load My Data** brings local data on your machine into the decision support
tool and is only used on locally installed versions. It brings data on your
computer into the tool without going through the IntELiMon servers, so the
data never leave your machine. This supports tribal data sovereignty and
other data that is not classified as open and available.

The tab has two parts:

- **Process .PTX files** (top): runs IntELiMon on your own computer, turning
  raw terrestrial laser scans (TLS point clouds) into IntELiMon metrics and
  Points2Pano images. This functionality is not active yet.
- **Load IntELiMon data** (bottom): loads IntELiMon outputs already on your
  computer (metrics, tree inventory, models and Points2Pano images) into
  your session, and places the plots on the map when their locations are
  known.

Loaded scans are listed under the agency **MyPC** on the **Selection Map**,
where you select them and click **Get Data** like any other scans.

## The screen at a glance

Move the mouse over a numbered marker, or press Tab to step through them, to
see what each part does.

<div class="help-shot"><img src="static/help/images/load-data-overview.png" alt="The Load My Data tab: the Process .PTX files card above and the Load IntELiMon data card below" width="648">
<span class="help-spot tip-right" tabindex="0" style="left:20%;top:2.5%">1<span class="help-tip"><b>Process .PTX files.</b> Runs IntELiMon on your computer. Not active yet.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:67.1%;top:11.5%">2<span class="help-tip"><b>Input: new PTX files.</b> The folder holding the raw scans (.ptx point clouds).</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:67.1%;top:21.6%">3<span class="help-tip"><b>Output: IntELiMon metrics.</b> The folder the results are written to. Required for both processing PTX files and selecting metrics files for use in the tool.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.5%;top:30.9%">4<span class="help-tip"><b>Run IntELiMon.</b> Calculates the IntELiMon metrics from the point clouds.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.5%;top:41.2%">5<span class="help-tip"><b>Run Points2Pano.</b> Makes the Points2Pano panorama images from the point clouds.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:61.7%;top:64.4%">6<span class="help-tip"><b>Load IntELiMon metrics.</b> Opens a folder browser. Pick the folder holding your IntELiMon outputs.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:95.7%;top:65.8%">7<span class="help-tip"><b>Scan metrics loaded.</b> How many scans were loaded from this computer. Red until a folder is loaded.</span></span>
<span class="help-spot tip-right tip-up" tabindex="0" style="left:46.3%;top:97.1%">8<span class="help-tip"><b>From IntELiMon download files.</b> Places the plots on the map from the X and Y coordinates in the metrics files. Coming soon.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:96.5%;top:97.1%">9<span class="help-tip"><b>From my .kmz.</b> Places the plots on the map from a Google Earth (KML/KMZ) file of plot locations. Coming soon.</span></span>
</div>

1. **Process .PTX files**: run IntELiMon locally (not active yet).
2. **Input: new PTX files**: folder of raw point clouds.
3. **Output: IntELiMon metrics**: folder for the results. Required for both
   processing PTX files and selecting metrics files for use in the tool.
4. **Run IntELiMon**: calculate the metrics.
5. **Run Points2Pano**: make the panorama images.
6. **Load IntELiMon metrics**: pick a folder of IntELiMon outputs to load.
7. **Scan metrics loaded**: the number of scans loaded.
8. **From IntELiMon download files**: map the plots from the coordinates in
   the metrics files (coming soon).
9. **From my .kmz**: map the plots from a KML/KMZ file (coming soon).

## Process .PTX files (not active yet)

When this part is active, IntELiMon will run entirely on your computer:

1. Click **Input: new PTX files** and pick the folder holding the raw scans.
2. Click **Output: IntELiMon metrics** and pick the folder to write the
   results to. The path appears beside each button.
3. Click **Run IntELiMon** to calculate the metrics, then **Run
   Points2Pano** to make the panorama images.

The output folder can then be loaded with **Load IntELiMon metrics** below;
the folder browser opens on it.

## Load IntELiMon data

### Step 1: Load the files

1. Navigate to the metrics folder in the **Process .PTX files** card.
2. Click the **Output: IntELiMon metrics** button and navigate to the folder
   that holds the metrics to be loaded.
3. Click **Load IntELiMon metrics**. A folder browser opens on your home
   folder, with any other drives (such as a thumb drive) listed as well.
4. Pick the folder that holds your IntELiMon outputs and confirm.
5. A message says the data are being made available on the Selection Map,
   and the box on the right turns green with the number of scans loaded.

<div class="help-shot"><img src="static/help/images/load-data-loaded.png" alt="After loading a folder: the box reads Scan metrics loaded: 10, Data available for selection on Selection Map tab" width="648">
<span class="help-spot tip-left" tabindex="0" style="left:97%;top:17%">1<span class="help-tip">Ten scans were loaded and can now be selected on the <b>Selection Map</b>.</span></span>
</div>

The folder can hold IntELiMon outputs in either form:

- **A download from the IntELiMon viewer**: one zip file per scan, named
  `<site>_<plot>_<date>_<scanner>.zip` (for example
  `AZCNF_0012_20241215_1.zip`), in site and year folders or all together.
  The zips don't need to be unpacked.
- **IntELiMon outputs on disk**: the `metrics`, `Inventory`, `Shrubs`,
  `Fuels`, `dtm`, `chm` and `points2pano` folders, with one file per scan
  named the same way (for example
  `metrics/AZCNF_0012_20241215_1_metrics.csv`).

Files that don't follow the scan naming are skipped. Scans already available
(from the IntELiMon API or an earlier load) are not added twice. You can load
more than one folder; the count adds up.

### Step 2: Place the plots on the map (optional, coming soon)

Choose one:

- **From IntELiMon download files**: uses the X and Y coordinates in the
  metrics files of a download from IntELiMon, when the data were not
  delivered through the API.
- **From my .kmz**: uses a Google Earth file (KML/KMZ) of your plot
  locations.

These two buttons are not active yet. Until they are, loaded scans have no
coordinates and are selected from the **Table** on the Selection Map (Step
3).

### Step 3: Select the loaded scans on the Selection Map

- **Scans with locations** appear on the **Location Map** like any other
  plots, in the color of the agency **MyPC**. Click them, or draw a shape
  around them, to select them.
- **Scans without locations** can't be drawn on the map. Select them from
  the table instead:

<div class="help-shot"><img src="static/help/images/selection-map-table-mypc.png" alt="The Selection Map Table view filtered to the MyPC agency: ten local scans with empty Latitude and Longitude, three of them selected" width="632">
<span class="help-spot tip-right" tabindex="0" style="left:19%;top:10.9%">1<span class="help-tip"><b>Agency selection</b> set to <b>MyPC</b>: only the scans loaded from this computer are listed.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:95%;top:6.3%">2<span class="help-tip">The <b>Table</b> view of the Selection Map.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:68%;top:61.7%">3<span class="help-tip"><b>Latitude</b> and <b>Longitude</b> are empty: these scans have no location, so they are not on the map.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:66.5%;top:45%">4<span class="help-tip"><b>Selected scans</b> are highlighted. Click a row to select it; click it again to unselect it.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:23.7%;top:32.8%">5<span class="help-tip"><b>Get Data</b> loads the selected scans into the session from your computer.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:44.6%;top:9%">6<span class="help-tip"><b>Clear selection</b> unselects every row in the table.</span></span>
</div>

1. Go to the **Selection Map** tab.
2. In **Agency selection**, pick **MyPC**.
3. Click **Table** at the top right of the map card.
4. Click the rows of the scans you want. Selected rows are highlighted.
5. Click **Get Data**. The scans are read from your computer and are ready
   on **Set Treatments** and the graph tabs.

## Things to know

- **Local installations only.** The web version of the tool doesn't show
  this tab; its scans come from the IntELiMon API.
- **Your data stay on your computer.** Loaded files are read where they are;
  nothing is uploaded.
- **Loaded scans last for one session.** Reloading the page clears them;
  load the folder again to get them back.
- **Scans without locations** are selected from the Selection Map table, not
  the map. Tabs that need plot locations, such as the plot locations map in
  the report and the Fuels exports landscape, need located plots.
- **Questions or problems:** <spokswinski@newmexicoconsortium.org>
