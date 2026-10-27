# Writing Help pages

Each file named `NN-topic.md` in this folder becomes one topic in the app's
Help tab. Files without the two-digit prefix (like this README) are ignored.

- **Order:** the `NN` prefix sets the order in the topic list. Pick a number
  between its neighbours, or renumber the files, to place a new page.
- **Label:** the first `# ` heading is the topic's label. Use `##` and below
  for sections inside the page.
- **Markdown:** GitHub-flavoured Markdown, including tables, strikethrough
  and autolinks.
- **Images:** put them in `images/` and link them as
  `![alt text](static/help/images/name.png)`. The app serves this folder
  under `static/`, so relative paths like `images/name.png` will not work.
- **Annotated screenshots:** to put numbered markers on a picture that show
  a note on mouse-over (or keyboard focus), wrap it in a `help-shot` div and
  place each `help-spot` with `left`/`top` in percent of the picture. Keep
  the whole block free of blank lines, or Markdown ends the HTML early.
  Add `tip-left`, `tip-right` or `tip-up` to a marker near an edge so its
  note opens toward the middle. Follow the picture with a numbered list of
  the same notes, for printing and searching.

  ```html
  <div class="help-shot"><img src="static/help/images/name.png" alt="..." width="800">
  <span class="help-spot" tabindex="0" style="left:20%;top:15%">1<span class="help-tip">Note.</span></span>
  </div>
  ```
- **Warnings:** for bold red text, use
  `<p class="help-warning"><strong>Text</strong></p>`.
- Pages are read when the app starts; restart the app to see edits.
