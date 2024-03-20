#!/bin/sh

ROOT=${0%/*}

config=$ROOT/${1-config.json}

echo "Use config $(readlink $config)"

echo '------------------------------'

trap clean_up INT TERM ERR EXIT

clean_up() {
    trap - INT TERM ERR EXIT
    $ROOT/linux-amd64/clean_iptables_rule.sh
}

$ROOT/linux-amd64/apply_iptables_rule.sh
sudo $ROOT/linux-amd64/xray run -c $config
