#!/bin/bash
# adsb-graphs Theme: Night
# Dark navy dashboard with indigo/purple accents
# ------------------------------------------------

COLORS="
  --color BACK#0d1117
  --color CANVAS#161b22
  --color SHADEA#0d1117
  --color SHADEB#0d1117
  --color GRID#1e2936
  --color MGRID#253447
  --color FONT#e2e8f0
  --color AXIS#475569
  --color FRAME#1e2936
  --color ARROW#e2e8f0
"

# ------------------------------------------------
# Data series colors
# ------------------------------------------------

# Aircraft Seen / Tracked  (filled area)
SEEN_COLOR="#818cf866"       # indigo fill, ~40% opacity
SEEN_LINE="#818cf8"          # indigo border

# w/ ADS-B position         (line)
ADSB_COLOR="#38bdf8"         # sky blue

# w/ MLAT position          (line)
MLAT_COLOR="#47556980"       # slate, ~50% opacity

# w/ TIS-B position         (line)
TISB_COLOR="#fb923c"         # orange

# w/o position              (line)
NPOS_COLOR="#f87171"         # red/pink
