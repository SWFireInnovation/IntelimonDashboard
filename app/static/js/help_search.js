// app/static/js/help_search.js
// Search box for the Help tab (app/view/tab_help.R). Typing filters the topic
// list to pages containing every word typed and highlights those words in the
// pages; Enter jumps to the first highlighted word. Runs entirely in the
// browser. Plain JS loaded from app/static, since the Rhino JS build needs
// Node.
(function () {
  "use strict";

  // Wrap each occurrence of any of `words` in the text under `root` in <mark>.
  function highlight(root, words) {
    var pattern = new RegExp(
      "(" + words.map(function (w) {
        return w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      }).join("|") + ")",
      "gi"
    );
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    var nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.forEach(function (node) {
      pattern.lastIndex = 0;
      if (!pattern.test(node.nodeValue)) return;
      var frag = document.createDocumentFragment();
      node.nodeValue.split(pattern).forEach(function (part, i) {
        // split() with one capture group puts the matches at odd indexes
        if (i % 2 === 1) {
          var mark = document.createElement("mark");
          mark.className = "help-hit";
          mark.textContent = part;
          frag.appendChild(mark);
        } else if (part) {
          frag.appendChild(document.createTextNode(part));
        }
      });
      node.parentNode.replaceChild(frag, node);
    });
  }

  function clearHighlights(root) {
    root.querySelectorAll("mark.help-hit").forEach(function (mark) {
      var parent = mark.parentNode;
      parent.replaceChild(document.createTextNode(mark.textContent), mark);
      parent.normalize();
    });
  }

  function showTopic(link) {
    if (window.bootstrap && bootstrap.Tab) {
      bootstrap.Tab.getOrCreateInstance(link).show();
    } else if (window.jQuery) {
      window.jQuery(link).tab("show");
    }
  }

  function search(input) {
    var layout = input.closest(".help-layout");
    var words = input.value.toLowerCase().split(/\s+/).filter(Boolean);
    var links = layout.querySelectorAll("ul.nav a[data-bs-toggle='tab']");
    var firstMatch = null;
    var activeHidden = false;

    links.forEach(function (link) {
      var pane = layout.querySelector(link.getAttribute("href"));
      clearHighlights(pane);
      var text = (link.textContent + " " + pane.textContent).toLowerCase();
      var match = words.every(function (w) { return text.indexOf(w) !== -1; });
      link.parentElement.hidden = !match;
      if (match && words.length) highlight(pane, words);
      if (match && !firstMatch) firstMatch = link;
      if (!match && link.classList.contains("active")) activeHidden = true;
    });

    layout.querySelector(".help-search-empty").hidden = firstMatch !== null;
    if (activeHidden && firstMatch) showTopic(firstMatch);
  }

  document.addEventListener("input", function (e) {
    if (e.target.matches(".help-search-input")) search(e.target);
  });

  document.addEventListener("keydown", function (e) {
    if (e.key !== "Enter" || !e.target.matches(".help-search-input")) return;
    e.preventDefault();
    var layout = e.target.closest(".help-layout");
    var active = layout.querySelector(".tab-content > .tab-pane.active");
    var hit = active && active.querySelector("mark.help-hit");
    if (hit) hit.scrollIntoView({ behavior: "smooth", block: "center" });
  });
})();
