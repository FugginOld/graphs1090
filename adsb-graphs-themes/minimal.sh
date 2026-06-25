#!/bin/bash
# adsb-graphs Theme: Minimal
# Clean light background, muted modern data colors
# ------------------------------------------------

COLORS="
  --color BACK#f4f4f0
  --color CANVAS#ffffff
  --color SHADEA#e8e8e4
  --color SHADEB#d8d8d4
  --color GRID#e0e0e0
  --color MGRID#c8c8c8
  --color FONT#1a1a1a
  --color AXIS#888888
  --color FRAME#e0e0db
  --color ARROW#1a1a1a
"

# ------------------------------------------------
# Data series colors
# ------------------------------------------------

# Aircraft Seen / Tracked  (filled area)
SEEN_COLOR="#22c55e26"       # green fill, ~15% opacity
SEEN_LINE="#16a34a"          # dark green border

# w/ ADS-B position         (line)
ADSB_COLOR="#3b82f6"         # blue

# w/ MLAT position          (line)
MLAT_COLOR="#94a3b8"         # slate gray

# w/ TIS-B position         (line)
TISB_COLOR="#f59e0b"         # amber

# w/o position              (line)
NPOS_COLOR="#ef4444"         # red
