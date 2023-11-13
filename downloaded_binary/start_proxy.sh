#!/bin/sh

ROOT=${0%/*}

trap clean_up INT TERM ERR EXIT

clean_up() {
    trap - INT TERM ERR EXIT
    $ROOT/amd64/clean_iptables_rule.sh
}

$ROOT/amd64/apply_iptables_rule.sh
sudo $ROOT/amd64/xray run -c $ROOT/v2ray.json