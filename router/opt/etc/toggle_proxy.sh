#!/bin/sh

function perl_replace() {
    local regexp replace file content
    regexp=$1
    # 注意 replace 当中的特殊变量, 例如, $& $1 $2 的手动转义.
    # 写完一定测试一下，perl 变量引用: http://www.perlmonks.org/?node_id=353259
    replace=$2
    escaped_replace=$(echo "$replace" |sed 's#"#\\"#g')

    perl -i -ne "s$regexp$replacegs; print \$_; unless ($& eq \"\") {print STDERR \"\`\033[0;33m$&\033[0m' is replace with \`\033[0;33m${escaped_replace}\033[0m'\n\"};" "$3" "$4"
}

# 为了支持多行匹配，使用 perl 正则, 比 sed 好用一百倍！
function replace_multiline () {
    local regexp replace file content
    regexp=$1
    replace=$2
    file=$3

    perl_replace "$regexp" "$replace" -0 "$file"
}

# disalbe_proxy 并没有停止 v2ray 服务.
# 因为即使关闭透明代理，仍可以通过浏览器插件使用 v2ray 的 socks 代理或 http 代理服务。

dnsmasq_dir=/opt/etc/dnsmasq.d

function clean_dnsmasq_config () {
    if [ -d "$dnsmasq_dir" ]; then
        rm -f $dnsmasq_dir/v2ray.conf
        rmdir $dnsmasq_dir
        chmod +x /opt/etc/restart_dnsmasq.sh && /opt/etc/restart_dnsmasq.sh
    fi
}

function enable_dnsmasq_config () {
    echo -n 'Apply redirect mode. '
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

    if [ -e /opt/etc/use_redirect_proxy ]; then
        enable_dnsmasq_config
    else
        if modprobe xt_TPROXY &>/dev/null; then
            sed -i 's#"tproxy": ".*"#"tproxy": "tproxy"#' /opt/etc/v2ray.json
            if [ -e /opt/etc/use_fakedns ]; then
                replace_multiline '("tag":\s*"transparent",.+?)"destOverride": \[.+?\]' '$1"destOverride": ["fakedns"]' /opt/etc/v2ray.json
                replace_multiline '("servers":\s*\[)(\s*)"8.8.4.4",' '$1$2"fakedns",$2"8.8.4.4",' /opt/etc/v2ray.json
            else
                replace_multiline '("tag":\s*"transparent",.+?)"destOverride": \[.+?\]' '$1"destOverride": ["http", "tls"]' /opt/etc/v2ray.json
                replace_multiline '("servers":\s*\[).*?(\s*)"8.8.4.4",' '$1$2"8.8.4.4",' /opt/etc/v2ray.json
            fi
        else
            enable_dnsmasq_config
        fi
    fi

    chmod +x /opt/etc/init.d/S22v2ray && /opt/etc/init.d/S22v2ray start

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
