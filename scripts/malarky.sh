#!/bin/bash

if diff /usr/share/adsb-graphs/malarky.conf /etc/systemd/system/collectd.service.d/malarky.conf \
    && grep -qs -e 'DataDir "/run/collectd"' /etc/collectd/collectd.conf \
    && grep -qs -e 'DB=/run/collectd' /etc/default/adsb-graphs
then
    echo ---------
    echo write reducing measures already enabled, no need to do anything for this script!
    echo ---------
    exit 0
fi

systemctl stop collectd &>/dev/null

set -e
mkdir -p /etc/systemd/system/collectd.service.d
rm -f /etc/systemd/system/collectd.service
cp -f /usr/share/adsb-graphs/malarky.conf /etc/systemd/system/collectd.service.d/malarky.conf
set +e
sed -i -e 's?DataDir.*?DataDir "/run/collectd"?' /etc/collectd/collectd.conf

if ! grep -qs -e '^DB=' /etc/default/adsb-graphs; then
    echo "DB=" >>/etc/default/adsb-graphs
fi

sed -i -e 's#^DB=.*#DB=/run/collectd#' /etc/default/adsb-graphs

systemctl daemon-reload
systemctl restart collectd
systemctl restart adsb-graphs

cat >/etc/cron.d/collectd_to_disk <<"EOF"
# restart collectd so data is saved to disk
42 23 * * * root /bin/systemctl restart collectd
EOF

# remove legacy stuff
rm -rf "$TARGET/adsb-graphs-writeback-backup1" "$TARGET/adsb-graphs-writeback-backup2"

rm -f /usr/share/adsb-graphs/noMalarky

echo ---------
echo write reducing measures enabled!
echo ---------
