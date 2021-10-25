#!/bin/sh

# Update geosite.dat.

tag=$(curl https://github.com/v2fly/domain-list-community/releases/latest |sed 's#.*href="\(.*\)".*#\1#g'|sed 's#.*/\([0-9]*\)#\1#g')

curl -L https://github.com/v2fly/domain-list-community/releases/download/$tag/dlc.dat -o /opt/sbin/geosite.dat.new

if [ $? == 0 ]; then
    cd /opt/sbin

    if [ -e /opt/etc/init.d/S22v2ray ]; then
        /opt/etc/init.d/S22v2ray stop
    else
        systemctl stop v2ray
    fi

    rm -f geosite.dat.old
    cp geosite.dat geosite.dat.old

    if [ "$(ls -l geosite.dat.new |awk '{print $5}')" -gt 1000000 ]; then
         cp geosite.dat.new geosite.dat
    fi

    if [ -e /opt/etc/init.d/S22v2ray ]; then
        /opt/etc/init.d/S22v2ray start
    else
        systemctl start v2ray
    fi
else
    echo 'download failed.'
fi
