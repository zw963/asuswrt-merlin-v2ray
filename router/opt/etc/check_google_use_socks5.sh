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

if [ "$user_asuswrt" == "true" ]; then
    echo 'Current curl verison not support socks5 proxy'
    exit 1
else
    curl -so /dev/null -w "Check ${1-google.com} use socks5://127.0.0.1:1080, %{http_code}\n" ${1-google.com} -x socks5://127.0.0.1:1080
fi
