#!/bin/sh

ROOT=${0%/*}

export v2ray_config=$ROOT/${1-config.json}
etc_folder=$ROOT/../router/opt/etc

echo "Use config $(readlink $v2ray_config)"

echo '------------------------------'

trap clean_up INT TERM ERR EXIT

clean_up() {
    trap - INT TERM ERR EXIT
    $etc_folder/clean_iptables_rule.sh
}

$etc_folder/apply_iptables_rule.sh
sudo $ROOT/linux-amd64/xray run -c $v2ray_config
