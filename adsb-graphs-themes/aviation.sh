#!/bin/bash
# graphs1090 Theme: Aviation
# Dark phosphor-green terminal / radar aesthetic
# ------------------------------------------------
# Paste these --color flags into your rrdtool graph calls in graphs1090.sh
# (add them to the COLORS variable or directly into each graph function)

COLORS="
  --color BACK#06100a
  --color CANVAS#06100a
  --color SHADEA#06100a
  --color SHADEB#06100a
  --color GRID#0d2614
  --color MGRID#1a4028
  --color FONT#4ade80
  --color AXIS#2d6e3e
  --color FRAME#0a1c0f
  --color ARROW#4ade80
"

# ------------------------------------------------
# Data series colors — update the AREA/LINE calls
# in each graph function that draws aircraft data
# ------------------------------------------------

# Aircraft Seen / Tracked  (filled area)
SEEN_COLOR="#4ade8066"       # green fill, ~40% opacity
SEEN_LINE="#4ade80"          # green border

# w/ ADS-B position         (line)
ADSB_COLOR="#22d3ee"         # cyan

# w/ MLAT position          (line)
MLAT_COLOR="#ffffff80"       # white, ~50% opacity

# w/ TIS-B position         (line)
TISB_COLOR="#facc15"         # amber

# w/o position              (line)
NPOS_COLOR="#f87171"         # red

# ------------------------------------------------
# Example rrdtool graph snippet (aircraft graph):
# ------------------------------------------------
# rrdtool graph "$OUTPUT" \
#   $COLORS \
#   --title "ADS-B Aircraft Seen / Tracked" \
#   --vertical-label "Aircraft" \
#   --font DEFAULT:0:"Space Mono" \
#   DEF:seen=dump1090.rrd:aircraft_with_pos:AVERAGE \
#   DEF:adsb=dump1090.rrd:aircraft_with_pos:AVERAGE \
#   AREA:seen${SEEN_COLOR}:"Aircraft Seen / Tracked" \
#   LINE1:adsb${ADSB_COLOR}:"w/ ADS-B pos." \
#   ...
