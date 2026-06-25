#!/bin/bash
# graphs1090 Theme: Retro
# Modernized version of the original dark green style —
# same green fill + cyan ADS-B line, cleaner execution
# ------------------------------------------------

COLORS="
  --color BACK#131313
  --color CANVAS#131313
  --color SHADEA#131313
  --color SHADEB#131313
  --color GRID#222222
  --color MGRID#333333
  --color FONT#c9c9c9
  --color AXIS#5a5a5a
  --color FRAME#1e1e1e
  --color ARROW#c9c9c9
"

# ------------------------------------------------
# Data series colors
# ------------------------------------------------

# Aircraft Seen / Tracked  (filled area)
SEEN_COLOR="#5db32985"       # green fill, ~52% opacity
SEEN_LINE="#5db329"          # green border

# w/ ADS-B position         (line)
ADSB_COLOR="#00e0ff"         # bright cyan

# w/ MLAT position          (line)
MLAT_COLOR="#dcdcdca6"       # light gray, ~65% opacity

# w/ TIS-B position         (line)
TISB_COLOR="#e8820a"         # orange

# w/o position              (line)
NPOS_COLOR="#cc2e2e"         # red
