#!/bin/bash

if ! opkg --version &>/dev/null; then
    # 旁路由
    alias iptables='sudo iptables'
    alias ip='sudo ip'
    alias modprobe='sudo modprobe'
    dns_port=53
    sleep=0.2
else
    # 路由器
    use_asuswrt=true
    dns_port=65053
    sleep=1
fi

curl_version=$(curl -V |head -n1 |awk '{print $2}')

function version_less_than () {
    local currentver="$1"
    local requiredver="$2"
    local sort

    if sort -V --version &>/dev/null; then
        sort='sort -V'
    else
        # sort -V 是 GNU 扩展，这里兼容性原因，选择 sort -n，但可能不准确
        sort='sort -n'
    fi

    if [ "$(printf '%s\n' "$requiredver" "$currentver" | $sort | head -n1)" == "$requiredver" ]; then
        # greater than or equal
        false
    else
        # less than
        true
    fi
}

if version_less_than $curl_version 7.60.0; then
    echo "Current curl verison $curl_version not support socks5 proxy, exit ..."
    exit 1
fi

curl -so /dev/null -w "Check ${1-google.com} use socks5://127.0.0.1:1080, %{http_code}\n" ${1-google.com} -x socks5://127.0.0.1:1080
