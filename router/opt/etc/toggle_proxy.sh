#!/bin/sh

# disalbe_proxy 并没有停止 v2ray 服务.
# 因为即使关闭透明代理，仍可以通过浏览器插件使用 v2ray 的 socks 代理或 http 代理服务。

dnsmasq_dir=/opt/etc/dnsmasq.d

function disable_proxy () {
    echo '[0m[33mDisabling proxy ...[0m'

    /opt/etc/clean_iptables_rule.sh && chmod -x /opt/etc/apply_iptables_rule.sh

    if [ -d "$dnsmasq_dir" ]; then
        rm -f $dnsmasq_dir/v2ray.conf
        chmod +x /opt/etc/restart_dnsmasq.sh && /opt/etc/restart_dnsmasq.sh
    fi

    echo '[0m[33mProxy is disabled.[0m'
}

function enable_proxy () {
    echo '[0m[33mEnabling proxy ...[0m'

    chmod +x /opt/etc/apply_iptables_rule.sh && /opt/etc/apply_iptables_rule.sh

    mkdir -p "$dnsmasq_dir"

    # 为默认的 /etc/dnsmasq.conf 新增配置.
    if ! grep -qs "^conf-dir=$dnsmasq_dir/,\*\.conf$" /etc/dnsmasq.conf; then
        echo "conf-dir=$dnsmasq_dir/,*.conf" >> /etc/dnsmasq.conf
    fi

    # 开启日志.
    # if ! grep -qs "^log-queries$" /etc/dnsmasq.conf; then
    #     echo 'log-queries' >> /etc/dnsmasq.conf
    #     echo 'log-facility=/var/log/dnsmasq.log' >> /etc/dnsmasq.conf
    # fi

    echo 'server=/#/127.0.0.1#65053' > $dnsmasq_dir/v2ray.conf
    chmod +x /opt/etc/restart_dnsmasq.sh && /opt/etc/restart_dnsmasq.sh

    echo '[0m[33mProxy is enabled.[0m'
}

if [ "$1" == 'disable' ]; then
    disable_proxy
elif [ "$1" == 'enable' ]; then
    enable_proxy
elif [ -x /opt/etc/apply_iptables_rule.sh ]; then
    disable_proxy
else
    enable_proxy
fi
