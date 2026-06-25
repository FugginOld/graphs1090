#!/bin/bash
# graphs1090 Phase C cutover — expose Grafana via the existing web server.
#
# What this does (non-destructive):
#   1. Reconfigures Grafana to serve from /grafana/ sub-path.
#   2. Installs a lighttpd or nginx proxy conf.
#   3. Reloads the web server.
#   4. Keeps the old /graphs1090/ PNGs serving unchanged as a fallback.
#
# Usage:  sudo bash collector/cutover.sh
#
# After this script, Grafana is reachable at:
#   http://<host>/grafana/         (via web server proxy)
#   http://<host>:3000/            (direct, still works)
#
# Old PNGs stay at:  http://<host>/graphs1090/

set -e
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND"' ERR

here="$(cd "$(dirname "$0")/.." && pwd)"

# ── detect web server ─────────────────────────────────────────────────────────

webserver=""
if systemctl is-active --quiet lighttpd 2>/dev/null; then
    webserver=lighttpd
elif systemctl is-active --quiet nginx 2>/dev/null; then
    webserver=nginx
fi

if [ -z "$webserver" ]; then
    echo "No running lighttpd or nginx detected."
    echo "Install the proxy conf manually:"
    echo "  lighttpd: config/http/90-grafana-proxy.conf"
    echo "  nginx:    config/http/nginx-graphs1090.conf (grafana block)"
    echo "Then set GF_SERVER_ROOT_URL and GF_SERVER_SERVE_FROM_SUB_PATH in"
    echo "  /etc/grafana/grafana.ini or /etc/default/grafana-server"
    exit 0
fi

echo "Detected web server: $webserver"

# ── configure Grafana sub-path ────────────────────────────────────────────────

echo "== 1. Configure Grafana sub-path /grafana/ =="

grafana_env=/etc/default/grafana-server
if [ -f "$grafana_env" ]; then
    # Remove old GF_SERVER lines we're about to add so re-runs are idempotent.
    sed -i '/^GF_SERVER_ROOT_URL=/d;/^GF_SERVER_SERVE_FROM_SUB_PATH=/d' "$grafana_env"
    {
        echo 'GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s/grafana/'
        echo 'GF_SERVER_SERVE_FROM_SUB_PATH=true'
    } >> "$grafana_env"
    echo "  -> updated $grafana_env"
else
    # Fall back to grafana.ini override section.
    ini=/etc/grafana/grafana.ini
    if grep -q '^\[server\]' "$ini" 2>/dev/null; then
        # Insert after [server] header if not already present.
        if ! grep -q 'serve_from_sub_path' "$ini"; then
            sed -i '/^\[server\]/a root_url = %%(protocol)s://%%(domain)s/grafana/\nserve_from_sub_path = true' "$ini"
            echo "  -> updated $ini"
        else
            echo "  -> $ini already has serve_from_sub_path; skipping"
        fi
    fi
fi

systemctl restart grafana-server

# ── install proxy conf ────────────────────────────────────────────────────────

echo "== 2. Install $webserver proxy conf =="

if [ "$webserver" = lighttpd ]; then
    install -m 0644 "$here/config/http/90-grafana-proxy.conf" \
        /etc/lighttpd/conf-available/90-grafana-proxy.conf

    # lighty-enable-mod creates the symlink in conf-enabled/.
    if command -v lighty-enable-mod &>/dev/null; then
        lighty-enable-mod grafana-proxy || true
    else
        ln -sf /etc/lighttpd/conf-available/90-grafana-proxy.conf \
               /etc/lighttpd/conf-enabled/90-grafana-proxy.conf
    fi

    lighttpd -t -f /etc/lighttpd/lighttpd.conf && systemctl reload lighttpd
    echo "  -> lighttpd reloaded"

elif [ "$webserver" = nginx ]; then
    # The nginx conf file ships combined (legacy + grafana blocks).
    # If the user already has the legacy conf in place, patch it in-place.
    target=""
    for candidate in /etc/nginx/conf.d/graphs1090.conf \
                     /etc/nginx/sites-enabled/graphs1090 \
                     /etc/nginx/sites-available/graphs1090; do
        [ -f "$candidate" ] && target="$candidate" && break
    done

    if [ -n "$target" ]; then
        if ! grep -q '/grafana/' "$target"; then
            cat >> "$target" <<'NGINXBLOCK'

# graphs1090 Grafana reverse proxy (Phase C cutover)
location /grafana/ {
  proxy_pass         http://127.0.0.1:3000/grafana/;
  proxy_http_version 1.1;
  proxy_set_header   Upgrade $http_upgrade;
  proxy_set_header   Connection "upgrade";
  proxy_set_header   Host $host;
}
location = /grafana {
  absolute_redirect off;
  return 301 /grafana/;
}
NGINXBLOCK
            echo "  -> appended Grafana block to $target"
        else
            echo "  -> $target already has /grafana/ block; skipping"
        fi
    else
        echo "  -> no existing graphs1090 nginx conf found; installing new file"
        install -m 0644 "$here/config/http/nginx-graphs1090.conf" \
            /etc/nginx/conf.d/graphs1090.conf
    fi

    nginx -t && systemctl reload nginx
    echo "  -> nginx reloaded"
fi

# ── done ──────────────────────────────────────────────────────────────────────

ip=$(hostname -I 2>/dev/null | awk '{print $1}')
echo
echo "== Phase C done =="
echo "Grafana (via proxy):  http://${ip}/grafana/"
echo "Grafana (direct):     http://${ip}:3000/"
echo "Old PNGs (unchanged): http://${ip}/graphs1090/"
echo
echo "Verify panels show live data, then run:"
echo "  sudo bash collector/decommission.sh"
echo "to remove the old collectd/RRD pipeline (Phase D, irreversible)."
