#!/bin/sh

function match_multiline() {
    escaped_regex=$(echo "$1" |sed 's#/#\\\/#g')
    result=$(echo "$2" |perl -0777 -ne "print if /${escaped_regex}/s")

    if [[ "$result" ]]; then
        return 0
    else
        return 1
    fi
}

function perl_replace() {
    local regexp=$1
    # 注意：$1 在 perl 里面是一个矢量, 因此它有 $[ 会出错，因为 perl 会认为在通过 []
    # 方法读取矢量的元素，所以记得在 placement 中 [ 也要转义。
    # 写完一定测试一下，perl 变量引用: http://www.perlmonks.org/?node_id=353259
    local replace=$2
    local escaped_replace=$(echo "$replace" |sed 's#"#\\"#g')

    # 和 sed 类似，就是 g, 表示是否全局替换，不加只替换第一个
    local replace_all_matched=$3
    # 就是 s, 新增的话, . 也匹配 new_line
    local match_newline=$4

    if [ -z "$replace_all_matched" ]; then
        globally=''
    else
        globally=' globally'
    fi

    perl -i -ne "s$regexp$replace${replace_all_matched}${match_newline}; print \$_; unless ($& eq \"\") {print STDERR \"\`\033[0;33m$&\033[0m' was replaced with \`\033[0;33m${escaped_replace}\033[0m'${globally} for \`[0m[0;34m$6[0m'!\n\"};" "$5" "$6"
}

# 为了支持多行匹配，使用 perl 正则, 比 sed 好用一百倍！
function replace_multiline () {
    local regexp=$1
    local replace=$2
    local file=$3

    # 这个 -0 必须的，-0 表示，将空白字符作为 input record separators ($/)
    # 这也意味着，它会将文件内的所有内容整体作为一个字符串一次性读取。
    # 感觉类似于 -0777 (file slurp mode) ?
    perl_replace "$regexp" "$replace" "g" "s" -0777 "$file"
}

function replace_multiline1 () {
    local regexp=$1
    local replace=$2
    local file=$3

    perl_replace "$regexp" "$replace" "" "s" -0777 "$file"
}

# disalbe_proxy 并没有停止 v2ray 服务.
# 因为即使关闭透明代理，仍可以通过浏览器插件使用 v2ray 的 socks 代理或 http 代理服务。

dnsmasq_dir=/opt/etc/dnsmasq.d
v2ray_config=/opt/etc/v2ray.json

function clean_dnsmasq_config () {
    if [ -d "$dnsmasq_dir" ]; then
        rm -f $dnsmasq_dir/v2ray.conf
    fi
}

function enable_dnsmasq_config () {
    if ! which dnsmasq &>/dev/null; then
        echo -e "[0m[1;31mERROR:[0m Transparent proxy based on redirect mode need dnsmasq to serve as LAN DNS server!"
        exit 1
    fi

    echo -n 'Apply dnsmasq config ... '
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

    sed -i 's#"tproxy": ".*"#"tproxy": "redirect"#' $v2ray_config
}

function disable_proxy () {
    echo '[0m[0;33m => Disabling proxy ...[0m'

    if [ -e /opt/etc/init.d/S22v2ray ]; then
        chmod -x /opt/etc/init.d/S22v2ray && sh /opt/etc/init.d/S22v2ray stop
    else
        systemctl disable v2ray && systemctl stop v2ray
    fi
    /opt/etc/clean_iptables_rule.sh && chmod -x /opt/etc/apply_iptables_rule.sh

    if which dnsmasq &>/dev/null; then
        clean_dnsmasq_config
        chmod +x /opt/etc/restart_dnsmasq.sh && /opt/etc/restart_dnsmasq.sh
    fi

    echo '[0m[0;33m => Proxy is disabled.[0m'
}

function enable_proxy () {
    echo '[0m[0;33m => Enabling proxy ...[0m'

    if [ -e /opt/etc/use_redirect_proxy ]; then
        enable_dnsmasq_config
    else
        if modprobe xt_TPROXY &>/dev/null; then
            sed -i 's#"tproxy": ".*"#"tproxy": "tproxy"#' $v2ray_config
            if [ -e /opt/etc/use_fakedns ]; then
                echo 'Apply fakeDNS config ...'
                replace_multiline1 '("tag":\s*"transparent",.+?)"destOverride": \[.+?\]' '$1"destOverride": ["fakedns"]' $v2ray_config
                if ! match_multiline '"servers":\s*\[.*?"fakedns",.*?"8.8.4.4",' "$(cat $v2ray_config)"; then
                    replace_multiline1 '("servers":\s*\[)(.*?)(\s*)"8.8.4.4",' '$1$3"fakedns",$2$3"8.8.4.4",' $v2ray_config
                fi
            else
                echo 'Apply TProxy config ...'
                replace_multiline1 '("tag":\s*"transparent",.+?)"destOverride": \[.+?\]' '$1"destOverride": ["http", "tls"]' $v2ray_config
                replace_multiline1 '("servers":\s*\[).*?(\s*)"8.8.4.4",' '$1$2"8.8.4.4",' $v2ray_config
            fi
        else
            if [ -e /opt/etc/use_fakedns ]; then
                echo -e "[0m[1;31mERROR:[0m Enable fakeDNS need router support TProxy!"
                exit 1
            else
                enable_dnsmasq_config
            fi
        fi
    fi

    if grep '"loglevel":\s*"debug"' $v2ray_config; then
        replace_multiline '"loglevel":\s*"debug"' '"loglevel": "warning"' $v2ray_config
    fi

    chmod +x /opt/etc/apply_iptables_rule.sh && /opt/etc/apply_iptables_rule.sh

    if [ -e /opt/etc/init.d/S22v2ray ]; then
        chmod +x /opt/etc/init.d/S22v2ray && /opt/etc/init.d/S22v2ray start
    else
        systemctl start v2ray && systemctl enable v2ray
    fi

    if which dnsmasq &>/dev/null; then
        chmod +x /opt/etc/restart_dnsmasq.sh && /opt/etc/restart_dnsmasq.sh
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
