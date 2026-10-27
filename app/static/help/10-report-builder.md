# Report builder

<p class="help-warning"><strong>The report's automated descriptions are
written by the app from the data, not by an analyst. Read each one before you
share the report, and add your own interpretation in the text blocks and
comments. Model outputs (custom models, fuels, fire behavior and simulated
stem maps) are predictions with uncertainty the figures don't show; the report
prints a caveat when it holds them.</strong></p>

## What this tab is for

The Report builder turns the figures and tables you collect across the tabs
into a formatted report, as a Word (.docx) file you can edit or a PDF. It is
the last step of the workflow and is used to communicate monitoring results
and their management relevance.

The report is built from:

- **Figures and tables** added with the **+ Report data** button on the
  graph cards and fuel and forestry cards of the other tabs. Each one comes
  with its settings, an automated description and the methods and references
  behind it.
- **Text blocks** you write here: an introduction, a data description, the
  results, management relevance or any other heading.
- **Standard sections** built from the loaded scans: the scans, plots and
  treatments; a map of the plot locations; and the sample size and design
  issues.
- **Report details** from the left panel: the title, subtitle, author,
  organization, date and summary.

Everything is arranged in one ordered list, so text, sections and data can go
in any order.

## The screen at a glance

Move the mouse over a numbered marker, or press Tab to step through them, to
see what each part does.

<div class="help-shot"><img src="static/help/images/report-overview.png" alt="The Report builder tab: report details on the left and the report contents list on the right" width="625">
<span class="help-spot tip-right" tabindex="0" style="left:29.6%;top:27.8%">1<span class="help-tip"><b>Title.</b> The report title, on the title page and in the file name. "IntELiMon monitoring report" when left empty.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:29.6%;top:38.9%">2<span class="help-tip"><b>Subtitle.</b> For example the unit, project or treatment.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:29.6%;top:49.8%">3<span class="help-tip"><b>Prepared by.</b> Printed on the title page as "Prepared by …".</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:29.6%;top:60.7%">4<span class="help-tip"><b>Organization.</b> Printed on the title page.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:29.6%;top:71.8%">5<span class="help-tip"><b>Date of preparation.</b> Printed on the title page, in the footer and in the file name. Today by default.</span></span>
<span class="help-spot tip-right tip-up" tabindex="0" style="left:29.6%;top:83.3%">6<span class="help-tip"><b>Summary.</b> An executive summary that opens the report. Blank lines start new paragraphs. Scroll the panel for Format and Build report.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:74.9%;top:14.7%">7<span class="help-tip"><b>+ Text block.</b> Adds an empty text block directly under the selected card, or at the bottom when no card is selected.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:90.6%;top:19.4%">8<span class="help-tip"><b>Start over.</b> Removes everything from the report and restores the default text blocks and sections.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:58.4%;top:33.1%">9<span class="help-tip"><b>Entry.</b> Its number in the report, its type (text, section, figure or table) and its title. Click it to select it.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96%;top:33.1%">10<span class="help-tip"><b>↑ ↓ ✕.</b> Move the entry up or down, or remove it.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:96%;top:38.9%">11<span class="help-tip"><b>Heading.</b> Pick a heading from the list or type your own.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:48%;top:47.4%">12<span class="help-tip"><b>Text.</b> "Optional" blocks are left out of the report while empty.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:80%;top:82.7%">13<span class="help-tip"><b>Standard section.</b> Built from the loaded scans when the report is built; the line below previews it.</span></span>
</div>

1. **Title**: on the title page and in the file name.
2. **Subtitle**: for example the unit, project or treatment.
3. **Prepared by**.
4. **Organization**.
5. **Date of preparation**: today by default. Dates throughout the report
   are written MM/DD/YYYY, and counts below ten are spelled out.
6. **Summary**: opens the report. Format and **Build report** are below it.
7. **+ Text block**: adds an empty text block directly under the selected
   card, or at the bottom of the report when no card is selected.
8. **Start over**: clears the report.
9. **Entry**: number, type and title; click to select.
10. **↑ ↓ ✕**: move up, move down, remove.
11. **Heading** of a text block.
12. **Text** of a text block.
13. **Standard section**, with a preview.

## Step by step

1. Load scans on the **Selection Map** and enter treatment dates and unit
   names on **Set Treatments**.
2. On the other tabs, click **+ Report data** on each graph, table or card you
   want in the report. A message confirms each addition.
3. Open the **Report builder**. Fill in the report details in the left panel.
4. Write the text blocks, read each automated description and add comments.
5. Arrange the entries with the arrows and add text blocks or sections where
   needed.
6. Choose **Word (.docx)** or **PDF** and click **Build report**, then
   **Download report**.

## A new report

Every session starts with these entries:

| # | Entry | Type |
|---|---|---|
| 1 | Introduction | Optional text block |
| 2 | Data description | Optional text block |
| 3 | Scans, plots and treatments | Standard section |
| 4 | Plot locations | Standard section |
| 5 | Sample size and design | Standard section |
| 6 | Results | Optional text block |
| 7 | Management relevance | Optional text block |

Figures and tables added from the cards go after the last figure or table
already in the report, or after **Results** when there are none yet, so the
data stay ahead of **Management relevance**.

## Adding figures and tables

Each tab adds a different kind of item:

| Tab | What + Report data adds |
|---|---|
| Standard outputs, Custom models, rothRmel | The graph as shown, or its statistics table in Statistics view, with the plot type, data type and other settings |
| Points2Pano viewer (on the graph tabs and Forestry exports; the button is in the lower right of the panorama) | An image of the default view of the plot showing |
| Fuels exports | The Surface fuels, Canopy fuels, Time lag fuels or Mean fuel loading card as a table |
| Forestry exports | The stem map, and the Metrics, Species, Stocking, Size bias or FVS tab |

<div class="help-shot"><img src="static/help/images/report-figure-entry.png" alt="A figure entry with its settings, its automated description open, a comment box and a Points2Pano photo entry below" width="376">
<span class="help-spot tip-left" tabindex="0" style="left:57.2%;top:7.6%">1<span class="help-tip"><b>Preview</b> of the figure or table.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:93%;top:17.2%">2<span class="help-tip"><b>Settings</b> behind it: the source tab, plot type, data type and so on. Printed under the caption.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:39.9%;top:22.5%">3<span class="help-tip"><b>Automated description.</b> Click to open or close it.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:53.2%;top:26.3%">4<span class="help-tip"><b>Include in the report.</b> Untick to leave the description out.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:97%;top:37.9%">5<span class="help-tip"><b>Summary</b> of the change over time and across the treatment.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:97%;top:51.8%">6<span class="help-tip"><b>What the change means</b> for this metric, in italics.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:47.9%;top:55%">7<span class="help-tip"><b>Comment.</b> Your own note, printed below the figure.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:77%;top:75.8%">8<span class="help-tip">A <b>Points2Pano photo</b> entry.</span></span>
</div>

1. **Preview** of the figure or table.
2. **Settings** behind it, printed under the caption.
3. **Automated description**: click to open.
4. **Include in the report**: untick to leave the description out.
5. **Summary** of the change.
6. **What the change means**.
7. **Comment**: your own note, printed below the figure.
8. A **Points2Pano photo** entry.

### Automated descriptions

Graph and statistics items come with a description written from the same
data the card draws: how many scans, plots and time steps it covers, the
mean in the first and last time steps, the largest change between steps and,
across each treatment date, the average change at the plots scanned before
and after it. An italic line says what a change in that metric usually
means. Untick **Include in the report** to leave the description out.

Issues with the data behind an item, such as single scans, few plots or a
treatment without scans on both sides, are listed under **Sample size and
design**, and a red note under the item points to them.

A graph and its statistics table with the same data share one description:
the second says "These data are described under Figure 1".

## Text blocks

<div class="help-shot"><img src="static/help/images/report-selected-entry.png" alt="A new text block added right after the selected Stand metrics entry, highlighted with a teal border" width="376">
<span class="help-spot tip-left" tabindex="0" style="left:95.7%;top:40.4%">1<span class="help-tip">The <b>selected entry</b> is highlighted. New text blocks and sections go right after it.</span></span>
<span class="help-spot tip-right" tabindex="0" style="left:53.2%;top:46.2%">2<span class="help-tip">Pick or type a <b>heading</b>.</span></span>
</div>

1. Click an entry to select it; it is highlighted with a teal border.
2. Click **+ Text block**. An empty text block is added directly under the
   selected card and becomes the selected one, so several added in a row
   keep their order. If no card is selected, it is added at the bottom of
   the report.
3. Pick a heading from the list, or type your own and press **Enter**:
   <div class="help-shot"><img src="static/help/images/report-headings.png" alt="The heading list: Introduction, Management objectives, Methods, Data description, Results, Discussion, Conclusions, Management relevance and Suggested management actions" width="464"></div>
4. Write the text. Blank lines start new paragraphs.

The default blocks are marked **Optional**: left empty, they are left out of
the report. The exception is an empty **Results** block with figures right
after it, whose heading still introduces them. Text blocks you add are always
printed, even with only a heading.

## Standard sections

| Section | What it holds |
|---|---|
| Scans, plots and treatments | A paragraph on the scans, plots, sites, dates, agencies and management units. Then the treatments entered on the Set Treatments tab: how many of each type took place, what was done and when, how many plots were scanned before and after each treatment and how long before and after, and which plots and units were scanned on both sides of it. Tables list the plots, the treatments (date, type and plot counts) and the time steps, each step named for the treatment it comes before or after |
| Plot locations | A map of the selected plots on satellite imagery (Esri World Imagery), zoomed to their extent |
| Sample size and design | Issues across all loaded scans (few plots, single scans, small or unbalanced time steps, unbalanced units), then the issues of each figure and table |

The line under each section previews it from the scans loaded now. Remove a
section with **✕**; a **+** button for it then appears beside **+ Text block**
so you can add it back.

## Arranging the report

- **↑** and **↓** move an entry one place. Entries can go in any order.
- **✕** removes an entry. Removing a figure or table from the report doesn't
  change its card.
- Consecutive items from one card share a heading, with a subheading each,
  for example "Time series plot" and "Statistics" under one metric.
- **Start over** asks for confirmation, then removes every figure, table and
  text block and restores the default entries. The cards are not affected.

## Building and downloading

<div class="help-shot"><img src="static/help/images/report-build.png" alt="The bottom of the report details panel: format choice, Build report and Download report buttons" width="200">
<span class="help-spot tip-left" tabindex="0" style="left:87.5%;top:73.2%">1<span class="help-tip"><b>Format</b>: Word (.docx) to edit, or PDF.</span></span>
<span class="help-spot tip-left" tabindex="0" style="left:92.5%;top:82.3%">2<span class="help-tip"><b>Build report.</b> Builds it in the background.</span></span>
<span class="help-spot tip-left tip-up" tabindex="0" style="left:92.5%;top:92.9%">3<span class="help-tip"><b>Download report</b> appears when the build is done.</span></span>
</div>

1. Choose the **Format**: **Word (.docx)** to keep editing, or **PDF**.
2. Click **Build report**. The report is built in the background, so you can
   keep using the app; "Building the report…" shows while it runs. Larger
   reports and the cover photo and map take longer.
3. Click **Download report**. The file is named after the title and date,
   for example `WACNR_treatment_monitoring_20261016.docx`.

To change the report, edit it here and build again. The download always
holds the last build.

## What's in the report

| Part | Contents |
|---|---|
| Title page | Title, subtitle, cover photo (the Points2Pano image of the first selected scan), prepared by, organization and date |
| Second page | Cover photo caption, lines for handwritten notes, About these data (with the methods used), the disclaimer and a statement of origin |
| Contents | The report's headings. The PDF fills in page numbers; in Word, type each page number over its highlighted **#** |
| Summary | Your summary |
| Body | Your entries in order. Figures and tables are numbered separately, each with its caption, settings, automated description and comment |
| Caveats | A red warning when the report holds rothRmel or custom model output |
| About these data | How IntELiMon data are collected and processed, and a sentence for each method used by the figures and tables |
| References | Every work cited by the methods used, alphabetically |

Every page has a footer with "IntELiMon Decision Support Tool", the
generation date and the page number.

## Things to know

- **The report lasts for one session.** Reloading the page clears it along
  with the downloaded data. Build and download the report before you leave.
- **Items are snapshots.** An item keeps the settings and data it had when
  you added it. To update one, remove it and add it again from its card.
- **Standard sections are built at build time** from the scans, units and
  treatment dates loaded then.
- **Read the automated text.** It describes the data mechanically; it doesn't
  know about field conditions, data errors or outlier stems. Add context in
  comments and text blocks.
- **Word contents need page numbers.** Word can't be told the page numbers
  when the file is made, so type them over the highlighted **#** marks after
  your final edits, or replace the list with Word's own table of contents
  (References → Table of Contents).
- **The cover photo and map need an internet connection** to the Points2Pano
  and Esri imagery servers. Without it, the report shows a placeholder.
