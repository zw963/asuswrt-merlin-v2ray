#!/bin/sh

if [ -t 1 ]; then
    /opt/etc/clean_iptables_rule.sh
fi

if iptables -t nat -C PREROUTING -p tcp -j V2RAY_TCP 2>/dev/null; then
    exit 0
fi

echo '[0m[33mApplying iptables rule ...[0m'

ipset_protocal_version=$(ipset -v |grep -o 'version.*[0-9]' |head -n1 |cut -d' ' -f2)

if [ "$ipset_protocal_version" -gt 6 ]; then
    alias iptables='/usr/sbin/iptables'
else
    alias iptables='/opt/sbin/iptables'
fi

local_v2ray_port=$(cat /opt/etc/v2ray.json |grep '"inbounds"' -A10 |grep '"protocol" *: *"dokodemo-door"' -A10 |grep '"port"' |grep -o '[0-9]*')

if [ -z "$local_v2ray_port" ]; then
    echo 'can not find out v2ray port setting in /opt/etc/v2ray.json'
    exit
fi

v2ray_server_ip=$( cat /opt/etc/v2ray.json |grep 'protocol":\s*\"vmess' -A10 |grep '"address"'|cut -d: '-f2'|cut -d'"' -f2)

LOCAL_IPS="
0.0.0.0/8
10.0.0.0/8
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.168.0.0/16
224.0.0.0/4
240.0.0.0/4
"

iptables -t nat -N V2RAY_TCP
for local_ip in $LOCAL_IPS; do
    iptables -t nat -A V2RAY_TCP -d $local_ip -j RETURN
done
iptables -t nat -A V2RAY_TCP -d $v2ray_server_ip -j RETURN

# 如果是 V2Ray 标记过、并再次发出的流量(通过 streamSettings.sockopt.mark: 255),
# 全部走直连，不这样做就成了死循环了。
iptables -t nat -A V2RAY_TCP -p tcp -j RETURN -m mark --mark 0xff

# REDIRECT其实是 DNAT 的一种特殊形式，
# 特殊在其把数据包的目标 IP 改成了 127.0.0.1，端口改成了--to-ports 参数指定的本地端口，
# 这样本机的透明代理程序就能处理这个包，应用能通过内核的状态信息拿到被改写之前的目标 IP 和端口号
iptables -t nat -A V2RAY_TCP -p tcp -j REDIRECT --to-ports $local_v2ray_port
# apply rule
iptables -t nat -A PREROUTING -p tcp -j V2RAY_TCP
iptables -t nat -A OUTPUT -p tcp -j V2RAY_TCP

if modprobe xt_TPROXY &>/dev/null; then
    # Add any UDP rules
    ip rule add fwmark 1 table 100
    ip route add local default dev lo table 100

    iptables -t mangle -N V2RAY_UDP

    for local_ip in $LOCAL_IPS; do
        iptables -t mangle -A V2RAY_UDP -d $local_ip -j RETURN
    done
    iptables -t mangle -A V2RAY_UDP -d $v2ray_server_ip -j RETURN
    iptables -t mangle -A V2RAY_UDP -p udp -j TPROXY --on-port $local_v2ray_port --tproxy-mark 1
    # Apply the rules
    iptables -t mangle -A PREROUTING -j V2RAY_UDP
fi

echo '[0m[33mDone apply iptables rule.[0m'
