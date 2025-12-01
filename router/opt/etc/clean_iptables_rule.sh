#!/bin/sh

[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

echo -n 'Cleaning iptables rule ...'

if ! opkg --version &>/dev/null; then
    # 旁路由
    dns_port=53
    sleep=0.2
else
    # 路由器
    use_asuswrt=true
    dns_port=65053
    sleep=1
fi

# clean old version rule, maybe delete later.
while iptables -t nat -C PREROUTING -p tcp -j V2RAY_TCP 2>/dev/null; do
    iptables -t nat -D PREROUTING -p tcp -j V2RAY_TCP
    iptables -t nat -D OUTPUT -p tcp -j V2RAY_TCP
    sleep $sleep
done
iptables -t nat -F V2RAY_TCP 2>/dev/null          # flush
iptables -t nat -X V2RAY_TCP 2>/dev/null          # --delete-chain

while iptables -t mangle -C PREROUTING -j V2RAY_UDP 2>/dev/null; do
    iptables -t mangle -D PREROUTING -j V2RAY_UDP
    sleep $sleep
done
iptables -t mangle -F V2RAY_UDP 2>/dev/null          # flush
iptables -t mangle -X V2RAY_UDP 2>/dev/null          # --delete-chain

while iptables -t nat -C PREROUTING -p udp -j V2RAY_DNS 2>/dev/null; do
    iptables -t nat -D PREROUTING -p udp -j V2RAY_DNS
    sleep $sleep
done
iptables -t nat -F V2RAY_DNS 2>/dev/null
iptables -t nat -X V2RAY_DNS 2>/dev/null

while iptables -t mangle -C OUTPUT -j V2RAY_MASK 2>/dev/null; do
    iptables -t mangle -D OUTPUT -j V2RAY_MASK
    sleep $sleep
done
iptables -t mangle -F V2RAY_MASK 2>/dev/null          # flush
iptables -t mangle -X V2RAY_MASK 2>/dev/null          # --delete-chain

while iptables -t mangle -C PREROUTING -p tcp -m socket -j DIVERT 2>/dev/null; do
    iptables -t mangle -D PREROUTING -p tcp -m socket -j DIVERT
    sleep $sleep
done
iptables -t mangle -F DIVERT 2>/dev/null          # flush
iptables -t mangle -X DIVERT 2>/dev/null          # --delete-chain

ip route del local default dev lo table 100 2>/dev/null
ip rule del fwmark 1 table 100 2>/dev/null

if which ip6tables &>/dev/null; then
    # ip6tables -F

    # 1) 清理 IPv6 mangle 表中的 V2RAY6_UDP（PREROUTING 挂钩）
    while ip6tables -t mangle -C PREROUTING -j V2RAY6_UDP 2>/dev/null; do
        ip6tables -t mangle -D PREROUTING -j V2RAY6_UDP
        sleep $sleep
    done
    ip6tables -t mangle -F V2RAY6_UDP 2>/dev/null
    ip6tables -t mangle -X V2RAY6_UDP 2>/dev/null

    # 2) 清理 IPv6 mangle 表中的 V2RAY6_MASK（OUTPUT 挂钩）
    while ip6tables -t mangle -C OUTPUT -j V2RAY6_MASK 2>/dev/null; do
        ip6tables -t mangle -D OUTPUT -j V2RAY6_MASK
        sleep $sleep
    done
    ip6tables -t mangle -F V2RAY6_MASK 2>/dev/null
    ip6tables -t mangle -X V2RAY6_MASK 2>/dev/null

    ip -6 route del local ::/0 dev lo table 100 2>/dev/null
    ip -6 rule del fwmark 1 table 100 2>/dev/null
fi

echo '[0m[1;32m done.[0m'
