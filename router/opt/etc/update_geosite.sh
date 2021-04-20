#!/bin/sh

# Update geosite.dat.

tag=$(curl https://github.com/v2fly/domain-list-community/releases/latest |sed 's#.*href="\(.*\)".*#\1#g'|sed 's#.*/\([0-9]*\)#\1#g')

curl -L https://github.com/v2fly/domain-list-community/releases/download/$tag/dlc.dat -o /opt/sbin/geosite.dat.new

if [ $? == 0 ]; then
    cd /opt/sbin

    /opt/etc/init.d/S22v2ray stop

    rm -f geosite.dat.old
    cp geosite.dat geosite.dat.old

    if [ "$(ls -l geosite.dat.new |awk '{print $5}')" -gt 1000000 ]; then
         cp geosite.dat.new geosite.dat
    fi

    /opt/etc/init.d/S22v2ray restart
else
    echo 'download failed.'
fi
