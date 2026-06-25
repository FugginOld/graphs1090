#!/bin/bash
# adsb-graphs Phase D decommission — remove the old collectd/RRD pipeline.
#
# THIS IS IRREVERSIBLE. Run only after:
#   - Phase C cutover is complete (Grafana is serving live data)
#   - You have verified Grafana panels match the old PNGs
#   - You no longer need the PNG fallback at /adsb-graphs/
#
# What is removed:
#   - collectd service (stopped + disabled)
#   - /usr/share/adsb-graphs/{html,adsb-graphs.sh,...} render pipeline files
#   - Legacy lib/ and scripts/ directories from the repo install
#   - collectd package (optional, prompted)
#   - Old lighttpd/nginx /adsb-graphs/ web conf (optional, prompted)
#
# What is kept:
#   - /var/lib/collectd/rrd/  (your historical RRD data; delete manually if wanted)
#   - Telegraf + InfluxDB + Grafana (the new stack, untouched)
#   - /usr/share/adsb-graphs/adsb_telegraf.py and adsb_stats.py (new collector)
#   - /usr/share/adsb-graphs/adsb_collector.conf (your runtime config)
#
# Usage:  sudo bash collector/decommission.sh

set -e
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND"' ERR

ipath=/usr/share/adsb-graphs

# ── confirmation gate ─────────────────────────────────────────────────────────

echo "=========================================================="
echo "  adsb-graphs Phase D — decommission old collectd/RRD stack"
echo "=========================================================="
echo
echo "This will PERMANENTLY remove:"
echo "  - collectd service"
echo "  - PNG render scripts and web assets from $ipath"
echo "  - Legacy lib/ and scripts/ from the installed files"
echo
echo "Your Grafana dashboards and InfluxDB data are NOT affected."
echo "Your historical RRD files in /var/lib/collectd/rrd/ are NOT removed."
echo
read -r -p "Type 'yes' to proceed: " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# ── stop and disable collectd ─────────────────────────────────────────────────

echo "== 1. Stop collectd =="
if systemctl is-active --quiet collectd 2>/dev/null; then
    systemctl stop collectd
    echo "  -> stopped"
fi
if systemctl is-enabled --quiet collectd 2>/dev/null; then
    systemctl disable collectd
    echo "  -> disabled"
fi

# ── remove render pipeline from install path ──────────────────────────────────

echo "== 2. Remove legacy files from $ipath =="

# Remove PNG render script and associated assets; keep the new collector files.
legacy_items=(
    "$ipath/adsb-graphs.sh"
    "$ipath/service-adsb-graphs.sh"
    "$ipath/html"
    "$ipath/default"
    "$ipath/default-config"
    "$ipath/dump1090.db"
    "$ipath/dump1090.py"
    "$ipath/prune-value.py"
    "$ipath/system_stats.py"
    "$ipath/installed"
    # theme folders
    "$ipath/colors"
    "$ipath/images"
)

for item in "${legacy_items[@]}"; do
    if [ -e "$item" ]; then
        rm -rf "$item"
        echo "  -> removed $item"
    fi
done

# Remove collectd conf drop-in if present.
for f in /etc/collectd/conf.d/adsb-graphs.conf /etc/collectd/adsb-graphs.conf; do
    if [ -f "$f" ]; then
        rm "$f"
        echo "  -> removed $f"
    fi
done

# ── remove PNG output directory ───────────────────────────────────────────────

echo "== 3. Remove PNG output directory =="
for d in /run/adsb-graphs /var/run/adsb-graphs; do
    if [ -d "$d" ]; then
        rm -rf "$d"
        echo "  -> removed $d"
    fi
done

# Remove the tmpfs mount from /etc/fstab if present.
if grep -q 'adsb-graphs' /etc/fstab 2>/dev/null; then
    sed -i '/adsb-graphs/d' /etc/fstab
    echo "  -> removed adsb-graphs tmpfs from /etc/fstab"
fi

# ── optional: remove /adsb-graphs/ web conf ────────────────────────────────────

echo
read -r -p "Remove the old /adsb-graphs/ web conf (lighttpd/nginx)? [y/N] " rm_webconf
if [[ "$rm_webconf" =~ ^[Yy]$ ]]; then
    for f in /etc/lighttpd/conf-available/88-adsb-graphs.conf \
              /etc/lighttpd/conf-enabled/88-adsb-graphs.conf \
              /etc/lighttpd/conf-available/95-adsb-graphs-otherport.conf \
              /etc/lighttpd/conf-enabled/95-adsb-graphs-otherport.conf; do
        [ -f "$f" ] && rm "$f" && echo "  -> removed $f"
    done
    # nginx
    for f in /etc/nginx/conf.d/adsb-graphs.conf \
              /etc/nginx/sites-enabled/adsb-graphs \
              /etc/nginx/sites-available/adsb-graphs; do
        if [ -f "$f" ]; then
            # Remove legacy /adsb-graphs blocks but keep any /grafana/ block.
            if grep -q '/grafana/' "$f"; then
                # File has both; strip only the legacy locations.
                sed -i '/location \/adsb-graphs/,/^}/d' "$f"
                sed -i '/location \/perf/,/^}/d' "$f"
                echo "  -> stripped legacy blocks from $f (kept /grafana/)"
            else
                rm "$f"
                echo "  -> removed $f"
            fi
        fi
    done
    # Reload whichever web server is running.
    systemctl is-active --quiet lighttpd && systemctl reload lighttpd && echo "  -> lighttpd reloaded"
    systemctl is-active --quiet nginx    && nginx -t && systemctl reload nginx && echo "  -> nginx reloaded"
fi

# ── optional: remove collectd package ────────────────────────────────────────

echo
read -r -p "Remove the collectd package (apt-get purge collectd collectd-core)? [y/N] " rm_pkg
if [[ "$rm_pkg" =~ ^[Yy]$ ]]; then
    apt-get purge -y collectd collectd-core || true
    apt-get autoremove -y || true
    echo "  -> collectd purged"
fi

# ── done ──────────────────────────────────────────────────────────────────────

echo
echo "== Phase D complete =="
echo "Grafana: http://$(hostname -I 2>/dev/null | awk '{print $1}')/grafana/"
echo
echo "Historical RRD data is still in /var/lib/collectd/rrd/ — remove manually"
echo "if you no longer need it:  sudo rm -rf /var/lib/collectd/rrd/"
