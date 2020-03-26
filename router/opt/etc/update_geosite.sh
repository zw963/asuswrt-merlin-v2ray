#!/bin/sh

# Update geosite.dat.

tag=$(curl https://github.com/v2ray/domain-list-community/releases/latest |sed 's#.*href="\(.*\)".*#\1#g'|sed 's#.*/\([0-9]*\)#\1#g')

curl -L https://github.com/v2ray/domain-list-community/releases/download/$tag/dlc.dat -o /opt/sbin/geosite.dat.new

if [ $? == 0 ]; then
    cp /opt/sbin/geosite.dat.new /opt/sbin/geosite.dat
    rm /opt/sbin/geosite.dat.new
    /opt/etc/init.d/S22v2ray restart
else
    echo 'download failed.'
fi
