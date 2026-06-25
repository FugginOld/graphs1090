#!/bin/bash

DB=/var/lib/collectd/rrd

source /etc/default/adsb-graphs

# autodetect and use /run/collectd as DB folder if it exists and has localhost
# folder having it automatically changed in /etc/default/adsb-graphs causes
# issues for example when the user replaces his configuration with the default
# which is a valid approach
if [[ -d /run/collectd/localhost ]]; then
    DB=/run/collectd
fi

export DB
