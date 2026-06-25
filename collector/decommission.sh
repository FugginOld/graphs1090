#!/bin/bash
# graphs1090 Phase D decommission — remove the old collectd/RRD pipeline.
#
# THIS IS IRREVERSIBLE. Run only after:
#   - Phase C cutover is complete (Grafana is serving live data)
#   - You have verified Grafana panels match the old PNGs
#   - You no longer need the PNG fallback at /graphs1090/
#
# What is removed:
#   - collectd service (stopped + disabled)
#   - /usr/share/graphs1090/{html,graphs1090.sh,...} render pipeline files
#   - Legacy lib/ and scripts/ directories from the repo install
#   - collectd package (optional, prompted)
#   - Old lighttpd/nginx /graphs1090/ web conf (optional, prompted)
#
# What is kept:
#   - /var/lib/collectd/rrd/  (your historical RRD data; delete manually if wanted)
#   - Telegraf + InfluxDB + Grafana (the new stack, untouched)
#   - /usr/share/graphs1090/adsb_telegraf.py and adsb_stats.py (new collector)
#   - /usr/share/graphs1090/adsb_collector.conf (your runtime config)
#
# Usage:  sudo bash collector/decommission.sh

set -e
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND"' ERR

ipath=/usr/share/graphs1090

# ── confirmation gate ─────────────────────────────────────────────────────────

echo "=========================================================="
echo "  graphs1090 Phase D — decommission old collectd/RRD stack"
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
    "$ipath/graphs1090.sh"
    "$ipath/service-graphs1090.sh"
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
for f in /etc/collectd/conf.d/graphs1090.conf /etc/collectd/graphs1090.conf; do
    if [ -f "$f" ]; then
        rm "$f"
        echo "  -> removed $f"
    fi
done

# ── remove PNG output directory ───────────────────────────────────────────────

echo "== 3. Remove PNG output directory =="
for d in /run/graphs1090 /var/run/graphs1090; do
    if [ -d "$d" ]; then
        rm -rf "$d"
        echo "  -> removed $d"
    fi
done

# Remove the tmpfs mount from /etc/fstab if present.
if grep -q 'graphs1090' /etc/fstab 2>/dev/null; then
    sed -i '/graphs1090/d' /etc/fstab
    echo "  -> removed graphs1090 tmpfs from /etc/fstab"
fi

# ── optional: remove /graphs1090/ web conf ────────────────────────────────────

echo
read -r -p "Remove the old /graphs1090/ web conf (lighttpd/nginx)? [y/N] " rm_webconf
if [[ "$rm_webconf" =~ ^[Yy]$ ]]; then
    for f in /etc/lighttpd/conf-available/88-graphs1090.conf \
              /etc/lighttpd/conf-enabled/88-graphs1090.conf \
              /etc/lighttpd/conf-available/95-graphs1090-otherport.conf \
              /etc/lighttpd/conf-enabled/95-graphs1090-otherport.conf; do
        [ -f "$f" ] && rm "$f" && echo "  -> removed $f"
    done
    # nginx
    for f in /etc/nginx/conf.d/graphs1090.conf \
              /etc/nginx/sites-enabled/graphs1090 \
              /etc/nginx/sites-available/graphs1090; do
        if [ -f "$f" ]; then
            # Remove legacy /graphs1090 blocks but keep any /grafana/ block.
            if grep -q '/grafana/' "$f"; then
                # File has both; strip only the legacy locations.
                sed -i '/location \/graphs1090/,/^}/d' "$f"
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
