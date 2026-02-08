#!/usr/bin/env bash
set -u

ROOT=${0%/*}

export v2ray_config="$ROOT/${1:-config.json}"
etc_folder="$ROOT/../router/opt/etc"

echo "Use config: $(readlink -f "$v2ray_config" 2>/dev/null || echo "$v2ray_config")"
echo '------------------------------'

toggle_proxy () {
    if sudo iptables -t mangle -C PREROUTING -j V2RAY_UDP >/dev/null 2>&1; then
        "$etc_folder/clean_iptables_rule.sh" || true
        echo "[toggle] cleaned"
    else
        "$etc_folder/apply_iptables_rule.sh" || true
        echo "[toggle] applied"
    fi
}

clean_up () {
    trap - INT TERM EXIT
    "$etc_folder/clean_iptables_rule.sh" || true
    echo "[cleanup] done"
}

trap clean_up INT TERM EXIT

# 用 fd 3 绑定控制终端读按键（关键）
exec 3</dev/tty
old_tty="$(stty -g <&3)"
stty quit undef <&3
trap 'stty "$old_tty" <&3; exec 3<&- ' EXIT

# 启动时默认开启 iptables
"$etc_folder/apply_iptables_rule.sh" || true
echo "[init] iptables applied"

# 启动 xray（日志仍在 Konsole）
sudo $ROOT/linux-amd64/xray run -c "$v2ray_config" </dev/null &
xray_pid=$!

echo "Press Ctrl+\\ to toggle iptables. Ctrl+C to exit."

while kill -0 "$xray_pid" 2>/dev/null; do
    IFS= read -rsn1 -t 0.2 k <&3 || true
    [[ "${k:-}" == $'\034' ]] && toggle_proxy
done

wait "$xray_pid"
