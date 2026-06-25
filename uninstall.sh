#!/bin/bash

ipath=/usr/share/adsb-graphs
systemctl stop collectd
systemctl disable --now adsb-graphs

/usr/share/adsb-graphs/gunzip.sh /var/lib/collectd/rrd/localhost

rm -f /etc/systemd/system/collectd.service.d/malarky.conf
rm -f /etc/systemd/system/collectd.service
mv /etc/collectd/collectd.conf.adsb-graphs /etc/collectd/collectd.conf &>/dev/null
rm -f /etc/cron.d/cron-adsb-graphs

lighty-disable-mod adsb-graphs >/dev/null

systemctl daemon-reload
systemctl restart collectd
rm -r $ipath


echo Uninstall finished
