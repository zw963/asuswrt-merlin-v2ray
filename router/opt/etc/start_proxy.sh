#!/bin/sh

trap clean_up INT TERM ERR EXIT

clean_up() {
    trap - INT TERM ERR EXIT
    ./clean_iptables_rule.sh
}

./apply_iptables_rule.sh
sudo ./xray run -c v2ray.json
