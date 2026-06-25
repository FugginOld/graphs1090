#!/bin/bash
systemctl stop collectd &>/dev/null

rm -f /etc/systemd/system/collectd.service
rm -f /etc/systemd/system/collectd.service.d/malarky.conf
sed -i -e 's?DataDir.*?DataDir "/var/lib/collectd/rrd/"?' /etc/collectd/collectd.conf

if ! grep -qs -e '^DB=' /etc/default/adsb-graphs; then
    echo "DB=" >>/etc/default/adsb-graphs
fi

sed -i -e 's#^DB=.*#DB=/var/lib/collectd/rrd#' /etc/default/adsb-graphs

systemctl daemon-reload

/usr/share/adsb-graphs/gunzip.sh /var/lib/collectd/rrd/localhost

systemctl restart collectd
systemctl restart adsb-graphs

rm -f /etc/cron.d/collectd_to_disk

touch /usr/share/adsb-graphs/noMalarky

echo ---------
echo write reducing measures disabled!
echo ---------
