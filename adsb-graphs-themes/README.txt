adsb-graphs Color Themes
=======================
Four modernized color schemes for adsb-graphs / RRDtool.

HOW TO APPLY
------------
1. Open your adsb-graphs shell script:
   sudo nano /usr/share/adsb-graphs/adsb-graphs.sh

2. Find the section near the top where color variables are set
   (look for lines with --color BACK or colorscheme).

3. Add one of the four theme blocks below to a new
   colorscheme option, OR paste the --color flags and
   series colors directly into the rrdtool graph calls.

4. Each theme file contains:
   - RRDtool --color flags  (canvas, background, grid, font, axes)
   - Series hex colors       (area fill and line colors per data series)

5. Restart the service after editing:
   sudo systemctl restart adsb-graphs

THEMES INCLUDED
---------------
  aviation.sh  — Dark phosphor-green terminal / radar aesthetic
  minimal.sh   — Clean light background, muted data colors
  night.sh     — Dark navy dashboard with indigo accents
  retro.sh     — Modernized version of the original dark green style

NOTE: RRDtool renders PNG images, so smooth curves and fonts from
the interactive preview will differ slightly — but the color
palettes translate directly.
