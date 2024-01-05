#!/usr/bin/env sh

if iptables -t nat -C PREROUTING -p tcp -j V2RAY_TCP 2>/dev/null; then
    exit 0
fi

ROOT=${0%/*}/

if [ -t 1 ]; then
    if [ -e /opt/etc/clean_iptables_rule.sh ]; then
        /opt/etc/clean_iptables_rule.sh
    else
        $ROOT/clean_iptables_rule.sh
    fi
fi

echo -n ' Applying redirect rule ...'

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

if [ -n "$v2ray_config" ]; then
    config_file=$v2ray_config
elif [ -e /opt/etc/v2ray.json ]; then
    config_file=/opt/etc/v2ray.json
else
    config_file=./v2ray.json
fi

sed -i 's#"tproxy": ".*"#"tproxy": "redirect"#' $config_file

local_v2ray_port=$(cat $config_file |grep '"inbounds"' -A10 |grep '"protocol" *: *"dokodemo-door"' -A10 |grep -o '"port": [0-9]*,' |grep -o '[0-9]*')

if [ -z "$local_v2ray_port" ]; then
    echo "can not find out v2ray port setting in $config_file"
    exit
fi

v2ray_server_ip=$(cat $config_file |grep 'protocol":\s*"\(vmess\|vless\)' -A10 |grep -o '"address": ".*",'|cut -d: '-f2'|cut -d'"' -f2)

if [ -z "$v2ray_server_ip" ]; then
    echo "can not find out remote VPS ip/domain in $config_file"
    exit
fi

iptables -t nat -N V2RAY_TCP # 代理局域网 TCP 流量

# step 1: 所有针对本地地址、局域网地址、VPS 服务器地址的流量直连
iptables -t nat -A V2RAY_TCP -d 127.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY_TCP -d $v2ray_server_ip -j RETURN
iptables -t nat -A V2RAY_TCP -d 192.168.0.0/16 -j RETURN

# step 4: 从 V2Ray 发出的流量，再次经过时 netfilter 时，如果是 V2Ray 标记过
# 为 255 的流量，全部走直连.
iptables -t nat -A V2RAY_TCP -p tcp -j RETURN -m mark --mark 0xff

# step 2: 所有剩下的流量会转发给 V2Ray 本地监听的端口.
# REDIRECT其实是 DNAT 的一种特殊形式，
# 特殊在其把数据包的目标 IP 改成了 127.0.0.1，端口改成了--to-ports 参数指定的本地端口，
# 这样本机的透明代理程序就能处理这个包，应用能通过内核的状态信息拿到被改写之前的目标 IP 和端口号
iptables -t nat -A V2RAY_TCP -p tcp -j REDIRECT --to-ports $local_v2ray_port

# step 3: V2Ray 内部处理，并将 outbounds 的流量全部通过 streamSettings.sockopt.mark: 255, set mark 255.

# 应用到 PREROUTING 关卡的事情：
# 1. 针对目标地址为本地地址、VPS 地址的数据包，直接返回
# 2. 剩下的目标地址为远程地址的数据包，全部转发到 local v2ray port

# 针对外部来的流量，应用 V2RAY_TCP 策略
iptables -t nat -A PREROUTING -p tcp -j V2RAY_TCP

# 将 V2RAY_TCP 这个 rule-chain, 附加到 OUTPUT 这个网关的 `nat 占位符' 的最后面.
iptables -t nat -A OUTPUT -p tcp -j V2RAY_TCP

if which dnsmasq &>/dev/null; then
    chmod +x /opt/etc/restart_dnsmasq.sh && /opt/etc/restart_dnsmasq.sh
fi
