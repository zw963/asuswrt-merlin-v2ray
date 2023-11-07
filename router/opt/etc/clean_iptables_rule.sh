#!/bin/sh

echo -n 'Cleaning iptables rule ...'

ipset_protocal_version=$(ipset -v 2>/dev/null |grep -o 'version.*[0-9]' |head -n1 |cut -d' ' -f2)

if [ "${ipset_protocal_version:-7}" -gt 6 ]; then
    alias iptables='sudo /usr/sbin/iptables'
    alias ip='sudo ip'
else
    alias iptables='/opt/sbin/iptables'
fi

# clean old version rule, maybe delete later.
while iptables -t nat -C PREROUTING -p tcp -j V2RAY_TCP 2>/dev/null; do
    iptables -t nat -D PREROUTING -p tcp -j V2RAY_TCP
    iptables -t nat -D OUTPUT -p tcp -j V2RAY_TCP
    sleep 0.2
done
iptables -t nat -F V2RAY_TCP 2>/dev/null          # flush
iptables -t nat -X V2RAY_TCP 2>/dev/null          # --delete-chain

while iptables -t mangle -C PREROUTING -j V2RAY_UDP 2>/dev/null; do
    iptables -t mangle -D PREROUTING -j V2RAY_UDP
    sleep 0.2
done
iptables -t mangle -F V2RAY_UDP 2>/dev/null          # flush
iptables -t mangle -X V2RAY_UDP 2>/dev/null          # --delete-chain

while iptables -t mangle -C OUTPUT -j V2RAY_MASK 2>/dev/null; do
    iptables -t mangle -D OUTPUT -j V2RAY_MASK
    sleep 0.2
done
iptables -t mangle -F V2RAY_MASK 2>/dev/null          # flush
iptables -t mangle -X V2RAY_MASK 2>/dev/null          # --delete-chain

while iptables -t mangle -C PREROUTING -p tcp -m socket -j DIVERT 2>/dev/null; do
    iptables -t mangle -D PREROUTING -p tcp -m socket -j DIVERT
    sleep 0.2
done
iptables -t mangle -F DIVERT 2>/dev/null          # flush
iptables -t mangle -X DIVERT 2>/dev/null          # --delete-chain

ip route del local default dev lo table 100 2>/dev/null
ip rule del fwmark 1 table 100 2>/dev/null

echo '[0m[1;32m done.[0m'
