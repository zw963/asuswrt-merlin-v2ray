#!/bin/sh

# 一个坑：华硕路由器如果 kill 掉 dnsmasq 的进程，也会重新初始化 /etc/dnsmasq.conf 配置
# 因此，只需要发送 SIGHUP 即可，它会清除 cache, 并且 重新加载配置。

if ! which dnsmasq &>/dev/null; then
    echo -e "[0m[1;31mERROR:[0m No dnsmasq installed, exit ..."
    exit 1
fi

echo -n 'Apply dnsmasq config ... '

if [ -n "$v2ray_config" ]; then
    config_file=$v2ray_config
elif [ -e /opt/etc/config.json ]; then
    config_file=/opt/etc/config.json
else
    config_file=./config.json
fi

# 因为 redirct 的方式几乎不用了，所以相应的配置从默认生成的配置中移除，
# 并在这里通过指出要做哪些修改，让用户通过手动修改来实现。

cat <<'HEREDOC'
如果需要使用 redirect 方式，还需要依照如下操作修改配置文件：
1. 将下面的配置加入 inbound 的第一条（transparent那条）的后面。
这会在 65053 监听，配合后面的 dnsmasq 的替换，会将所有 DNS 请求转发到 65053, 才有意义。

{
    // redirect 透明代理必需(不支持tproxy时), 用来接受从 dnsmasq 转发过来的 DNS 流量。
    "tag": "dns-inbound",
    "protocol": "dokodemo-door",
    "port": 65053, // 当使用 redirect 模式时, 在 65053 端口监听来自于 dnsmasq 的 udp 流量.
    // "settings": {
        //    // 这里是流量被转发到的地址，端口，可接受的网络协议类型
        //    // 注意： 这有别于 dns-outbound 中对应的配置，后者是直接修改 DNS 服务器地址/端口
        //    // 因为这里的流量直接来自 dnsmasq, 所以这个 address 必须填, 似乎随便填都可以.
        //    "address": "8.8.4.4",
        //    "port": 53,
        //    "network": "udp"
        // }
},

2. 将下面的配置加入 routing 的 rules 中
所有进入的 dns-inbound 的DNS 查询，会全部进入 dns-outbound
而 dns-outbound 唯一作用就是将 DNS  IP 查询（即 A 和 AAAA）转发给内置的 DNS 服务器
dns-outbound 本身在 tproxy 模式下，使用 rule 将来自于透明代理 1081 的 53 端口的
UDP 协议请求，转发到 dns-outbound
{
    // redirect 透明代理必需。
    "type": "field",
    "inboundTag": ["dns-inbound"],
    "outboundTag": "dns-outbound"
},

3. 替换 inbounds 里面的第一条，streamSettings 里面 "tproxy": "tproxy" 为 "tproxy": "redirect"
sed -i 's#"tproxy": ".*"#"tproxy": "redirect"#' $config_file
HEREDOC

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
