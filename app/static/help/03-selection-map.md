# Selection Map

## What this tab is for

The Selection Map is used to identify and download the data records that
will be available for analysis throughout the application. Plot locations
available through the IntELiMon API, along with any selected local data, are
displayed on the map and color-coded by agency.

Use the map controls to filter plots by agency and scan date, select plots
for analysis, and download the associated data into the current session.
Data downloaded from this tab populate the following tabs:

- Set Treatments
- Standard Outputs
- Custom Models
- Fuels Exports
- Forestry Exports
- rothRmel
- Report Builder

A plot may be scanned multiple times, such as before and after treatment.
Each scan is stored as a separate record. The controls on this tab determine
which scan records are selected and downloaded.

- **Agency selection** limits displayed plots to one or more agencies.
- **Date range** limits displayed scans to a specified time period.
- **Point selection** selects individual plots. Selecting a plot includes
  all scans for that plot that fall within the current date range.
- **Get Data** downloads forestry, fuels, and ecological metrics; tree
  inventory data; and predictive-model outputs for the selected scans.

For local installations, scans may also be loaded from a folder using the
**Load Data** tab.

## The screen at a glance

Move the mouse over a numbered marker, or press Tab to step through them, to
see what each part does.

<div class="help-shot"><img src="static/help/images/selection-map-overview.png" alt="The Selection Map tab: the Select Scans panel with Clear All Plots, Get Data and Clear All Downloads on the left, and the IntELiMon Plots card with its Location Map and Table views on the right" width="678">
<span class="help-spot tip-right" tabindex="0" style="left:25.2%;top:11%">1<span class="help-tip"><b>Agency selection.</b> Pick one or more agencies to show only their plots. Leave it empty to show every agency. Scans loaded from your own computer are listed as <b>MyPC</b>.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:25.2%;top:15.6%">2<span class="help-tip"><b>Select date range.</b> Drag either handle to show only scans collected between the two dates.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:25.2%;top:28.3%">3<span class="help-tip"><b>Clear All Plots.</b> Clears the plots you selected but haven't downloaded. Downloaded scans stay loaded.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:25.2%;top:32.9%">4<span class="help-tip"><b>Get Data.</b> Downloads the selected scans into your session. The other tabs use these data.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:25.2%;top:37.4%">5<span class="help-tip"><b>Clear All Downloads.</b> Removes all downloaded scans and their data from the session, after asking you to confirm.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:34.6%;top:14%">6<span class="help-tip"><b>Zoom in and out.</b> You can also zoom with the mouse wheel and pan by dragging the map.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:34.6%;top:22.3%">7<span class="help-tip"><b>Draw a polygon or rectangle.</b> Every plot inside the shape is selected at once.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:88%;top:13.2%">8<span class="help-tip"><b>Satellite or Base Map.</b> Switch between satellite imagery and a plain gray map. Markers are easier to see on the Base Map.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:81.2%;top:4.3%">9<span class="help-tip"><b>Location Map / Table.</b> Switch between the map and a table of the same scans. Scans without coordinates, such as local scans not yet placed on the map, are only in the table.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:62.7%;top:75%">10<span class="help-tip"><b>Legend.</b> The color of each agency's plots. Selected plots are gold; downloaded plots are blue.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:79.6%;top:64%">11<span class="help-tip"><b>Plots.</b> Each dot is a plot. Zoom in and click a dot to select it; click it again to unselect it.</span></span>
<span class="help-spot tip-right tip-up" tabindex="0" style="left:30%;top:97.5%">12<span class="help-tip"><b>Expand.</b> Shows the card full screen, partly hidden behind the legend in this corner. Press <b>Close</b> at the top right to return.</span></span>
</div>

1. **Agency selection**: shows only the chosen agencies' plots.
2. **Select date range**: shows only scans between the two dates.
3. **Clear All Plots**: clears the plots not yet downloaded.
4. **Get Data**: downloads the selected scans.
5. **Clear All Downloads**: removes all downloaded scans and their data.
6. **Zoom buttons**: zoom in and out (the mouse wheel works too).
7. **Draw polygon / rectangle**: select every plot inside a shape.
8. **Satellite / Base Map**: switches the background map.
9. **Location Map / Table**: switches between the map and a table of the
   scans.
10. **Legend**: agency colors, plus gold for selected and blue for
    downloaded plots.
11. **Plots**: click to select or unselect.
12. **Expand**: shows the card full screen.

## Step by step

### Step 1: Choose agencies (optional)

<div class="help-shot"><img src="static/help/images/selection-map-agency-list.png" alt="The Agency selection list open, showing agency names" width="400">
<span class="help-spot tip-right" tabindex="0" style="left:40%;top:26%">1<span class="help-tip">Click the box to open the list. You can also type part of a name to find an agency quickly.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:38%;top:45%">2<span class="help-tip">Click an agency to add it. The list stays open so you can add more.</span></span>
</div>

1. Click the **Agency selection** box. The agency names open in a drop down
   list.
2. Click an agency, or type part of its name and press **Enter**. Add as
   many agencies as you need.
3. Click anywhere outside the list, or press **Esc**, to close it.
4. To remove an agency, click its name in the box and press **Backspace** or
   **Delete**.

When the box is empty, plots from every agency are shown. After a change,
the map zooms to fit all the plots that match.

### Step 2: Set the date range (optional)

<div class="help-shot"><img src="static/help/images/selection-map-date-range.png" alt="The date range slider with its start handle moved to 2023-06-27" width="180"></div>

1. Drag the **left handle** to the earliest date you want.
2. Drag the **right handle** to the latest date you want.

The dates above the handles show the range. The slider moves in steps of
about a month (30 days). Only scans collected inside the range are shown on
the map and can be selected.

The figure below shows the map after both filters: only USDA Forest Service
plots scanned from June 2023 onward remain.

<div class="help-shot"><img src="static/help/images/selection-map-agency-filtered.png" alt="The map after choosing USDA Forest Service and moving the start date to 2023-06-27" width="760">
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:16%">1<span class="help-tip">One agency chosen: only its plots are drawn.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:10%;top:37%">2<span class="help-tip">Start date moved later: scans collected before it are hidden.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:62%;top:42%">3<span class="help-tip">The map zooms to fit the plots that match both filters.</span></span>
</div>

### Step 3: Find your plots

- **Zoom** with the **+** and **−** buttons or the mouse wheel, and **pan**
  by dragging the map.
- Once you zoom in far enough, each plot shows its **plot number**. The
  numbers appear when no more than 80 plots are in view.
- Use the **Expand** button in the lower left corner of the map card to work
  on a full-screen map.
- Switch to **Base Map** if the markers are hard to see on the satellite
  imagery.
- For a larger view, click the gray circle in the lower left corner of the
  map card to expand the map to full screen.

### Step 4: Select plots

<div class="help-shot"><img src="static/help/images/selection-map-selected.png" alt="A zoomed-in map with plot numbers; three plots are selected and drawn in gold" width="780">
<span class="help-spot tip-right" tabindex="0" style="left:46%;top:34%">1<span class="help-tip"><b>Selected plot</b> (gold). Click it again to unselect it.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:24%;top:46%">2<span class="help-tip"><b>Plot not selected</b>, drawn in its agency's color.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:31%;top:54%">3<span class="help-tip"><b>Plot number</b>, shown once you zoom in.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:12.5%;top:62.5%">4<span class="help-tip"><b>Selected</b> in the legend: gold marks the plots you picked.</span></span>
</div>

1. When a plot point is clicked, it turns **gold**: it is selected, together
   with all of its scans inside the date range.
2. Click more plots to add them. They can be anywhere on the map across
   sites and agencies.
3. To unselect a plot, click its dot again to revert it to its original
   color. A plot whose scans are already downloaded stays selected; see
   Step 6.

The dots are small. If a click doesn't select a plot, zoom in further and
click the center of the dot.

#### Select scans from the table

Click **Table** at the top right of the map card to list the same scans as
rows: site, plot, date, agency, latitude, longitude and scanner. The agency
and date filters apply to the table too, and the column filters at the top
of the table narrow both the table and the map.

<div class="help-shot"><img src="static/help/images/selection-map-table-mypc.png" alt="The Table view filtered to the MyPC agency: ten local scans with empty Latitude and Longitude, three of them selected" width="632">
<span class="help-spot tip-right" tabindex="0" style="left:19%;top:10.9%">1<span class="help-tip"><b>Agency selection</b> set to <b>MyPC</b>: only the scans loaded from this computer are listed.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:95%;top:6.3%">2<span class="help-tip">The <b>Table</b> view.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:68%;top:61.7%">3<span class="help-tip">Empty <b>Latitude</b> and <b>Longitude</b>: these scans have no location, so they are only in the table.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:66.5%;top:45%">4<span class="help-tip"><b>Selected scans</b> are highlighted.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:44.6%;top:9%">5<span class="help-tip"><b>Clear selection</b> unselects every row in the table.</span></span>
</div>

1. Click the rows you want. Selected rows are highlighted; click a row again
   to unselect it.
2. The selection is shared with the map: rows you select turn gold on the
   map, and plots you click on the map are selected in the table.
3. Click **Get Data** as usual.

The table is the way to select scans that have no coordinates, such as
scans loaded from your own computer on the **Load My Data** tab (local
installations only) before their locations are added. Pick **MyPC** in
**Agency selection** to list just those scans.

#### Select many plots at once by drawing a shape

<div class="help-shot"><img src="static/help/images/selection-map-draw-polygon.png" alt="A polygon being drawn around plots 0020, 0009, 0010 and 0019, with the Finish, Delete last point and Cancel buttons beside the polygon tool" width="490">
<span class="help-spot tip-right" tabindex="0" style="left:4.5%;top:28.5%">1<span class="help-tip"><b>Polygon tool.</b> Click it, then click the map at each corner of the shape.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:4.5%;top:37%">2<span class="help-tip"><b>Rectangle tool.</b> Click it, then drag across the plots.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:49%;top:28.9%">3<span class="help-tip"><b>Finish</b> closes the polygon; <b>Delete last point</b> takes back a corner; <b>Cancel</b> stops drawing.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:45.9%;top:48.5%">4<span class="help-tip">Click the <b>first point</b> again to close the shape.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:59.2%;top:70.5%">5<span class="help-tip">Every plot inside the shape will be selected.</span></span>
</div>

1. Zoom so the plots you want are in view.
2. Pick a tool on the left of the map:
   - **Polygon** (the pentagon): click the map at each corner of the shape.
     Click the first corner again, or click **Finish**, to close it.
     **Delete last point** takes back a corner; **Cancel** stops drawing.
     Edges can't cross each other.
   - **Rectangle** (the square): click, then drag across the plots.
3. When the shape is closed, every plot inside it turns **gold**, with all
   of its scans inside the date range, as if you had clicked each one. A
   message says how many plots were added.

<div class="help-shot"><img src="static/help/images/selection-map-draw-selected.png" alt="After drawing the polygon: plots 0020, 0009, 0010 and 0019 are gold and a message reads Selected 4 plots inside the drawn shape" width="498">
<span class="help-spot tip-left" tabindex="0" style="left:68.5%;top:39.8%">1<span class="help-tip">The four plots inside the shape are now <b>selected</b> (gold).</span></span>
<span class="help-spot tip-right tip-up" tabindex="0" style="left:27%;top:95.5%">2<span class="help-tip">A message counts the plots added.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:20.5%;top:62.5%">3<span class="help-tip"><b>Selected</b> in the legend.</span></span>
</div>

The shape disappears once its plots are selected, so you can draw another
one to add more. A shape only adds plots: plots already selected stay
selected, and the message counts them separately. To take a plot out, click
it. Only plots that pass the agency and date filters are selected.

### Step 5: Get the data

<div class="help-shot"><img src="static/help/images/selection-map-progress.png" alt="Progress message: Getting data from 3 new scans at 3 plots" width="295"></div>

1. Click **Get Data**.
2. A progress message counts the scans and plots being downloaded. Each scan
   brings its metrics, tree inventory and predictive model outputs.
3. When it finishes, the downloaded plots turn **blue**.

<div class="help-shot"><img src="static/help/images/selection-map-downloaded.png" alt="Base Map view: three downloaded plots in blue among plots that were not selected" width="780">
<span class="help-spot tip-right" tabindex="0" style="left:45.5%;top:34%">1<span class="help-tip"><b>Downloaded plot</b> (blue): its scans are loaded and ready on the other tabs.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:14.5%;top:55.5%">2<span class="help-tip"><b>Downloaded</b> in the legend.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:23%;top:46%">3<span class="help-tip">A plot that was not selected keeps its agency color.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:88%;top:13.5%">4<span class="help-tip"><b>Base Map</b> chosen: the plain background makes the markers easy to see.</span></span>
</div>

You can now go on to **Set Treatments** to enter treatment dates, or straight
to the graph tabs.

To add more plots later, select them and click **Get Data** again. Only scans
that are not already downloaded are fetched; the new ones are added to the
data you already have.

### Step 6: Change or clear the selection

Plots you have selected but not yet downloaded (gold) can be changed
freely:

- Click a gold plot, or its row in the **Table**, to take it out of the
  selection.
- Click **Clear All Plots** to clear all of them and start again.

Downloaded scans (blue) stay loaded until you remove them on purpose, so
the other tabs never lose data they are showing. Clicking a downloaded plot,
filtering it out, or using **Clear All Plots** leaves it loaded, and a
message says so. To remove downloaded scans:

- **Some scans:** select them in the table on the **Set Treatments** tab and
  click **Remove selected scans**.
- **All scans:** click **Clear All Downloads** below **Get Data**. A window
  asks you to confirm; it removes the data of every downloaded scan, with
  their unit names, remeasurement numbers and scan groupings, and clears the
  blue markers. Figures already added to the report are kept.

To use removed scans again, select them and click **Get Data**.

<div class="help-shot"><img src="static/help/images/selection-map-no-scans.png" alt="Warning: No scans selected. Click on a desired plot and set date range." width="293"></div>

If you click **Get Data** with nothing to download, this warning appears.
It also appears when every selected scan has already been downloaded.

## Map symbols

| Symbol | Meaning |
|---|---|
| Dot in an agency color | A plot that matches the filters; click it, or draw a shape around it, to select it |
| Gold dot | A selected plot |
| Blue dot | A plot whose scans are downloaded; it stays loaded until removed |
| Number beside a dot | The plot number, shown when zoomed in |

## Things to know

- **Selecting a plot selects all of its scans in the date range.** To leave a
  scan out, for example a late re-scan, narrow the date range so the scan
  falls outside it.
- **Changing the agencies or dates updates the selection.** Selected scans
  that no longer match are dropped, and the map zooms to fit the plots that
  match. Set the filters first, then select plots.
- **Downloaded data stay loaded.** Clearing the selection, unselecting a
  downloaded plot or changing the filters doesn't remove scans that are
  already downloaded, and the graph tabs keep showing them. Remove them with
  **Clear All Downloads**, or a few at a time on the Set Treatments tab.
- **If the IntELiMon server doesn't respond,** the tab opens with no plots
  and a red message, or **Get Data** says no scans were downloaded. Wait a
  few minutes, then reload the page or click **Get Data** again. A download
  that fails partway leaves nothing half-loaded.
- **Data last for one session.** Reloading the page or closing the browser
  tab clears all selections and downloads.
- **New selections get default settings.** Each selected plot is placed in a
  management unit called "My Unit". When you click **Get Data**, each plot's
  scans are numbered as remeasurements (0 for its first scan, 1 for its
  next, and so on) and all scans are sorted into scan groupings (time
  steps). Change them on the **Set Treatments** tab.
