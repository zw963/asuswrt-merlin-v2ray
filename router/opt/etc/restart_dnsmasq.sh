#!/bin/sh

echo -n 'Restart dnsmasq ...'
dnsmasq --test 2>/dev/null && kill $(cat /var/run/dnsmasq.pid) && dnsmasq --log-async
echo '[0m[1;32m done.[0m'
