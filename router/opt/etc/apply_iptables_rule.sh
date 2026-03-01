#!/bin/sh

[ "$(id -u)" -ne 0 ] && exec sudo -E "$0" "$@"

# 如果规则已经存在则不重复添加（IPv4 & IPv6 都检测一下）
if iptables -t mangle -C PREROUTING -j V2RAY_UDP 2>/dev/null; then
    echo 'Skipping because this script was ran.'
    exit 0
fi

ROOT=${0%/*}/

if [ -t 1 ]; then
    if [ -e /opt/etc/clean_iptables_rule.sh ]; then
        /opt/etc/clean_iptables_rule.sh
    else
        $ROOT/clean_iptables_rule.sh
    fi
else
    echo -n 'Sleep 10 seconds for waiting sync system time'
    sleep 10
fi

echo -n 'Applying iptables rule ...'

if ! opkg --version &>/dev/null; then
    # 旁路由
    use_asuswrt=false
    sleep=0.2
else
    # 路由器
    use_asuswrt=true
    sleep=1
fi

if [ -n "$v2ray_config" ]; then
    config_file=$v2ray_config
elif [ -e /opt/etc/config.json ]; then
    config_file=/opt/etc/config.json
else
    config_file=./config.json
fi

local_v2ray_port=$(cat $config_file |grep '"inbounds"' -A10 |grep '"protocol" *: *"dokodemo-door"' -A10 |grep -o '"port": [0-9]*,' |grep -o '[0-9]*')

if [ -z "$local_v2ray_port" ]; then
    echo "can not find out v2ray port setting in $config_file"
    exit
fi

v2ray_server_ip=$(cat $config_file |grep 'protocol":\s*"\(vmess\|vless\)' -A10 |grep -o '"address": ".*",'|cut -d: '-f2'|cut -d'"' -f2)

if [ -z "$v2ray_server_ip" ]; then
    echo "can not find out remote VPS ip/domain in $config_file"
    exit
fi

function apply_tproxy_rule () {
    echo -n ' Applying TProxy rule ...'

    # 确保 fwmark 1 的路由表（IPv4 / IPv6）存在，幂等
    # local 是一个路由类型，指将网络包发给系统本地协议栈。
    ip rule add fwmark 1 table 100 2>/dev/null || true
    ip route add local 0.0.0.0/0 dev lo table 100 2>/dev/null || true

    # 由于使用了mangle表，所以数据包的原始和目的地址都是不会被修改的。
    # 定义了一个叫做 V2RAY_UDP 的 empty chain.
    iptables -t mangle -N V2RAY_UDP

    # step 1: 所有针对本地地址直连
    iptables -t mangle -A V2RAY_UDP -d 0.0.0.0/8 -j RETURN
    iptables -t mangle -A V2RAY_UDP -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A V2RAY_UDP -d 169.254.0.0/16 -j RETURN
    iptables -t mangle -A V2RAY_UDP -d 224.0.0.0/4 -j RETURN
    iptables -t mangle -A V2RAY_UDP -d 240.0.0.0/4 -j RETURN
    iptables -t mangle -A V2RAY_UDP -d 255.255.255.255 -j RETURN

    # 视情况（可能会影响极少数“特殊网络”）
    iptables -t mangle -A V2RAY_UDP -d 100.64.0.0/10 -j RETURN

    # step 2: 局域网地址，TCP 总是直连，UDP 只有 53 端口走代理
    iptables -t mangle -A V2RAY_UDP -d 10.0.0.0/8 -p tcp ! --dport 53 -j RETURN
    iptables -t mangle -A V2RAY_UDP -d 10.0.0.0/8 -p udp ! --dport 53 -j RETURN

    # iptables -t mangle -A V2RAY_UDP -d 172.0.0.0/8 -j RETURN # 这个似乎被 docker 内部使用, 使用容器必须
    iptables -t mangle -A V2RAY_UDP -d 172.16.0.0/12 -p tcp ! --dport 53 -j RETURN
    iptables -t mangle -A V2RAY_UDP -d 172.16.0.0/12 -p udp ! --dport 53 -j RETURN

    # 但是针对局域网地址，tcp 总是流量直连，局域网内目标地址是 53 的 udp 流量，则继续走代理。
    iptables -t mangle -A V2RAY_UDP -d 192.168.0.0/16 -p tcp ! --dport 53 -j RETURN
    iptables -t mangle -A V2RAY_UDP -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN

    # 远程 VPS 地址直连
    iptables -t mangle -A V2RAY_UDP -d $v2ray_server_ip -j RETURN

    # 从 V2Ray 发出的流量，再次经过时 netfilter 时，如果是 V2Ray 标记过为 255 的流量，全部走直连.
    iptables -t mangle -A V2RAY_UDP -m mark --mark 0xff -j RETURN

    # step 3: 这个不会解释，反正知道和上面的 ip rule/route 一起，可以针对 tcp/udp 实现类似于 redirect 的功能。
    # 同时需要在 V2Ray 的入站的地方加
    # "streamSettings": {
    #     "sockopt": {
    #         "tproxy": "tproxy"
    #     }
    # }
    # 来确保 V2Ray 可以识别这种流量。

    #  TPROXY 把匹配的 TCP/UDP 包转发到本机 dokodemo-door 端口
    # More details, see https://www.kernel.org/doc/Documentation/networking/tproxy.txt

    # 下面两行代码，将使用 --tproxy-mark 1 标记过的 udp/tcp 数据包路由到本机回环接口
    # 间接实现了类似于 redirect 的功能，而且同时对 tcp/udp 生效.
    iptables -t mangle -A V2RAY_UDP -p udp -j TPROXY --on-ip 127.0.0.1 --on-port $local_v2ray_port --tproxy-mark 1
    # 之前手贱, 这里加了一个 ! --dport 22, 等于 22 端口不设 tproxy mark, 造成 22 一定翻墙, 引起很多问题.
    iptables -t mangle -A V2RAY_UDP -p tcp -j TPROXY --on-ip 127.0.0.1 --on-port $local_v2ray_port --tproxy-mark 1

    # 将 V2RAY_UDP 这个 rule-chain, 附加到 PREROUTING 这个网关的 `mangle 占位符' 的最后面.
    iptables -t mangle -A PREROUTING -j V2RAY_UDP
}

function apply_gateway_rule () {
    # 这个 rule 仅仅在 tproxy 模式下需要, 否则，在路由器中无法访问外网.
    echo -n ' Apply gateway rule ...'

    iptables -t mangle -N V2RAY_MASK # 代理网关本机

    iptables -t mangle -A V2RAY_MASK -d 0.0.0.0/8 -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 169.254.0.0/16 -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 224.0.0.0/4 -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 240.0.0.0/4 -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 255.255.255.255 -j RETURN

    # 视情况（可能会影响极少数“特殊网络”）
    iptables -t mangle -A V2RAY_MASK -d 100.64.0.0/10 -j RETURN

    iptables -t mangle -A V2RAY_MASK -d 10.0.0.0/8 -p tcp ! --dport 53 -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 10.0.0.0/8 -p udp ! --dport 53 -j RETURN

    iptables -t mangle -A V2RAY_MASK -d 172.16.0.0/12 -p tcp ! --dport 53 -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 172.16.0.0/12 -p udp ! --dport 53 -j RETURN

    # 这里不要瞎改成和上面 tproxy 一样，否则，（可能是因为 53 端口走代理），会造成旁路由重启后不会同步时间。
    # 但是只有让 UDP 53 走代理，才能避免来自网通路由器的 DNS 污染，只能先开启吧。
    # 如果是旁路由，记得替换下面两行为：iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -j RETURN
    # 来确保时间同步服务可以正常工作。
    iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -p tcp ! --dport 53 -j RETURN
    iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN

    iptables -t mangle -A V2RAY_MASK -d $v2ray_server_ip -j RETURN

    # 避免影响时间同步服务
    iptables -t mangle -A V2RAY_MASK -p udp --dport 123 -j RETURN
    iptables -t mangle -A V2RAY_MASK -p udp --dport 323 -j RETURN

    # cloudflared 常用出站：7844（Argo Tunnel）；先直连放行
    iptables -t mangle -A V2RAY_MASK -p tcp --dport 7844 -j RETURN
    iptables -t mangle -A V2RAY_MASK -p udp --dport 7844 -j RETURN

    # 直连 SO_MARK 为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面V2Ray 配置的 255)，此规则目的是避免代理本机(网关)流量出现回环问题
    iptables -t mangle -A V2RAY_MASK -m mark --mark 0xff -j RETURN

    # 在 OUTPUT 链打标记会使相应的包重路由到 PREROUTING 链上，
    # 在已经配置好了 PREROUTING 相关的透明代理的情况下，OUTPUT 链也可以透明代理了，
    iptables -t mangle -A V2RAY_MASK -p udp -j MARK --set-mark 1   # 给 UDP 打标记,重路由
    iptables -t mangle -A V2RAY_MASK -p tcp -j MARK --set-mark 1   # 给 TCP 打标记，重路由

    iptables -t mangle -A OUTPUT -j V2RAY_MASK # 应用规则
}

if command -v python3 &>/dev/null;then
    get_lan6_prefix64() {
        dev="${1:-$(ip -6 route show default | sed -n 's/.* dev \([^ ]*\).*/\1/p' | head -n1)}"
        [ -n "$dev" ] || return 1

        ip -6 addr show dev "$dev" scope global 2>/dev/null \
            | awk '/inet6/ && $2 !~ /temporary/ {print $2; exit}' \
            | python3 - <<'PY'
import sys, ipaddress
s=sys.stdin.read().strip()
if not s:
    sys.exit(1)
ip = ipaddress.IPv6Interface(s)
net = ipaddress.IPv6Network((int(ip.ip) & ((1<<128)- (1<<64)), 64))
print(str(net))
PY
    }
    LAN6_PREFIX="$(get_lan6_prefix64 "$@" || true)"
fi

function apply_tproxy_rule_v6 () {
    echo -n ' Applying IPv6 TProxy rule ...'

    ip -6 rule add fwmark 1 table 100 2>/dev/null || true
    ip -6 route add local ::/0 dev lo table 100 2>/dev/null || true

    ip6tables -t mangle -N V2RAY6_UDP 2>/dev/null

    # 本地 / 链路本地 / ULA 直连
    ip6tables -t mangle -A V2RAY6_UDP -d ::1/128  -j RETURN
    ip6tables -t mangle -A V2RAY6_UDP -d fe80::/10 -j RETURN
    ip6tables -t mangle -A V2RAY6_UDP -d fc00::/7 -j RETURN

    # 这里的 "${LAN6_PREFIX:-}" 用法很有趣，确保这个变量即使没定义(python 没检测到
    #变量也存在，但是一个空字符串)，因此 -n 判断失败，但是 set -u 不会失败。
    [ -n "${LAN6_PREFIX:-}" ] && ip6tables -t mangle -A V2RAY6_UDP  -d "$LAN6_PREFIX" -j RETURN

    # 已被 xray 标记过的流量直连
    ip6tables -t mangle -A V2RAY6_UDP -m mark --mark 0xff -j RETURN

    # 把 TCP/UDP 流量 TPROXY 到本机 dokodemo-door 端口（::1）
    ip6tables -t mangle -A V2RAY6_UDP -p udp -j TPROXY --on-ip ::1 --on-port "$local_v2ray_port" --tproxy-mark 1
    ip6tables -t mangle -A V2RAY6_UDP -p tcp -j TPROXY --on-ip ::1 --on-port "$local_v2ray_port" --tproxy-mark 1

    ip6tables -t mangle -A PREROUTING -j V2RAY6_UDP
}

function apply_gateway_rule_v6 () {
    echo -n ' Apply IPv6 gateway rule ...'

    ip6tables -t mangle -N V2RAY6_MASK 2>/dev/null || true

    ip6tables -t mangle -A V2RAY6_MASK -d ::1/128  -j RETURN
    ip6tables -t mangle -A V2RAY6_MASK -d fe80::/10 -j RETURN
    ip6tables -t mangle -A V2RAY6_MASK -d fc00::/7 -j RETURN
    [ -n "${LAN6_PREFIX:-}" ] && ip6tables -t mangle -A V2RAY6_MASK -d "$LAN6_PREFIX" -j RETURN

    # cloudflared 常用出站：7844（Argo Tunnel）；先直连放行
    ip6tables -t mangle -A V2RAY6_MASK -p tcp --dport 7844 -j RETURN
    ip6tables -t mangle -A V2RAY6_MASK -p udp --dport 7844 -j RETURN

    # 已被 xray 标记过的流量直连
    ip6tables -t mangle -A V2RAY6_MASK -m mark --mark 0xff -j RETURN

    # 给 IPv6 出站流量打标记，重路由到 TPROXY
    ip6tables -t mangle -A V2RAY6_MASK -p udp -j MARK --set-mark 1
    ip6tables -t mangle -A V2RAY6_MASK -p tcp -j MARK --set-mark 1

    ip6tables -t mangle -A OUTPUT -j V2RAY6_MASK
}


function apply_DNS_redirect () {
    # 这个之前只是在 tproxy 模式下，不懂怎么用的时候，监听在 53 或 65053 端口用。
    echo -n 'Redirect all DNS request to localhost port 65053'

    iptables -t nat -N V2RAY_DNS
    iptables -t nat -A V2RAY_DNS -d 192.168.0.0/16 -p udp --dport 53 -j REDIRECT --to-ports 65053

    iptables -t nat -A PREROUTING -p udp -j V2RAY_DNS # 这个让外部设备阻止 DNS 污染生效
}

function apply_socket_rule () {
    # 新建 DIVERT 规则，避免已有连接的包二次通过 TPROXY，理论上有一定的性能提升
    iptables -t mangle -N DIVERT
    iptables -t mangle -A DIVERT -j MARK --set-mark 1
    iptables -t mangle -A DIVERT -j ACCEPT
    iptables -t mangle -I PREROUTING -p tcp -m socket -j DIVERT
}

if modprobe xt_TPROXY &>/dev/null; then
    apply_tproxy_rule
    # 下面的 rule 使得路由器内访问 google 可以工作。
    # 似乎在 fakedns 模式下不工作。
    apply_gateway_rule

    # 这些 rule 只是导入 IP v6 到 xray，但是仍需要 VPS 服务器支持  ipv6,
    # 才能正确的暴露 VPS 的 IP V6 地址到外部。
    if which ip6tables &>/dev/null; then
        # ip6tables -I OUTPUT -m addrtype ! --dst-type LOCAL -j DROP
        apply_tproxy_rule_v6
        apply_gateway_rule_v6
    fi

    # apply_socket_rule


    # if [ "$use_asuswrt" == true ]; then
    #     apply_DNS_redirect
    # fi
else
    echo 'Not support tproxy, exit ...'
fi

echo '[0m[1;32m done.[0m'
