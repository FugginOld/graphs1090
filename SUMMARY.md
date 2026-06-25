# Recent Changes Summary

## Observable behavior changes

### None for end users

All three changes are internal refactors. A deployed instance will behave identically to before with one new side effect per issue.

---

## Issue 1 — Metric Extraction (`dump1090.py`)

**What changed:** The aircraft-counting and quartile logic that was duplicated across `read_1090()` and `read_978()` is now a single pure function, `compute_aircraft_stats()`.

**Observable:** No change to collectd metrics, RRD values, or graph output. Identical numbers are dispatched to collectd as before.

**New:** 14 unit tests in `test_dump1090.py` covering counting, signal filtering, range filtering, and quartile computation. Run with `python -m pytest test_dump1090.py`.

**Why it's an improvement:**

Before this change, the logic for deciding which aircraft count toward totals, which qualify for range statistics, and which qualify for signal statistics existed in two nearly identical inline loops — one inside `read_1090()` and one inside `read_978()`. The loops were ~100 lines each and differed only in a few threshold values (message count threshold, range cap, RSSI clamping). Because the logic was inline and entangled with collectd dispatch calls, there was no way to test it without standing up a collectd environment.

Extracting `compute_aircraft_stats()` creates a **deep module**: the function's interface is small (a list of aircraft dicts, receiver coordinates, and a mode flag) but it hides the full complexity of the filtering and quartile computation behind it. The collectd dispatch calls remain in `read_1090()` and `read_978()` where they belong — side effects stay at the edges.

The immediate practical gain is testability: the 14 tests exercise the real filtering rules through the public interface, with no mocking required. A future change to signal thresholds or range capping rules can be verified by running `pytest` rather than by deploying to a live receiver.

---

## Issue 2 — Graph Manifest (`adsb-graphs.sh` + `html/graphs.js`)

**What changed:** The `show_graph()` function, which mutated `/usr/share/adsb-graphs/html/index.html` via `sed` to unhide optional panels (UAT 978, Airspy, dump1090-misc), is removed. Instead, `adsb-graphs.sh` writes a `manifest.json` to the graphs output directory after each generation run. `graphs.js` fetches this file on page load and shows the relevant panels.

**Observable:**
- Optional panels (UAT 978, Airspy, dump1090-misc) now appear and disappear based on `manifest.json` rather than inline styles baked into `index.html` at generation time.
- `index.html` is no longer mutated on disk by the graph generation script.
- On the very first page load after upgrade (before graphs have been generated once), optional panels will be hidden — same as the prior default state.
- If `manifest.json` is absent or unreadable, optional panels stay hidden silently. No console errors in supported browsers.

**Why it's an improvement:**

The prior design had no single place that represented "which graphs are currently active." That knowledge was split across three files: `adsb-graphs.sh` knew when to call `show_graph`, `index.html` stored the current visibility state as inline styles, and `graphs.js` checked those inline styles at runtime to decide which image `src` attributes to update. Adding a new optional graph type required coordinated edits to all three files with no mechanism to detect a mismatch.

The `show_graph` mechanism was also a side-channel: a graph generation script was responsible for mutating a UI file on disk. These are unrelated concerns. If `index.html` was ever reset (e.g. after a package upgrade), the panels would silently revert to hidden until the next graph generation cycle.

`manifest.json` creates a real **seam** between "what graphs were generated" and "what the UI should display." `adsb-graphs.sh` writes its output declaration; `graphs.js` reads it. Each side has one job, and the file is the interface. Adding a new optional graph now requires only one change in `adsb-graphs.sh` (call `register_active_graph`) and one entry in `MANIFEST_PANELS` in `graphs.js` — `index.html` is not touched.

---

## Issue 3 — Config Resolution (`resolve-config.sh`)

**What changed:** The DB path resolution block (default path, source `/etc/default/adsb-graphs`, tmpfs autodetect) was copy-pasted identically in both `adsb-graphs.sh` and `service-adsb-graphs.sh`. It is now in a single shared file, `resolve-config.sh`, which both scripts source.

**Observable:** No behavior change. `DB` resolves to the same path as before under all conditions. The explanation comment for why the autodetect does not write back to `/etc/default/adsb-graphs` now lives in one place.

**Why it's an improvement:**

The duplicated block encoded a non-obvious policy: the tmpfs path (`/run/collectd`) takes precedence over the configured path, but this override is intentionally never written back to the config file because users may have customised it. That reasoning was explained in a comment — which was also duplicated. When policy comments drift from the code they describe, the comment becomes misleading rather than helpful.

With `resolve-config.sh` as the single owner of this logic, the policy and its explanation are collocated. Any future change to DB path resolution — supporting a third storage location, changing the autodetect condition, or adjusting the override priority — is a one-file edit with no risk of the two consumers falling out of sync.

---

## Issue 4 — Themes + dashboard (`adsb-graphs.sh`, `html/*`)

**What changed:** The single light/dark `colorscheme` switch is replaced by six
named themes, each rendered into its own image folder; the web UI becomes a
dashboard (top bar, graph cards, live "Now" sidebar) with an in-page theme
switcher.

- `adsb-graphs.sh`: the old `colors=""`/`if dark` block is now `set_palette <theme>`
  carrying full palettes for `orig-light`, `orig-dark`, `aviation`, `minimal`,
  `night`, `retro`. The option strings that embed `$colors`/`$CANVAS` moved into
  `compute_layout()` so they can be rebuilt per theme. Generation runs in a loop
  over `$graph_themes`, writing each theme to `${DOCUMENTROOT}/<theme>/`.
- New outputs at the graphs root: `themes.json` (which themes exist) and
  `stats.json` (current sidebar values, via `rrdtool lastupdate` plus one CPU
  `PRINT`). `manifest.json` is now written once at the base and deduped.
- `html/index.html` is a dashboard; `portal.css` carries six `[data-theme]`
  chrome palettes; `graphs.js` swaps the `graphs/<theme>/` folder for every image,
  persists the choice (localStorage + `?theme=`), and fills the sidebar from
  `stats.json`. All original image/panel IDs are preserved.

**Observable:**
- The page has a theme switcher and a stats sidebar. Switching theme recolors the
  chrome instantly and loads that theme's PNGs.
- Disk/CPU cost scales with the number of enabled themes (default six ≈ 6× the
  prior RRDtool work). Trim with `graph_themes="..."` in `/etc/default/adsb-graphs`.
- If `themes.json`/`stats.json` are missing (e.g. first load before a render),
  the switcher falls back to the full list and the sidebar shows placeholders —
  no console errors.

**Why it's an improvement:**

RRDtool bakes colors into the PNG at render time, so a browser can't recolor an
existing graph. The folder-per-theme design makes that constraint explicit: the
generator declares each theme's pixels under `graphs/<theme>/`, and the page's
only job is to choose a folder. Theme color, page chrome, and image selection are
three separate seams — palettes live in `set_palette`, chrome in CSS
`[data-theme]` blocks, selection in `graphs.js` — instead of one global flag baked
through the whole pipeline. Adding or tuning a theme is a localized edit on each
side, and the workload is opt-out per deployment via `graph_themes`.
