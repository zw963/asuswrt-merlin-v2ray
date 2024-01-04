#!/bin/sh

echo -n 'Restart dnsmasq ...'

# 一个坑：华硕路由器如果 kill 掉 dnsmasq 的进程，也会重新初始化 /etc/dnsmasq.conf 配置
# 因此，只需要发送 SIGHUP 即可，它会清除 cache, 并且 重新加载配置。

dnsmasq --test 2>/dev/null && kill -HUP $(ps |grep dnsmasq |grep nobody |awk '{print $1}')

echo '[0m[1;32m done.[0m'
