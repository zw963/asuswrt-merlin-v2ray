#!/bin/sh

ROOT=${0%/*}

trap clean_up INT TERM ERR EXIT

clean_up() {
    trap - INT TERM ERR EXIT
    $ROOT/clean_iptables_rule.sh
}

$ROOT/apply_iptables_rule.sh
sudo $ROOT/xray run -c $ROOT/v2ray.json
