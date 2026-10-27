# Forestry exports

<p class="help-warning"><strong>Tree species are not measured by the
scanner. The species on this tab come from the species mix you enter and are
assigned to stems by a rule, so per-species results and FVS growth depend on
that choice. The FVS files have not been tested in a live FVS run: check them
against the FVS documentation for your variant before relying on a
projection.</strong></p>

## What this tab is for

The Forestry exports tab has two modes, a single plot inventory mode and a
generative area of interest mode. **Plot inventory** mode works with the
trees detected in each scan. For one scan at a time it:

- maps every detected stem, sized by diameter;
- calculates stand metrics (density, basal area, quadratic mean diameter,
  stand density index, relative density and crown ratio), corrected for the
  part of the plot hidden from the scanner;
- lets you try a thinning prescription and see the residual stand; and
- exports a tree list, stand record and keyword file for the **Forest
  Vegetation Simulator (FVS)**.

Each of the stand metrics and outputs is updated to reflect the prescription
applied to the scan, and the outputs can be used in the Report builder.

A second mode, **Generative AOI map**, simulates a stem map across a larger
area from the structure of the loaded plots or an individual plot. This map
can then be edited for scale and pattern and used to generate FVS inputs.

## The screen at a glance

Move the mouse over a numbered marker, or press Tab to step through them, to
see what each part does.

<div class="help-shot"><img src="static/help/images/forestry-overview.png" alt="The Forestry exports tab: settings on the left, the stem map in the middle, the tabbed stand card at the top right and the Points2Pano viewer at the bottom right" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:9.9%">1<span class="help-tip"><b>Mode.</b> Plot inventory (one scan) or Generative AOI map (a simulated area).</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:3%;top:17.7%">2<span class="help-tip"><b>Scan.</b> The scan shown. Use ◀ and ▶ to step through the scans with tree inventories; the Points2Pano viewer follows.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:30.7%">3<span class="help-tip"><b>Plot radius.</b> The radius of the plot used for the full plot area (15 m by default).</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:3%;top:37.5%">4<span class="help-tip"><b>Plot area.</b> The full area, the unoccluded area (nonocarea) visible to the scanner, and the share visible.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:46.7%">5<span class="help-tip"><b>Scale per-area values by.</b> The visible area (corrected, recommended) or the full plot area.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:59.6%">6<span class="help-tip"><b>Species mix.</b> FVS species codes and their share of the stems, adding up to 100%.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:77.9%">7<span class="help-tip"><b>+ Add species.</b> Adds a row, up to six species.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:85.3%">8<span class="help-tip"><b>Assignment rule.</b> How species are given to stems: at random, by size or in patches.</span></span>
<span class="help-spot tip-right tip-up" tabindex="0" style="left:22.5%;top:91.4%">9<span class="help-tip"><b>Prescription.</b> A thinning to try. Scroll down for its settings and the FVS options.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:44.4%;top:5.5%">10<span class="help-tip"><b>Color by.</b> Color the stems by species, diameter or crown ratio.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:47.9%;top:3.8%">11<span class="help-tip"><b>Stem count.</b> Stems detected and stems marked for removal.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:65%;top:3.8%">12<span class="help-tip"><b>+ Report data.</b> Adds the stem map, as shown, to the report.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:52.5%;top:48.4%">13<span class="help-tip"><b>Stem map.</b> Each dot is a stem, sized by diameter. The + is the scanner.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:60.3%;top:36%">14<span class="help-tip"><b>Plot rings.</b> The dashed ring is the plot radius; the solid ring has the same area as the part visible to the scanner.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:90.5%;top:7.8%">15<span class="help-tip"><b>Tabs.</b> Metrics, Species, Stocking, Size bias and FVS.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:80.8%;top:3.6%">16<span class="help-tip"><b>+ Report data.</b> Adds the open tab to the report.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.5%;top:3.6%">17<span class="help-tip"><b>Download.</b> The open tab as CSV data; Stocking and Size bias also as SVG or PNG images.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:87.5%;top:19%">18<span class="help-tip"><b>Stand metrics.</b> Per acre, after the prescription when there is one.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:95%;top:36.8%">19<span class="help-tip"><b>Occlusion correction.</b> The metrics with the full plot area and with the visible area. Scroll the tab for the summary of how much of the plot was visible and how stocked the stand is.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:67.9%;top:42%">20<span class="help-tip"><b>Expand.</b> Shows the tabbed card full screen; the charts grow to fill it. Press <b>Close</b> to return.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.5%;top:49.7%">21<span class="help-tip"><b>Scan label.</b> The site, plot, date and scanner of the panorama. It follows the scan chosen in the left panel, and stepping it with ◀ and ▶ changes the stem map and metrics to that scan too.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:81%;top:67%">22<span class="help-tip"><b>Points2Pano viewer.</b> A 360° panorama made from the scan. Use the viewer's own controls to look around.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:89%;top:90%">23<span class="help-tip"><b>+ Report data.</b> In the lower right of the panorama: adds a photo of the plot showing to the report.</span></span>
</div>

1. **Mode**: plot inventory or generative map.
2. **Scan**: step through the scans with ◀ and ▶ (the panorama follows).
3. **Plot radius**. Editable, but occlusion does not scale in proportion.
4. **Plot area**: full, visible and the share visible.
5. **Scale per-area values by**: visible or full area.
6. **Species mix** (predicted).
7. **+ Add species**. Edits in additional species.
8. **Assignment rule**. Species to stem assignment (random, by size, in
   clusters).
9. **Prescription**. Applied thinning methods and options, with the FVS
   options below it.
10. **Color by**: species, diameter or crown ratio (not directly measured).
11. **Stem count**.
12. **+ Report data** for the stem map.
13. **Stem map**.
14. **Plot rings**. Dashed for the plot extent, solid to represent the area
    not occluded.
15. **Tabs** of the top right card for different forestry metrics.
16. **+ Report data** for the open tab.
17. **Download** the open tab (CSV, and SVG or PNG for the charts).
18. **Stand metrics**. Dynamic, based on the prescription.
19. **Occlusion correction** table. Occlusion uncertainty reporting; scroll
    for the summary.
20. **Expand** the top right card to full screen.
21. **Scan label** of the panorama, linked to the scan in the left panel.
22. **Points2Pano viewer**.
23. **+ Report data** for the panorama.

## Step by step

1. Download scans on the **Selection Map**. Each scan brings its tree
   inventory.
2. Pick a scan with **◀** and **▶**.
3. Check the **Plot radius** and leave **Scale per-area values by** on
   **Unoccluded area (nonocarea) (corrected)**.
4. Enter the **Species mix** for the stand and pick an **Assignment rule**.
5. Read the stand metrics on the **Metrics** tab.
6. **Optional:** choose a **Prescription** and its settings, and compare
   the stand before and after.
7. Set the **FVS** options and download the FVS files, or add the stem map
   and tabs to the report.

## Correcting for hidden trees: unoccluded area

A single scan from plot center can't see behind every trunk and bush, so
part of the plot is hidden. The processing pipeline reports the area the
scanner could see as the **unoccluded area** (IntELiMon metric
`nonocarea`). Dividing stem counts and basal area by
this visible area, rather than by the full plot area, corrects density and
basal area for the trees the scanner couldn't see. Quadratic mean diameter
is a ratio of sizes and doesn't change.

The **Occlusion correction** table on the Metrics tab compares both, and the
summary below it (scroll the tab) says how much of the plot was visible. If a scan has no unoccluded area,
the full plot area is used and per-area values may be too low.

## Species mix

The scanner records stem positions, diameters and heights, but not species.
Enter the species of the stand as **FVS species codes** (for example `DF` for
Douglas-fir or `LP` for loblolly pine) with their share of the stems. The
codes must be valid for the FVS variant you export to. The **Total** turns
red unless the shares add up to 100%.

The **Assignment rule** decides which stem gets which species:

| Rule | Effect |
|---|---|
| Random (ratio only) | Each stem gets a species at random, in the ratio entered |
| By size class | The largest stems go to the first species, then down the list |
| Spatially clustered | Each species occupies its own patches of the plot |

All three give the same stand-level shares; they differ in which stems are
which species, and so in per-species metrics and FVS growth.

## Prescriptions

<div class="help-shot"><img src="static/help/images/forestry-prescription.png" alt="Thin from below to 120 ft² per acre: 23 of 35 stems marked with a red x, and the metrics showing the residual stand" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:59%">1<span class="help-tip"><b>Method</b>: Thin from below, with a residual basal area of 120 ft²/ac.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:58.75%;top:40%">2<span class="help-tip"><b>Marked stems</b> are hollow with a red ×.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:45.6%;top:44.2%">3<span class="help-tip"><b>Kept stems</b> stay filled.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:47.9%;top:3.8%">4<span class="help-tip">23 of 35 stems are <b>marked</b> for removal.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:87.5%;top:19%">5<span class="help-tip">The metrics now describe the <b>residual stand</b>.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.5%;top:40%">6<span class="help-tip">Scroll the Metrics tab for the <b>stocking summary</b>: residual SDI as a share of the maximum.</span></span>
</div>

| Method | What it marks |
|---|---|
| None - inventory only | Nothing |
| Thin from below | The smallest stems first, until the basal area reaches **Residual BA** |
| Thin from above | The largest stems first, until the basal area reaches **Residual BA** |
| By species | Every stem of the species chosen in **Remove species** |
| Spacing / crop-tree | Keeps the largest stems at least **Minimum spacing** apart and marks the rest |

Marked stems are drawn hollow with a red ×, and the metrics, species table,
stocking chart and FVS tree list switch to the residual stand. The
**Prescription** summary gives the residual stand density index as a share
of a maximum of 450:

- below 35%: below full stocking, so understory response is likely;
- 35 to 55%: the managed zone, with full occupancy and no imminent
  self-thinning;
- above 55%: past the onset of self-thinning, so competition mortality is
  likely.

The maximum of 450 is a general value, not specific to your species or
region.

## The top right card

The card at the top right holds five tabs: Metrics, Species, Stocking, Size
bias and FVS. Above the tabs:

- **+ Report data** adds the open tab to the report (see below).
- **Download** saves the open tab:

  <div class="help-shot"><img src="static/help/images/forestry-download.png" alt="The Download menu of the top right card open on the Size bias tab: CSV data, SVG image and PNG image" width="253"></div>

  - **CSV data** on every tab: the stand metrics, the species table, the
    stocking values (trees per acre, QMD and SDI before and after the
    prescription), the stems detected and inferred missing in each diameter
    class, or the FVS settings.
  - **SVG image** and **PNG image** on the Stocking and Size bias tabs: the
    chart on a white background, for documents and slides.

  Files are named after the tab and the scan, for example
  `forestry_size_bias_CASDU_0003_2025-01-24.png`.

The **Expand** button in the card's lower left corner shows it full screen,
with the charts enlarged; press **Close** to return.

### Metrics

| Metric | Meaning |
|---|---|
| Density | Trees per acre |
| Basal area | Stem cross-section per acre (ft²/ac) |
| QMD | Quadratic mean diameter (in) |
| SDI | Stand density index (Reineke, 1933) |
| Rel. density | Relative density (Curtis, 1982) |
| Mean CR | Mean crown ratio (%), from tree height and the scan's canopy base height |

### Species

<div class="help-shot"><img src="static/help/images/forestry-species.png" alt="The Species tab: trees, share of stems, basal area, QMD and stems removed for each species" width="253"></div>

For each species: number of trees, share of stems, basal area, QMD and the
number marked for removal.

### Stocking

<div class="help-shot"><img src="static/help/images/forestry-stocking.png" alt="The Stocking chart: trees per acre against QMD with SDI lines at 450, 55% and 35%, and the stand before and after the prescription" width="253"></div>

Trees per acre against QMD, with lines at the maximum SDI of 450 and at 55%
and 35% of it. The orange point is the stand before the prescription and the
cyan point after it, joined by an arrow.

### Size bias

<div class="help-shot"><img src="static/help/images/forestry-size-bias.png" alt="The Size bias chart: stems detected and inferred missing by diameter class" width="253"></div>

Small stems are more likely to be hidden than large ones, so the smallest
diameter classes stay under-counted even after the unoccluded area correction. The
chart shows the stems detected in each 2-inch class and an estimate of those
missed. It is indicative only and is not applied to the metrics.

### FVS

<div class="help-shot"><img src="static/help/images/forestry-fvs.png" alt="The FVS tab previewing the first rows of the tree list and the keyword file" width="253"></div>

A preview of the first 12 records of the tree list and of the keyword file,
built from the current settings. Download the files from the left panel.

## Points2Pano viewer

The card at the bottom right shows the Points2Pano panorama of a selected
scan: a 360° view made from the scan's points, useful for checking the stem
map against what the plot looks like.

- The label at the top shows the site, plot, scan date and scanner. Use
  **◀** and **▶** to step through the selected scans.
- The viewer is **linked to the scan shown**: picking a scan with ◀ and ▶
  in the left panel moves the panorama to the same scan, and stepping the
  viewer to a scan with a tree inventory shows that scan's stem map and
  metrics too. Scans without a tree inventory can still be viewed; the
  stem map then stays on the last scan with one.
- **+ Report data**, in the lower right corner of the panorama, adds an
  image of the default view of the plot to the report.
- In a narrow card the scan label is shortened with "…". Use the card's
  **Expand** button to see it in full.

## FVS export

<div class="help-shot"><img src="static/help/images/forestry-fvs-settings.png" alt="The FVS settings and download buttons at the bottom of the left panel" width="190">
<span class="help-spot tip-left" tabindex="0" style="left:89.5%;top:30%">1<span class="help-tip"><b>Variant.</b> The FVS geographic variant to run.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:89.5%;top:39.2%">2<span class="help-tip"><b>Site index</b> of the stand.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:89.5%;top:52%">3<span class="help-tip"><b>Cycles</b> and <b>cycle length</b> of the projection.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:89.5%;top:65%">4<span class="help-tip"><b>Slope</b> and <b>aspect</b> of the stand.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:89.5%;top:75.9%">5<span class="help-tip"><b>Options:</b> fire and fuels extension, lidar crown ratio, prescription as keyword.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:89.5%;top:88%">6<span class="help-tip"><b>Downloads.</b> Tree list, stand record, keyword file and stem list.</span></span>
</div>

Scroll to the bottom of the left panel for the FVS settings:

| Setting | Meaning |
|---|---|
| Variant | The FVS geographic variant: SN, CS, AK, CR, PN, NE or SO |
| Site index | Site index of the stand |
| Cycles, Cycle length (yr) | How many growth cycles to project, and how long each is |
| Slope (%), Aspect (deg) | Slope and aspect of the stand |
| FFE-FVS (fire & fuels) | Adds the Fire and Fuels Extension to the keyword file |
| Use lidar crown ratio | Uses each tree's crown ratio from the scan instead of letting FVS estimate it |
| Write prescription as keyword | Adds the prescription to the keyword file as an FVS thinning keyword |

The downloads, named after the site and plot:

| File | Contents |
|---|---|
| FVS_TreeInit (CSV) | One record per kept stem: diameter, height, crown ratio, species and the trees per acre each stem represents (from the visible area) |
| FVS_StandInit (CSV) | The stand record: inventory year, plot size, variant, site species and index, slope and aspect |
| Keyword file (.key) | The FVS run settings for the stand |
| Stem list (CSV) | Every detected stem with its position, species and whether it is marked for removal |

## Generative AOI map

<p class="help-warning"><strong>The generative map is simulated, not
measured. It spreads the structure of the scanned plots across the area you
set. Check its canopy cover against independent airborne lidar or LANDFIRE
before using it.</strong></p>

<div class="help-shot"><img src="static/help/images/forestry-generative.png" alt="Generative AOI map mode: area, fitted structure and pattern settings on the left and a simulated stem map of 400 by 300 m" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:17.7%">1<span class="help-tip"><b>Source.</b> The stems of the shown scan only, or of all loaded scans pooled.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:33.7%">2<span class="help-tip"><b>Area of interest</b> width and height, in meters.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:24.4%;top:54.7%">3<span class="help-tip"><b>Fitted structure.</b> Density and the Weibull diameter distribution fitted to the source stems.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:62.5%">4<span class="help-tip"><b>Override fitted values</b> to enter your own density and Weibull shape and scale.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:69.5%">5<span class="help-tip"><b>Spatial pattern.</b> Clustered, random or regular (plantation).</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:79%">6<span class="help-tip"><b>Clumping strength.</b> How many stems form each cluster.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:22.5%;top:85.9%">7<span class="help-tip"><b>Re-roll simulation.</b> A new random stem map with the same settings.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:48.75%;top:51.6%">8<span class="help-tip">The <b>simulated stem map</b>, labeled "SIMULATED - not measured".</span></span>
</div>

1. Set **Mode** to **Generative AOI map**.
2. Choose the **Source**: the scan shown, or all loaded scans pooled.
3. Enter the **width** and **height** of the area in meters.
4. Check the **Fitted structure**: the density (stems per hectare, from the
   visible area) and the Weibull shape and scale of the diameters. Tick
   **Override fitted values** to use your own.
5. Pick a **Spatial pattern** and, for clustered, a **Clumping strength**.
6. Click **Re-roll simulation** for a different random map.
7. Download the **Generated stems (CSV)** or **FVS stands (CSV)**. Both are
   labeled as simulated.

## + Report data

- The button above the **stem map** adds it, as shown, to the report.
- The button on the **top right card** adds the open tab: Metrics adds the
  stand metrics and occlusion correction tables, Species its table, and
  Stocking and Size bias their charts, and FVS a table of the export
  settings (variant, site index, cycles, options and number of tree records).
  Download the FVS files themselves from the left panel.
- The button on the **Points2Pano** panorama adds a photo of the plot.
- Each item brings its methods and citations into the report's "About these
  data" section and References: the unoccluded area correction (Murphy et
  al., 2024; Pokswinski et al., 2026), stand density index (Reineke, 1933)
  and relative density (Curtis, 1982), species assignment, the size bias
  estimate, the simulated stem map (Bailey and Dell, 1973; Neyman and Scott,
  1958), FVS (Dixon, 2002) and, when ticked, the Fire and Fuels Extension
  (Reinhardt and Crookston, 2003).

## Things to know

- **Species are assigned, not measured.** Per-species numbers reflect the
  species mix and rule you chose.
- **Small trees are under-counted.** See **Size bias**.
- **Watch for outlier stems.** A single misdetected stem with a very large
  diameter can dominate basal area. A thinning to a residual basal area
  below that one stem's share then removes every stem, the large one last.
  If a prescription removes everything, look for an unusually large dot on
  the stem map.
- **The tree list already leaves out marked stems.** With **Write
  prescription as keyword** ticked, the keyword file also asks FVS to thin,
  so FVS thins the residual stand a second time. Untick it when you export
  a thinned tree list.
- **Check the FVS files.** Keyword spellings and field widths vary between
  FVS versions and variants, and the files have not been run in FVS here.
- **Defaults are for the Southern variant.** The default species (LP, SA,
  WO) and variant (SN) suit southern pine stands. Change them for other
  regions.
