#!/bin/sh

# Update geosite.dat.

tag=$(curl https://github.com/v2ray/domain-list-community/releases/latest |sed 's#.*href="\(.*\)".*#\1#g'|sed 's#.*/\([0-9]*\)#\1#g')

curl -L https://github.com/v2ray/domain-list-community/releases/download/$tag/dlc.dat -o /opt/sbin/geosite.dat.new

cd /opt/sbin

if [ $? == 0 ]; then
    if [ "$(ls -l geosite.dat.new |awk '{print $5}')" -gt 700000 ]; then
        rm -f geosite.dat.old
        mv geosite.dat geosite.dat.old &&
            mv geosite.dat.new geosite.dat &&
            /opt/etc/init.d/S22v2ray restart
    fi
else
    echo 'download failed.'
fi
