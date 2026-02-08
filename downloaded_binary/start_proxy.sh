#!/usr/bin/env bash
set -u

ROOT=${0%/*}

export v2ray_config="$ROOT/${1:-config.json}"
etc_folder="$ROOT/../router/opt/etc"

echo "Use config: $(readlink -f "$v2ray_config" 2>/dev/null || echo "$v2ray_config")"
echo '------------------------------'

trap clean_up INT TERM EXIT

# 用 fd 3 绑定控制终端读按键（关键）
exec 3</dev/tty
old_tty="$(stty -g <&3)"
stty quit undef <&3
trap 'stty "$old_tty" <&3; exec 3<&- ' EXIT

# 启动时默认开启 iptables
$etc_folder/apply_iptables_rule.sh
echo "[init] iptables applied"

# 启动 xray（日志仍在 Konsole）
sudo $ROOT/linux-amd64/xray run -c "$v2ray_config" </dev/null &
xray_pid=$!

echo "Press Ctrl+\\ to toggle iptables. Ctrl+C to exit."

toggle_proxy () {
    if sudo iptables -t mangle -C PREROUTING -j V2RAY_UDP >/dev/null 2>&1; then
        $etc_folder/clean_iptables_rule.sh || true
        echo "[toggle] cleaned"
    else
        $etc_folder/apply_iptables_rule.sh || true
        echo "[toggle] applied"
    fi
}

clean_up () {
    trap - INT TERM EXIT
    $etc_folder/clean_iptables_rule.sh || true
    echo "[cleanup] done"
}

while kill -0 "$xray_pid" 2>/dev/null; do
    # 等待用户从 fd 3 输入，如果 0.2 秒没有输入，则直接返回 true，循环继续。
    IFS= read -rsn1 -t 0.2 k <&3 || true
    # 八进制 034 = 十进制 28 = 十六进制 0x1C
    # ASCII 0x1C 是 FS（File Separator） 控制字符
    # 在终端常见映射里：Ctrl+\ 对应的字符就是 0x1C
    [[ "${k:-}" == $'\034' ]] && toggle_proxy
done

wait "$xray_pid"
