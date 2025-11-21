#!/bin/sh

ROOT=${0%/*}

config=$ROOT/${1-config.json}
etc_folder=$ROOT/../router/opt/etc

echo "Use config $(readlink $config)"

echo '------------------------------'

trap clean_up INT TERM ERR EXIT

clean_up() {
    trap - INT TERM ERR EXIT
    $etc_folder/clean_iptables_rule.sh
}

$etc_folder/apply_iptables_rule.sh
sudo $ROOT/linux-amd64/xray run -c $config
