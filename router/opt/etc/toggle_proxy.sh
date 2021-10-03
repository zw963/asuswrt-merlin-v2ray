#!/bin/sh

# disalbe_proxy 并没有停止 v2ray 服务.
# 因为即使关闭透明代理，仍可以通过浏览器插件使用 v2ray 的 socks 代理或 http 代理服务。

dnsmasq_dir=/opt/etc/dnsmasq.d

function clean_dnsmasq_config () {
    if [ -d "$dnsmasq_dir" ]; then
        rm -f $dnsmasq_dir/v2ray.conf
        chmod +x /opt/etc/restart_dnsmasq.sh && /opt/etc/restart_dnsmasq.sh
    fi
}

function enable_dnsmasq_config () {
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
            echo 'log-facility=/var/log/dnsmasq.log' >> $dnsmasq_dir/v2ray.conf
        fi
    fi

    chmod +x /opt/etc/restart_dnsmasq.sh && /opt/etc/restart_dnsmasq.sh

    sed -i 's#"tproxy": ".*"#"tproxy": "redirect"#' /opt/etc/v2ray.json
}

function disable_proxy () {
    echo '[0m[0;33m => Disabling proxy ...[0m'

    /opt/etc/clean_iptables_rule.sh && chmod -x /opt/etc/apply_iptables_rule.sh
    chmod -x /opt/etc/init.d/S22v2ray && sh /opt/etc/init.d/S22v2ray stop

    clean_dnsmasq_config

    echo '[0m[0;33m => Proxy is disabled.[0m'
}

function enable_proxy () {
    echo '[0m[0;33m => Enabling proxy ...[0m'

    chmod +x /opt/etc/apply_iptables_rule.sh && /opt/etc/apply_iptables_rule.sh
    chmod +x /opt/etc/init.d/S22v2ray && /opt/etc/init.d/S22v2ray start

    if [ -e /opt/etc/use_redirect_proxy ]; then
        enable_dnsmasq_config
    else
        if modprobe xt_TPROXY &>/dev/null; then
            sed -i 's#"tproxy": ".*"#"tproxy": "tproxy"#' /opt/etc/v2ray.json
        else
            enable_dnsmasq_config
        fi
    fi

    echo '[0m[0;33m => Proxy is enabled.[0m'
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
