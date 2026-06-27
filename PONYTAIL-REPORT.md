# Ponytail Audit Report

Scope: over-engineering and complexity only. Ranked biggest cut first.
Generated against current tree (Phase D complete, collectd stack removed).

---

## Findings

**`delete:` `install.sh`**
~150 lines still targeting the collectd/rrdtool stack. Installs `collectd-core`, `rrdtool`,
`wget`, `unzip`, `bash-builtins`; includes a special-case Ubuntu Jammy collectd .deb
workaround, collectd service checks, and `malarky.sh` invocation. None of this applies
to the live Telegraf + InfluxDB + Grafana stack. Needs a full rewrite or delete.
→ [`install.sh`](install.sh)

---

**`delete:` `uninstall.sh`**
~40 lines referencing `collectd`, `gunzip.sh`, `lighty-disable-mod adsb-graphs`, and
collectd service management. Running this against a Telegraf install would leave it broken.
→ [`uninstall.sh`](uninstall.sh)

---

**`shrink:` `adsb_collector.conf.example` — strip ~50 dead option lines**
Active config keys for the Telegraf collector: `instance`, `url_1090`, `url_978`,
`url_airspy`, `url_1090_signal`, `interval`. Everything below `interval` is RRDtool /
graphs1090 era: `graph_size`, `font_size`, `color_scheme`, scatter settings, axis scaling
ratios, `TEMP_MULTIPLIER`, `hide_system` (with a reference to `collectd.conf`), rrdtool
timezone, custom PNG dimensions, `swidth`/`sheight`/`lwidth`/`lheight`. None consumed by
any current code.
→ [`collector/adsb_collector.conf.example`](collector/adsb_collector.conf.example)

---

**`delete:` `config/default`**
Empty file. No content, no callers.
→ [`config/default`](config/default)

---

**`delete:` `collector/__pycache__/adsb_telegraf.cpython-313.pyc`**
Compiled binary committed to the repo. `.gitignore` already lists `__pycache__/` and
`*.pyc`, but this file is tracked. `git rm --cached collector/__pycache__/adsb_telegraf.cpython-313.pyc`.
→ [`collector/__pycache__/`](collector/__pycache__/)

---

**`shrink:` urllib2 compat shim in `adsb_telegraf.py`**

```python
try:
    from urllib.request import urlopen
except ImportError:
    from urllib2 import urlopen
```

Python 2 EOL was 2020; shebang is `#!/usr/bin/env python3`. Replace with direct import.
→ [`collector/adsb_telegraf.py:22-24`](collector/adsb_telegraf.py#L22-L24)

---

**`shrink:` stale migration notes in `adsb_telegraf.py` docstring**
Lines `"Phase B: adsb_aircraft, ..."` and `"Remaining: 978, airspy, system metrics."`
are mid-migration breadcrumbs. Phase B is complete; 978/airspy are wired. Delete both lines.
Also: `"the legacy collectd plugin used"` in the first sentence — historical noise.
→ [`collector/adsb_telegraf.py:4-14`](collector/adsb_telegraf.py#L4-L14)

---

**`shrink:` stale migration note in `adsb_stats.py` docstring**
`"During the migration both copies coexist; Phase D consolidates them into this one."`
Phase D is done; the statement is now false. Delete the sentence.
→ [`collector/adsb_stats.py:3-5`](collector/adsb_stats.py#L3-L5)

---

## Summary

**net: ~-250 lines, -0 deps possible.**

All cuts are residue from the collectd→Telegraf migration. The live stack
(`adsb_telegraf.py`, `adsb_stats.py`, `telegraf/`, `influxdb/`, `grafana/`) is lean.
Previous report findings are resolved — those files were deleted in Phase D.
