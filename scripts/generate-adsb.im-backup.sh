#!/bin/bash
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

function cleanup {
    systemctl restart collectd
}

set -e

cd /usr/share/adsb-graphs/html/
rm -rf /usr/share/adsb-graphs/html/ultrafeeder
mkdir -p ultrafeeder/adsb-graphs/rrd

if dpkg --print-architecture | grep 64; then
    trap cleanup EXIT
    systemctl stop collectd

    if ! [[ -f /var/lib/collectd/rrd/localhost.tar.gz ]]; then
        pushd /var/lib/collectd/rrd
        tar -cz -f rrd.tar.gz localhost
        popd
        cp /var/lib/collectd/rrd/rrd.tar.gz ultrafeeder/adsb-graphs/rrd/localhost.tar.gz
    else
        cp /var/lib/collectd/rrd/localhost.tar.gz ultrafeeder/adsb-graphs/rrd/localhost.tar.gz
    fi

else
    /usr/share/adsb-graphs/rrd-dump.sh /var/lib/collectd/rrd/localhost /usr/share/adsb-graphs/html/ultrafeeder/adsb-graphs/xml.tar.gz
fi
rm -f adsb-graphs-to-adsb.im.backup
zip -0 -r adsb-graphs-to-adsb.im.backup ultrafeeder >/dev/null
rm -rf ultrafeeder

echo
echo "All done!"
echo "Backup should be available at http://$(ip route get 1.2.3.4 | grep -m1 -o -P 'src \K[0-9,.]*')/adsb-graphs/adsb-graphs-to-adsb.im.backup"
echo
