#!/bin/sh

# 一个坑：华硕路由器如果 kill 掉 dnsmasq 的进程，也会重新初始化 /etc/dnsmasq.conf 配置
# 因此，只需要发送 SIGHUP 即可，它会清除 cache, 并且 重新加载配置。

if ! which dnsmasq &>/dev/null; then
    echo -e "[0m[1;31mERROR:[0m No dnsmasq installed, exit ..."
    exit 1
fi

echo -n 'Apply dnsmasq config ... '

dnsmasq_dir=/opt/etc/dnsmasq.d

mkdir -p "$dnsmasq_dir"

# 为默认的 /etc/dnsmasq.conf 新增配置.
if ! grep -qs "^conf-dir=$dnsmasq_dir/,\*\.conf$" /etc/dnsmasq.conf; then
    echo "conf-dir=$dnsmasq_dir/,*.conf" >> /etc/dnsmasq.conf
fi

echo 'server=/#/127.0.0.1#65053' > $dnsmasq_dir/v2ray.conf

if [ "$1" == 'with_log' ]; then
    # 开启日志.
    if ! grep -qs "^log-queries$" /etc/dnsmasq.conf; then
        echo 'log-queries' >> $dnsmasq_dir/v2ray.conf
        echo 'log-facility=/tmp/dnsmasq.log' >> $dnsmasq_dir/v2ray.conf
    fi
fi

dnsmasq --test 2>/dev/null && kill -HUP $(ps |grep dnsmasq |grep nobody |awk '{print $1}')

echo '[0m[1;32m done.[0m'

date "+%Y%m%d_%H:%M:%S" > /tmp/restart_dnsmasq_was_run_at
