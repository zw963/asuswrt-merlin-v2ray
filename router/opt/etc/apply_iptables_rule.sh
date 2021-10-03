#!/bin/sh

if [ -t 1 ]; then
    /opt/etc/clean_iptables_rule.sh
fi

if iptables -t nat -C PREROUTING -p tcp -j V2RAY_TCP 2>/dev/null ||
        iptables -t mangle -C PREROUTING -j V2RAY_UDP 2>/dev/null; then
    exit 0
fi

echo -n 'Applying iptables rule ...'

ipset_protocal_version=$(ipset -v 2>/dev/null |grep -o 'version.*[0-9]' |head -n1 |cut -d' ' -f2)

if [ "$ipset_protocal_version" -gt 6 ]; then
    alias iptables='/usr/sbin/iptables'
else
    alias iptables='/opt/sbin/iptables'
fi

local_v2ray_port=$(cat /opt/etc/v2ray.json |grep '"inbounds"' -A10 |grep '"protocol" *: *"dokodemo-door"' -A10 |grep -o '"port": [0-9]*,' |grep -o '[0-9]*')

if [ -z "$local_v2ray_port" ]; then
    echo 'can not find out v2ray port setting in /opt/etc/v2ray.json'
    exit
fi

v2ray_server_ip=$(cat /opt/etc/v2ray.json |grep 'protocol":\s*\"vmess' -A10 |grep -o '"address": ".*",'|cut -d: '-f2'|cut -d'"' -f2)

if [ -z "$v2ray_server_ip" ]; then
    echo 'can not find out remote VPS ip/domain in /opt/etc/v2ray.json'
    exit
fi

LOCAL_IPS="
0.0.0.0/8
10.0.0.0/8
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
224.0.0.0/4
240.0.0.0/4
255.255.255.255/32
"

function apply_redirect_rule () {
    echo -n ' Applying redirect rule ...'
    iptables -t nat -N V2RAY_TCP # 代理局域网 TCP 流量
    for local_ip in $LOCAL_IPS; do
        iptables -t nat -A V2RAY_TCP -d $local_ip -j RETURN
    done
    iptables -t nat -A V2RAY_TCP -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A V2RAY_TCP -d $v2ray_server_ip -j RETURN
    # 如果是 V2Ray 标记过、并再次发出的流量(通过 streamSettings.sockopt.mark: 255 设置),
    # 全部走直连，不这样做就成了死循环了。
    iptables -t nat -A V2RAY_TCP -p tcp -j RETURN -m mark --mark 0xff
    # REDIRECT其实是 DNAT 的一种特殊形式，
    # 特殊在其把数据包的目标 IP 改成了 127.0.0.1，端口改成了--to-ports 参数指定的本地端口，
    # 这样本机的透明代理程序就能处理这个包，应用能通过内核的状态信息拿到被改写之前的目标 IP 和端口号
    iptables -t nat -A V2RAY_TCP -p tcp -j REDIRECT --to-ports $local_v2ray_port

    # apply rule
    iptables -t nat -A PREROUTING -p tcp -j V2RAY_TCP
    iptables -t nat -A OUTPUT -p tcp -j V2RAY_TCP
}

function apply_tproxy_rule () {
    echo -n ' Applying TProxy rule ...'
    # 使用一个特殊的路由，将数据包指向本地
    ip rule add fwmark 1 table 100
    ip route add local default dev lo table 100

    # 由于使用了mangle表，所以数据包的原始和目的地址都是不会被修改的。
    iptables -t mangle -N V2RAY_UDP

    for local_ip in $LOCAL_IPS; do
        iptables -t mangle -A V2RAY_UDP -d $local_ip -j RETURN
    done

    iptables -t mangle -A V2RAY_UDP -d $v2ray_server_ip -j RETURN

    iptables -t mangle -A V2RAY_UDP -d 192.168.0.0/16 -p tcp -j RETURN
    # 本地局域网内，除了发至 53 端口的流量(会被 tproxy 标记)，其余全部直连.
    iptables -t mangle -A V2RAY_UDP -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN

    iptables -t mangle -A V2RAY_UDP -p udp -j TPROXY --on-port $local_v2ray_port --tproxy-mark 1
    iptables -t mangle -A V2RAY_UDP -p tcp -j TPROXY --on-port $local_v2ray_port --tproxy-mark 1
    iptables -t mangle -A PREROUTING -j V2RAY_UDP
}

function apply_gateway_rule () {
    iptables -t mangle -N V2RAY_MASK # 代理网关本机
    for local_ip in $LOCAL_IPS; do
        iptables -t mangle -A V2RAY_MASK -d $local_ip -j RETURN
    done

    iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -p tcp -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN # 直连局域网，53 端口除外（因为要使用 V2Ray 的 DNS）
    iptables -t mangle -A V2RAY_MASK -j RETURN -m mark --mark 0xff    # 直连 SO_MARK 为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面V2Ray 配置的 255)，此规则目的是避免代理本机(网关)流量出现回环问题

    iptables -t mangle -A V2RAY_MASK -p udp -j MARK --set-mark 1   # 给 UDP 打标记,重路由
    iptables -t mangle -A V2RAY_MASK -p tcp -j MARK --set-mark 1   # 给 TCP 打标记，重路由

    iptables -t mangle -A OUTPUT -j V2RAY_MASK # 应用规则
}

if [ -e /opt/etc/use_redirect_proxy ]; then
    apply_redirect_rule
else
    if modprobe xt_TPROXY &>/dev/null; then
        apply_tproxy_rule
    else
        apply_redirect_rule
    fi
fi

echo '[0m[1;32m done.[0m'
