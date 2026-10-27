# Fuels exports

## What this tab is for

Fuels exports turns the loaded scans into fuel inputs for fire behavior
modeling and investigating fuel loading by fuel type. It brings together the surface and canopy fuels measured or
modeled from the scans, works out surface fuel loadings in tons per acre,
and offers three ways to use them:

- **Submit fuels to rothRmel**: sends the loadings to the rothRmel tab, which
  estimates fire behavior for each scan.
- **Fuel raster export**: builds a LANDFIRE landscape around your plots,
  with the canopy adjusted toward what the scans measured, as an LCP file
  for FlamMap and FARSITE and a GeoTIFF for IFTDSS.
- **+ Report data**: adds any fuel card to the report.

The cards are filled with the average of the loaded scans or a subset
selected by the user. Every white box can be edited, so you can test what-if values or enter field measurements.

## The screen at a glance

Move the mouse over a numbered marker, or press Tab to step through them, to
see what each part does.

<div class="help-shot"><img src="static/help/images/fuels-overview.png" alt="The Fuels exports tab: fuel source settings on the left, the surface, canopy, time lag and mean fuel loading cards in the middle, and the map with export buttons on the right" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:20.6%;top:7.6%">1<span class="help-tip"><b>Fuel data source.</b> Fuels from the scans (Modeled/User defined) or LANDFIRE's standard fuel models (LANDFIRE derived).</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:20.6%;top:20.6%">2<span class="help-tip"><b>Point in time.</b> Which scans the cards average: each plot's most recent scan, all scans, or each plot's scan nearest a date.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:21.25%;top:44.3%">3<span class="help-tip"><b>Fuel model system.</b> Scott &amp; Burgan 40 or Anderson 13. The two are separate classifications, not interchangeable.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:60.4%">4<span class="help-tip"><b>From scan.</b> The LANDFIRE fuel model code most common among the scans.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:67.2%">5<span class="help-tip"><b>Override.</b> Pick a fuel model to use for every scan instead of each scan's own LANDFIRE code.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:37.5%;top:5.6%">6<span class="help-tip"><b>Surface fuels.</b> Mean fuel bed, litter and duff depth and bare ground. Blank by default if no predictive models exist.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:50%;top:5.6%">7<span class="help-tip"><b>+ Report data.</b> Adds this card's values to the report.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:55%;top:13.4%">8<span class="help-tip"><b>Editable box.</b> Prefilled with the scans' mean. Type a value to replace it; an empty box has no data.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:73%;top:5.6%">9<span class="help-tip"><b>Canopy fuels.</b> Not modeled: canopy measures from the scan and bulk density from LANDFIRE.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:40%;top:29.3%">10<span class="help-tip"><b>Time lag fuels.</b> Downed woody fuel counts per 40 m of transect, turned into tons per acre. Blank by default if no predictive models exist.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:59.5%;top:40.4%">11<span class="help-tip"><b>Tons/acre.</b> The load from each count, using Brown's (1974) equations.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:44.4%;top:47.6%">12<span class="help-tip"><b>Fuel model tag.</b> The fuel models behind the loadings; point at it to list their codes.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:53%;top:60.4%">13<span class="help-tip"><b>Derived from.</b> Where each dead fuel load comes from: Auto, the time lag count, or the fuel model scaled to the fuel bed depth.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:55%;top:85.6%">14<span class="help-tip"><b>Notes.</b> How many scans are averaged and where values had to fall back to another source.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:55%;top:96%">15<span class="help-tip"><b>Submit fuels to rothRmel.</b> Sends each scan's loadings and the canopy values to the rothRmel tab.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:68.5%;top:46.2%">16<span class="help-tip"><b>Drawing tools.</b> Draw a polygon or rectangle to widen the area the fuel raster covers; edit or delete it below.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:97%;top:30.3%">17<span class="help-tip"><b>Fuel raster export.</b> Builds the LANDFIRE landscape (LCP and GeoTIFF) around the plots.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:97%;top:37.5%">18<span class="help-tip"><b>Download FastFuels / FCCS.</b> Not available yet: these buttons don't do anything.</span></span>
</div>

1. **Fuel data source**: scan fuels or LANDFIRE fuels.
2. **Point in time**: which scans the cards average.
3. **Fuel model system**: Scott & Burgan 40 or Anderson 13.
4. **From scan**: the scans' most common LANDFIRE fuel model.
5. **Override**: one fuel model for every scan.
6. **Surface fuels** card. Blank by default if no predictive models exist.
7. **+ Report data**: add a card to the report.
8. **Editable box**: type to replace the scans' mean.
9. **Canopy fuels** card. Data from this card are not modeled, but are
   derived from canopy measures from the scan and bulk density from
   LANDFIRE.
10. **Time lag fuels** card. Blank by default if no predictive models exist.
11. **Tons/acre** from each count.
12. **Fuel model tag**.
13. **Derived from**: the source of each dead fuel load.
14. **Notes** on averages and fallbacks.
15. **Submit fuels to rothRmel**.
16. **Drawing tools** (polygon and rectangle) for the raster area.
17. **Fuel raster export**.
18. **Download FastFuels / FCCS**: not available yet.

## Step by step

1. Download scans on the **Selection Map**.
2. Choose the **Fuel data source** and **Point in time** in the left panel.
   The app picks Modeled/User defined when the scans have fuel bed depth or
   time lag fuel models, and LANDFIRE derived when they have neither.
3. Choose the **fuel model system** and, if needed, an **Override**.
4. Review the cards. Change any white box to use your own value.
5. Check the **Mean fuel loading** card and its notes.
6. Click **Submit fuels to rothRmel**, build a **Fuel raster export**, or
   add cards to the report with **+ Report data**.

## Fuel data source

**Modeled/User defined** uses the fuels from the scans: the fuel bed depth
and time lag counts predicted by the site's custom models, and the canopy
measured by the scanner. The LANDFIRE fuel model of each scan fills in what
the scans can't measure: live herbaceous and woody loads, the moisture of
extinction and any dead load without a count. The fuel model is scaled to
the measured fuel bed depth.

**LANDFIRE derived** uses each scan's standard LANDFIRE fuel model for the
whole surface fuel bed: its loads and its depth. The measured depths and
counts are shown but not used. Canopy fuels are always derived from TLS
canopy metrics and LANDFIRE canopy bulk density values, so these do not
change when LANDFIRE derived is selected.

<div class="help-shot"><img src="static/help/images/fuels-landfire-mode.png" alt="The tab in LANDFIRE derived mode: the canopy card keeps the scan values, and every surface load is derived from the standard fuel model" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:18.75%;top:10.9%">1<span class="help-tip"><b>LANDFIRE derived</b> selected.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:86%;top:13.4%">2<span class="help-tip">The <b>canopy</b> stays the scans' (TLS) values in both modes; only the surface fuels change.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:37.5%;top:50.5%">3<span class="help-tip">The tag now names the LANDFIRE fuel models.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:52.5%;top:58.8%">4<span class="help-tip">Every load is the fuel model's <b>Standard load</b>.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:55%;top:82.5%">5<span class="help-tip">The note says the measured depths and counts are not used.</span></span>
</div>

### Point in time

- **Most recent per plot**: each plot's latest scan.
- **Mean of all scans**: every loaded scan.
- **Nearest**: each plot's scan closest to the date in the box.

The point in time sets the averages on the cards and the canopy used by the
fuel raster. The loadings sent to rothRmel always include every scan, so
rothRmel can follow them through time.

### LANDFIRE fuel model

Each scan carries the LANDFIRE fuel model code of its location in both
systems: **Scott & Burgan 40** (LF_FBFM40) and **Anderson 13** (LF_FBFM13).
Pick the system you intend to model with; they are separate
classifications. **From scan** shows the code most common among the scans.
Use **Override** to apply one fuel model to every scan, for example when
LANDFIRE's model doesn't match what you see on the ground.

## The fuel cards

### Surface fuels

The mean **fuel bed depth**, **litter depth** and **duff depth** (cm) and
**bare ground**, from the site's custom models. The fuel bed depth feeds the
loadings; litter, duff and bare ground are for reference and the report. An
empty box means the scans have no model for that value.

### Time lag fuels

<div class="help-shot"><img src="static/help/images/fuels-timelag-loading.png" alt="The Time lag fuels card with counts and tons per acre, and the Mean fuel loading card with the source and mean of each load" width="282">
<span class="help-spot tip-left" tabindex="0" style="left:62.4%;top:11.7%">1<span class="help-tip"><b>Count</b> of pieces per 40 m of transect, predicted from the scan. Edit it to use your own.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:98%;top:11.7%">2<span class="help-tip"><b>Tons/acre</b> from Brown's equations, updated as you type.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:80%;top:47%">3<span class="help-tip"><b>Derived from.</b> Choose the source of each dead fuel load.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:35.5%;top:66.7%">4<span class="help-tip"><b>Total load</b> and the fuel bed depth and moisture of extinction that go with it.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:53%;top:83.3%">5<span class="help-tip"><b>Notes</b> on how the means were made.</span></span>
</div>

The mean predicted count of 1-, 10-, 100- and 1000-hour fuel pieces a crew would tally
along 40 m of transect, as predicted by the site's custom models. Each count
is turned into tons per acre with the planar intersect equations of Brown
(1974), and the **Total** adds them up. Change a count to see its load; an
edited count replaces every scan's count in the Mean fuel loading card.

### Canopy fuels

The mean **canopy base height**, **mean tree height**, **average maximum
tree height** (m) and **canopy cover** (%) measured by the scanner, and the
**LANDFIRE canopy bulk density**. Bulk density is shown as LANDFIRE stores
it, in kg/m³ × 100 (7 means 0.07 kg/m³). These values travel with the fuels
submitted to rothRmel, and an edited canopy base height, cover or maximum
height shifts the canopy of the fuel raster.

### Mean fuel loading

This card shows the surface fuel loadings the fire model uses, in tons per
acre, averaged over the scans of the chosen point in time:

| Row | Where it comes from |
|---|---|
| 1-, 10-, 100-hour | The time lag count, or the fuel model scaled to the fuel bed depth (see below) |
| Live herb, live woody | The fuel model scaled to the fuel bed depth |
| Total load | The sum of the loads |
| Fuel bed depth (ft) | The measured depth, or the fuel model's depth when there is none |
| Dead Mx (%) | The fuel model's dead fuel moisture of extinction |
| Canopy (CBH · CC · CBD) | The Canopy fuels card |
| 1000-hour, duff | For reference; the Rothermel model doesn't use them |

In Modeled/User defined mode, the **Derived from** list sets the source of
each dead fuel load:

- **Auto** (the default): the time lag count, unless the scan has no count,
  or has a grass fuel model whose count is close to zero (transects barely
  register grass). Then it uses the fuel model × depth.
- **Time lag count**: always the count, using Brown's equations or user
  edited fields.
- **Fuel model × depth**: always the fuel model scaled to the fuel bed
  depth.

The notes under the table say how many scans are averaged and where a value
fell back to another source. A red note warns when a fuel model is
non-burnable: those scans carry no fuel, and rothRmel returns zero spread
for them.

## Submit fuels to rothRmel

<div class="help-shot"><img src="static/help/images/fuels-submitted.png" alt="Message: Submitted to rothRmel: Per-scan loadings, mean 5.35 t/ac (most recent per plot) (10 scans, each with its own loadings)." width="250"></div>

Click **Submit fuels to rothRmel** to send every scan's own loadings, with
the canopy values, to the rothRmel tab. A message confirms what was sent,
and the box under the button shows it with the time:

<div class="help-shot"><img src="static/help/images/fuels-submit-status.png" alt="Status box: Submitted. Per-scan loadings, mean 5.35 t/ac (most recent per plot), Modeled / user defined, 14:54:52" width="270"></div>

To use them, set **Surface fuel source** on the rothRmel tab to **Fuel tool
values**. Submit again after any change here; rothRmel keeps the last
values submitted.

## Fuel raster export

The fuel raster is a landscape for fire models: elevation, slope, aspect,
fuel model, canopy cover, stand height, canopy base height and canopy bulk
density, from LANDFIRE (LF2024 fuels and canopy, LF2020 topography).

<div class="help-shot"><img src="static/help/images/fuels-aoi-map.png" alt="The map with a drawn area of interest rectangle, the drawing tools and the export buttons" width="280">
<span class="help-spot tip-right" tabindex="0" style="left:16%;top:26.5%">1<span class="help-tip"><b>Draw a shape.</b> The rectangle tool: click, then drag on the map. The polygon tool sits above it: click each corner, then the first corner again to close.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:16%;top:39%">2<span class="help-tip"><b>Edit</b> or <b>delete</b> the shape.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:34%;top:54%">3<span class="help-tip">The <b>area of interest</b>. The landscape covers it as well as the plots.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:80%;top:4%">4<span class="help-tip"><b>Fuel raster export</b> builds the landscape.</span></span>
</div>

1. **Optional:** draw an area of interest. Click the square tool on the map
   and drag a rectangle, or click the pentagon tool and click each corner of
   a polygon, then the first corner again to close it. A message confirms
   its size. The landscape always covers the selected plots plus 2 km around
   them; the shape widens it to the shape's full extent, and the canopy
   corrections are worked out over the area inside the shape.
2. Click **Fuel raster export**.
3. Enter a contact email the first time. LANDFIRE requires one for every
   request:
   <div class="help-shot"><img src="static/help/images/fuels-email-prompt.png" alt="Dialog: Email address required. LANDFIRE requires a contact email to build the landscape file." width="312"></div>
4. The landscape is built in the background; LANDFIRE can take a few
   minutes, and you can keep using the app.
5. A **Fuel rasters ready** window opens with what was adjusted. Save the
   **LCP (.zip)**, the **GeoTIFF (.tif)**, or **both** in one .zip.

| File | Use |
|---|---|
| LCP (.zip) | The .lcp landscape and its .prj projection, for FlamMap and FARSITE |
| GeoTIFF (.tif) | The same landscape for IFTDSS as a custom landscape, with LANDFIRE FCCS fuelbeds and map zones added when LANDFIRE supplies them |

**How the scans change the landscape:**

- LANDFIRE's canopy cover, stand height and canopy base height across the
  area are adjusted toward the values the scans measured, and the scans' own
  values are written into a 30 m circle around each plot. Canopy base height
  is kept below stand height. The ready window lists each adjustment. This
  happens with either fuel data source.
- The **fuel model** layer is always LANDFIRE's. The surface fuels on this
  tab go to rothRmel only, not into the raster.

## + Report data

Each fuel card has a **+ Report data** button in its top right corner. It
adds the card to the report as a table:

| Card | What goes in the report |
|---|---|
| Surface fuels | Each measure with the value showing and the scans' mean beside it |
| Canopy fuels | Each measure with the value showing and the scans' mean beside it |
| Time lag fuels | Each class's count and tons per acre, the total, and the scans' mean count |
| Mean fuel loading | Each load with where it was derived from, the total load, fuel bed depth and dead moisture of extinction |

Each table records the fuel data source, the point in time and the number of
scans behind it, and a short description lists any values you edited. For
the Time lag fuels and Mean fuel loading cards, the report also explains
Brown's equations and the fuel model system used, with their references. A message confirms the addition, with the number of items
now in the report. Arrange the report on the **Report builder** tab.

## Download FastFuels and Download FCCS

These two buttons are not available yet; clicking them does nothing.

## Things to know

- **Scan fuels are model predictions.** Fuel bed depth and time lag counts
  come from site-level custom models calibrated with field data, not from
  direct measurement. They carry model error that the cards don't show, and
  they are not validated outside the site and conditions of the data used to
  build them, for example after a severe burn. Confirm important values in
  the field. Sites without those models have empty boxes here.
- **Edits apply to every scan.** A box you change replaces that value for
  every scan in the loadings and the raster. Leave a box at its prefilled
  value to keep each scan's own.
- **Check the fuel model.** Loads that come from the fuel model (live fuels,
  moisture of extinction, missing counts) are only as good as the model.
  Compare **From scan** with conditions on the ground, and use **Override**
  if it doesn't fit.
- **One very large stem or count can dominate a mean.** Check the cards
  against the plots before you submit or export.
- **Raster builds need an internet connection** to LANDFIRE and a contact
  email. If LANDFIRE has no data for part of the area, the GeoTIFF notes
  it; IFTDSS rejects landscapes with too many cells missing.
