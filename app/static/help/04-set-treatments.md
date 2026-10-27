# Set Treatments

## What this tab is for

Set Treatments lists the scans selected on the Selection Map. This tab is
used to examine the scans that have been downloaded, provide context to
them, and remove scans you no longer need.

- **Treatment dates** record when a treatment, such as a prescribed burn or
  a thinning, took place, and **what was done**. The graph tabs use the
  dates to separate pre- and post-treatment scans into different time steps
  and draw them as treatment lines. The report builder uses the dates and
  treatment types to describe the treatments and the scans around them.
- **Management unit names** group plots into the units you manage, such as
  "Burn Unit A".
- **Remeasurement numbers** count the visits to each plot: 0 for its first
  scan, 1 for its next scan, and so on, however close together the scans
  are. They are set automatically, and you can correct them here.
- **Scan groupings** gather the scans from one round of scanning into a
  time step. The graph tabs and the report compare scan groupings, so they
  decide which scans are averaged together. They are set automatically, and
  any you change here are used on every graph tab and in the report.

The table has one row per scan:

| Column | Meaning |
|---|---|
| site, plot | Where the scan was taken |
| date | When the scan was taken |
| scanner_id | The scanner type used to take the scan |
| Unit | The management unit name ("My Unit" until you name it) |
| Remeasurement | The visit number of the plot: 0 for its first scan |
| Scan grouping | The time step the scan belongs to, from 1 |

## The screen at a glance

Move the mouse over a numbered marker, or press Tab to step through them, to
see what each part does.

<div class="help-shot"><img src="static/help/images/set-treatments-overview.png" alt="The Set Treatments tab: the scan table with Remove selected scans above it on the left, and the Add Treatment Dates and Set Unit Name, Remeasurement or Scan Grouping panels on the right" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:26.9%;top:20%">1<span class="help-tip"><b>Column headings.</b> Sort the table by heading type: click one to sort by that column; click again to reverse the order.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:48.3%;top:23.9%">2<span class="help-tip"><b>Column filters.</b> Type or pick a value to show only the matching rows.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:9.8%;top:16.4%">3<span class="help-tip"><b>Rows.</b> How many scans are listed, and how many are hidden by the filters.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:37.5%;top:32.3%">4<span class="help-tip"><b>Scans.</b> Click a row to select it; click it again to unselect it. Select rows before you click Assign or Remove selected scans.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:48.1%;top:39.8%">5<span class="help-tip"><b>Unit.</b> Every scan starts in "My Unit". Give your units their own names.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:56.9%;top:47.2%">6<span class="help-tip"><b>Remeasurement.</b> The visit number of each plot, starting at 0: each plot here was scanned twice, so its scans are 0 and 1.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:68.5%;top:54.8%">7<span class="help-tip"><b>Scan grouping.</b> The time step of each scan, starting at 1. The graph tabs and the report average the scans of each grouping together.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:12.5%;top:9.5%">8<span class="help-tip"><b>Clear selection.</b> Unselects every row in the table.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:58.8%;top:5.1%">9<span class="help-tip"><b>Remove selected scans.</b> Removes the selected scans and their downloaded data from the session, after asking you to confirm.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:95%;top:26.2%">10<span class="help-tip"><b>Select Date.</b> Opens a calendar to pick a treatment date.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:95%;top:33.3%">11<span class="help-tip"><b>Treatment.</b> What was done on the date. Pick one or more types; optional.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.25%;top:37.7%">12<span class="help-tip"><b>Add Date.</b> Adds the date and its treatment to the Treatment dates list.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.25%;top:47.4%">13<span class="help-tip"><b>Treatment dates.</b> The dates and treatments added so far. Click one to select it.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:94.6%;top:53.4%">14<span class="help-tip"><b>Delete.</b> The trash can deletes the treatment date selected above it.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:95%;top:82.5%">15<span class="help-tip"><b>Unit Name.</b> The name to give the selected scans.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:95%;top:88.4%">16<span class="help-tip"><b>Scan Remeasurement.</b> The remeasurement number to give the selected scans.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:95%;top:94.3%">17<span class="help-tip"><b>Scan Grouping.</b> The scan grouping to give the selected scans. The <b>Assign</b> button is below it.</span></span>
</div>

1. **Column headings**: sort the table by heading type.
2. **Column filters**: show only matching rows.
3. **Rows**: how many scans are listed.
4. **Scans**: click rows to select them.
5. **Unit**: the management unit of each scan.
6. **Remeasurement**: the visit number of each plot.
7. **Scan grouping**: the time step of each scan.
8. **Clear selection**: unselect all rows.
9. **Remove selected scans**: remove the selected scans and their data.
10. **Select Date**: pick a treatment date.
11. **Treatment**: pick what was done on that date.
12. **Add Date**: add the date and treatment to the list.
13. **Treatment dates**: the dates and treatments added so far.
14. **Trash can**: delete the treatment date selected in the list.
15. **Unit Name**: the name to assign.
16. **Scan Remeasurement**: the remeasurement number to assign.
17. **Scan Grouping**: the scan grouping to assign, then **Assign**.

## Sorting and filtering the table

Sorting and filtering only change what you see. They help you find and
select scans for management unit assignment or to choose management dates.

- **Sort:** click a column heading. The arrow shows the direction; click
  again to reverse it. Hold **Shift** and click a second heading to sort by
  both columns. The table starts sorted by date, then site, then plot.
- **Filter:** click the box under a column heading and type or pick a
  value. Only matching rows stay in the table. Clear the box, or click the
  ⊗ under it, to show every row again.
- **Rows:** the line above the table counts the scans listed, and how many
  the filters hide.

The sort order, the filters and the selected rows stay as they are after you
click **Assign**, so you can keep working on the same scans.

## Name management units

<div class="help-shot"><img src="static/help/images/set-treatments-assign-unit.png" alt="The table filtered to site CASDU, all six CASDU scans selected, and Burn Unit A typed as the unit name" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:8.25%;top:23.9%">1<span class="help-tip"><b>Filter</b> the site column to CASDU so only that site's scans are listed.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:6.9%;top:20%">2<span class="help-tip">The arrow shows the table is <b>sorted</b> by site.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:37.5%;top:38.2%">3<span class="help-tip"><b>Selected rows</b> are highlighted. Click each row you want to name.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:95%;top:82.5%">4<span class="help-tip">Type the <b>unit name</b>.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:95%;top:97.9%">5<span class="help-tip">Click <b>Assign</b> to give the selected scans the name.</span></span>
</div>

1. Narrow the table to the scans of one unit, for example by filtering the
   **site** column (1) or sorting by site (2).
2. Click each scan of the unit to select it (3). Selected rows are
   highlighted. Click a row again to unselect it, or use **Clear
   selection** to start over.
3. Type the name in **Unit Name** (4).
4. Click **Assign** (5). The name appears in the **Unit** column of every
   selected scan.

Repeat for each unit. You can also double-click a single **Unit** cell, type
a new name and press **Enter** (or click elsewhere) to change one scan.

**Naming tips**

- Be precise in the naming of your management unit; this unit name is used
  in the Report builder as printed here.
- Spell a unit's name exactly the same way every time. "Unit A" and "unit A"
  are counted as two different units.
- Give every scan of a plot the same unit, so the report lists the plot
  under one unit.
- Scans left as "My Unit" are treated as not assigned to a unit.

## Add treatment dates

<div class="help-shot"><img src="static/help/images/set-treatments-calendar.png" alt="The Select Date calendar open on October 2026" width="200"></div>

1. Click the **Select Date** box. A calendar opens.
2. Use **«** and **»** to change the month, or click the month name to jump
   between months and years. Click the day of the treatment.
3. Alternatively, edit the date in the date box in YYYY-MM-DD format.
4. Click the **Treatment** box and pick what was done on that date. Pick
   more than one for a combined treatment, such as **Thinning** and
   **Piling and burning**. Remove a pick with Backspace. The treatment is
   optional, but the report can only describe treatments it knows.

   <div class="help-shot"><img src="static/help/images/set-treatments-type.png" alt="The Treatment list open under the date: Prescribed fire, Thinning, Piling and burning, Mastication, Herbicide, Grazing, Planting and seeding, Disking and plowing" width="176"></div>

5. Click **Add Date**. The date and its treatment appear in the
   **Treatment Dates** list, and the **Treatment** box is cleared for the
   next date.

The treatment types are:

| Treatment | What it is |
|---|---|
| Prescribed fire | Planned burning under set weather and fuel conditions to meet management objectives, usually to reduce surface fuels and the low vegetation that carries fire into the canopy |
| Thinning | Removal of selected trees to reduce stand density or change stand structure |
| Piling and burning | Gathering cut material or surface fuels into piles that are burned, often after thinning |
| Mastication | Mechanical shredding or chipping of shrubs and small trees, leaving the material on the ground as a compact fuel bed |
| Herbicide | Chemical control of unwanted vegetation |
| Grazing | Use of livestock to reduce herbaceous and shrub vegetation |
| Planting and seeding | Establishing trees, shrubs or herbaceous plants by planting or sowing |
| Disking and plowing | Mechanical cultivation that breaks up vegetation and the soil surface and mixes plant material into the soil |

Adding or deleting a date regroups every scan, which replaces any scan
groupings you entered by hand. Add your treatment dates before correcting
scan groupings.

Add one date for each treatment. If the date is already in the list, a
"Date already added" warning appears.

<div class="help-shot"><img src="static/help/images/set-treatments-date-added.png" alt="After adding a prescribed fire on 2025-05-15: the date and treatment are listed under Treatment Dates" width="800">
<span class="help-spot tip-left" tabindex="0" style="left:95%;top:26.2%">1<span class="help-tip">The <b>treatment date</b> picked in the calendar: 2025-05-15.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:95%;top:33.3%">2<span class="help-tip">The <b>Treatment</b> box: Prescribed fire was picked, and the box was cleared when the date was added.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96.25%;top:37.7%">3<span class="help-tip"><b>Add Date</b> was clicked.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:76.2%;top:49.2%">4<span class="help-tip">The date and its <b>treatment</b> are now in the Treatment dates list.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:56.9%;top:36%">5<span class="help-tip"><b>Remeasurement</b> numbers don't change: they count each plot's visits, before or after a treatment.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:68.5%;top:47.2%">6<span class="help-tip"><b>Scan grouping.</b> Scans after the date start a new grouping. Here more than 30 days already separated them, so the groupings stay 1 to 4.</span></span>
</div>

When you add a date:

- Scans collected on or after it start a new **Scan grouping**, so on the
  graph tabs and in the report pre- and post-treatment values are compared,
  and a treatment line marks the date.
- **Remeasurement** numbers don't change: they count visits to each plot,
  whether or not a treatment came between them.
- The report describes the treatments in its "Scans, plots and treatments"
  section. It first counts them ("Two prescribed fires took place during the
  reporting period."), then says what was done and when (for example,
  "Herbicide was applied on 05/15/2025."; the report writes dates as
  MM/DD/YYYY), how many plots were scanned before and after each treatment
  and how long before and after, and which plots and units give a direct
  before-and-after comparison. A table lists each treatment with its plot
  counts, and the time-step table names the treatment each step comes before
  or after.

<p class="help-warning"><strong>A treatment date applies to every loaded
scan, in every unit. If you load units treated at different times, check the
Scan grouping after adding the dates and correct it where needed.</strong></p>

## Correct remeasurement numbers

Remeasurement numbers are set for you when you click **Get Data**: each
plot's scans are numbered in date order, 0 for its first scan, 1 for its
next and so on, even when the next scan is the following day. Scans of a
plot taken on the same date share a number. To change them:

1. Sort or filter the table so the scans to change are easy to find, for
   example by clicking the **plot** heading.
2. Select the scans.
3. Leave **Unit Name** and **Scan Grouping** empty so they stay as they
   are.
4. Type the number in **Scan Remeasurement**: 0 for the plot's first scan,
   1 for its next, and so on.
5. Click **Assign**.

You can also double-click a single **Remeasurement** cell, type the number
and press **Enter**.

## Scan grouping

The graph tabs and the report don't compare scans one date at a time.
They gather the scans from one round of scanning into a **scan grouping**
(shown on the graphs as a time step) and compare the groupings. When you
click **Get Data**, scans are grouped by walking through the scan dates in
order. A new scan grouping starts when:

1. a **treatment date** falls between one scan date and the next;
2. a plot already scanned in the current grouping is **scanned again**,
   which marks a new round of scanning; or
3. more than **30 days** pass since the previous scan.

Plots scanned only once stay in the grouping that was open when they were
scanned. Groupings are numbered from 1 in date order; on the graphs each one
is labeled with the average date of its scans.

<div class="help-shot"><img src="static/help/images/set-treatments-scan-grouping.png" alt="The table sorted by Remeasurement, the six initial scans selected, and 1 typed as the scan grouping" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:62.3%;top:20%">1<span class="help-tip">The table is <b>sorted by Remeasurement</b>, so the initial scans of both units are listed together.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:37.5%;top:36%">2<span class="help-tip">The six <b>initial scans</b> are selected. By default they were split into scan groupings 1 and 2.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:95%;top:85.4%">3<span class="help-tip"><b>Unit Name</b> and <b>Scan Remeasurement</b> are left empty, so they don't change.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:95%;top:94.3%">4<span class="help-tip">The new <b>scan grouping</b>: 1.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:95%;top:97.9%">5<span class="help-tip">Click <b>Assign</b> to apply it.</span></span>
</div>

To change the grouping, for example to keep a round of scanning that ran
longer than 30 days together, or to separate units treated at different
times:

1. Sort or filter the table so the scans to change are easy to find, for
   example by clicking the **Remeasurement** heading (1).
2. Select the scans (2).
3. Leave **Unit Name** and **Scan Remeasurement** empty (3) so they stay as
   they are.
4. Type the number in **Scan Grouping** (4). Scans with the same number are
   averaged together.
5. Click **Assign** (5).

In the example, the four rounds of scanning (two per unit) are regrouped so
the graphs compare all initial scans (grouping 1) with all remeasurements
(grouping 2):

<div class="help-shot"><img src="static/help/images/set-treatments-final.png" alt="Both units named; remeasurements are 0 and 1 for each plot, and scan groupings are 1 for initial scans and 2 for remeasurements" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:50%;top:32.3%">1<span class="help-tip">Every scan has its <b>unit name</b>.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:56.9%;top:36%">2<span class="help-tip">Each plot's <b>remeasurement</b> numbers: 0 for its first scan, 1 for its next.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:68.5%;top:32.3%">3<span class="help-tip">The <b>initial scans</b> of both units are scan grouping 1.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:68.5%;top:54.8%">4<span class="help-tip">The <b>remeasurements</b> of both units are scan grouping 2.</span></span>
</div>

You can also double-click a single **Scan grouping** cell, type the number
and press **Enter**.

Your changes are used on every graph tab (Standard outputs, Custom models
and rothRmel) and in the report. The numbers only label the groupings: the
graphs order them by date, and a number you skip doesn't add an empty time
step.

## Delete a treatment date

<div class="help-shot"><img src="static/help/images/set-treatments-delete-date.png" alt="The 2025-05-15 prescribed fire selected in the Treatment dates list, with the trash can below it" width="176">
<span class="help-spot tip-left tip-up" tabindex="0" style="left:77%;top:93.6%">1<span class="help-tip">Then click the <b>trash can</b> below the list to delete it.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:6%;top:54%">2<span class="help-tip">First click the <b>date</b> to select it.</span></span>
</div>

1. Click the date in the **Treatment Dates** list to select it.
2. Click the **trash can** below the list.

To change a date or its treatment, delete it and add it again with the
correct date and treatment. Deleting a date
regroups every scan, which replaces scan groupings you entered by hand;
remeasurement numbers are kept.

## Remove scans

Scans stay in this table, with their downloaded data, until you remove them.
Unselecting a downloaded plot or using **Clear All Plots** on the Selection
Map doesn't remove it. To remove some of the scans:

<div class="help-shot"><img src="static/help/images/set-treatments-remove.png" alt="Both scans of plot WATBR 0111 selected in the table, with Remove selected scans above it" width="800">
<span class="help-spot tip-right" tabindex="0" style="left:37.5%;top:39.8%">1<span class="help-tip">The <b>scans to remove</b> are selected: both scans of plot WATBR 0111.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:57.6%;top:5.1%">2<span class="help-tip">Click <b>Remove selected scans</b>.</span></span>
</div>

1. Select the scans in the table. Sort or filter it first to find them.
2. Click **Remove selected scans** above the table.
3. A window says how many scans will be removed and asks you to confirm:

   <div class="help-shot"><img src="static/help/images/set-treatments-remove-confirm.png" alt="Remove selected scans? This removes 2 scans from this session, with their downloaded data." width="286"></div>

4. Click **Remove**, or **Cancel** to keep them.

The scans leave the table and the session: their metrics, tree inventory and
model outputs are removed, and the graph tabs and the report stop using
them. Figures already added to the report are kept. To use the scans again,
select them on the Selection Map and click **Get Data**. To remove every
downloaded scan at once, use **Clear All Downloads** on the Selection Map.

## Things to know

- **Treatment dates are shared by all loaded scans.** One list of dates
  applies to every site and unit; there is no separate list per unit. The
  report notes which units were scanned before and after each treatment.
- **One entry per date.** A date can be added once. For several treatments
  on the same date, pick them all in the **Treatment** box.
- **Download first, then number.** Clicking **Get Data** on the Selection
  Map renumbers and regroups every loaded scan, which replaces remeasurement
  numbers and scan groupings you set by hand. Unit names are kept. Finish
  downloading and adding treatment dates before correcting the numbers.
- **Download the scans to number them.** Plots you selected but didn't
  download yet are listed without remeasurement numbers or scan groupings;
  click **Get Data** on the Selection Map to fill them in. With no plots
  selected, the table says "No scans to display."
- **Units and numbers last for one session.** Reloading the page clears
  them along with the downloaded data.
- **Clear All Plots on the Selection Map** removes only plots that haven't
  been downloaded. Downloaded scans stay in this table until you remove them
  here or with **Clear All Downloads**.
