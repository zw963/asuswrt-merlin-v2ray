#!/bin/sh

echo '[0m[33mCleaning iptables rule ...[0m'

# clean old version rule, maybe delete later.
while iptables -t nat -C PREROUTING -p tcp -j V2RAY_TCP 2>/dev/null; do
    iptables -t nat -D PREROUTING -p tcp -j V2RAY_TCP
    iptables -t nat -D OUTPUT -p tcp -j V2RAY_TCP
done
iptables -t nat -F V2RAY_TCP 2>/dev/null          # flush
iptables -t nat -X V2RAY_TCP 2>/dev/null          # --delete-chain

while iptables -t mangle -C PREROUTING -j V2RAY_UDP 2>/dev/null; do
    iptables -t mangle -D PREROUTING -j V2RAY_UDP
done
iptables -t mangle -F V2RAY_UDP 2>/dev/null          # flush
iptables -t mangle -X V2RAY_UDP 2>/dev/null          # --delete-chain

while iptables -t mangle -C PREROUTING -j V2RAY_MARK 2>/dev/null; do
    iptables -t mangle -D PREROUTING -j V2RAY_MARK
done
iptables -t mangle -F V2RAY_MARK 2>/dev/null          # flush
iptables -t mangle -X V2RAY_MARK 2>/dev/null          # --delete-chain

ip route del local default dev lo table 100 2>/dev/null
ip rule del fwmark 1 table 100 2>/dev/null

echo '[0m[33mDone clean iptables rule.[0m'
