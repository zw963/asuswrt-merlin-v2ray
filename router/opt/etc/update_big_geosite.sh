#!/bin/sh

# Update big geosite.dat.

tag=$(curl https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest |sed 's#.*href="\(.*\)".*#\1#g'|sed 's#.*/\([0-9]*\)#\1#g')

curl -L https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/$tag/geosite.dat -o /opt/sbin/geosite.dat.new

if [ $? == 0 ]; then
    cd /opt/sbin

    /opt/etc/init.d/S22v2ray stop

    rm -f geosite.dat.old
    cp geosite.dat geosite.dat.old

    if [ "$(ls -l geosite.dat.new |awk '{print $5}')" -gt 4000000 ]; then
         cp geosite.dat.new geosite.dat
    fi

    /opt/etc/init.d/S22v2ray restart
else
    echo 'download failed.'
fi
