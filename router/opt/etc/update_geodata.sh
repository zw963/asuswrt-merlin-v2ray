#!/bin/sh

# Script for update geosite.dat, geoip-only-cn-private.dat.

ROOT=${0%/*}

function github_latest_release () {
    set -ue

    project_name=$1

    tag=$(wget -O - https://github.com/$project_name/releases/latest |egrep -o "$project_name/releases/tag/[^\"]*\" data-view-component" |cut -d'"' -f1 |rev|cut -d'/' -f1 |rev)

    echo "$tag"
}

sitedata=geosite.dat
ipdata=geoip-only-cn-private.dat

geoip_tag=$(github_latest_release v2fly/geoip)

geoip_url=https://github.com/v2fly/geoip/releases/download/${geoip_tag}/$ipdata
wget -c $geoip_url -O $ROOT/${ipdata}.new


geosite_tag=$(github_latest_release v2fly/domain-list-community)
geosite_url=https://github.com/v2fly/domain-list-community/releases/download/${geosite_tag}/dlc.dat
wget -c $geosite_url -O $ROOT/${sitedata}.new

if [ $? == 0 ]; then
    if  [ -e /opt/etc ]; then
        # 假设是路由器环境
        cd $ROOT

        if [ -e /opt/etc/init.d/S22v2ray ]; then
            /opt/etc/init.d/S22v2ray stop
        else
            systemctl stop v2ray
        fi

        if [ "$(ls -l ${sitedata}.new |awk '{print $5}')" -gt 1500000 ]; then
            cp $sitedata ${sitedata}.old
            cp ${sitedata}.new $sitedata
            rm -f ${sitedata}.new
        fi

        if [ "$(ls -l ${ipdata}.new |awk '{print $5}')" -gt 130000 ]; then
            cp $ipdata ${ipdata}.old
            cp ${ipdata}.new $ipdata
            rm -f ${ipdata}.new
        fi

        if [ -e /opt/etc/init.d/S22v2ray ]; then
            /opt/etc/init.d/S22v2ray start
        else
            systemctl start v2ray
        fi
    else
        # 假设是本机部署
        if [ "$(ls -l ${sitedata}.new |awk '{print $5}')" -gt 1500000 ]; then
            cp $sitedata ${sitedata}.old
            cp ${sitedata}.new $sitedata
            rm -f ${sitedata}.new
        fi

        if [ "$(ls -l ${ipdata}.new |awk '{print $5}')" -gt 130000 ]; then
            cp $ipdata ${ipdata}.old
            cp ${ipdata}.new $ipdata
            rm -f ${ipdata}.new
        fi

        echo 'restart proxy to take effect.'
    fi
else
    echo 'download failed.'
fi
