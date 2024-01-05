## NOTICE:

The maintainer using `Xray` + `side router` solution daily.

Other solution will not be updated in time may not work at all.

# Use Asuswrt Merlin as a transparent proxy, powered by V2ray

## Intro

This project is several scripts for config you ASUS router(merlin based) or 
Side router(A very old linux laptop) to serve as a transparent forward proxy.

Since 2023-07-16, this project's release version just follow [Xray-core](https://github.com/XTLS/Xray-core)'s version.

## Feature

1. transparent proxy(you know reason) for all devices connect to your's LAN.
2. use your router 1080 port (e.g. router.asus.com:1080) as a socks5/http proxy directly.
3. Ad block.
4. All additional benefits come from V2Ray.
5. Xray + XTLS support.

For transparent proxy, current three mode is supported, will select automatically depend on your's router device.

1. tproxy mode will be used if routers support TProxy.
2. redirect mode will be used if router not support TProxy.
3. fakedns mode based on tproxy mode, it can only switch on manually.

*NOTICE*

redirect mode require dnsmasq serve as LAN DNS server, if you asuswrt merlin, this is default mode.
others mode V2Ray and basically build tools(For use with QUIC) is the only dependency.

You can always check weather router support TProxy:

```sh
# modprobe xt_TPROXY
```

## Switch proxy mode

You can switch modes after deploy successful.

### Switch to use old redirect transparent proxy (need dnsmasq)

```sh
$: ./deploy_router_use_direct admin@192.168.50.1
```

### Switch to use fakedns based transparent proxy (need TProxy support)

```sh
$: ./use_fakedns admin@192.168.50.1
```

### Switch to auto mode (default)

```sh
$: ./use_auto_proxy admin@192.168.50.1
```

## Prerequisites

- A VPS which can visit free internet.
- A newer router which support [Entware](https://github.com/Entware/Entware), and can run V2ray comfortable.
  (i use ASUS RT-AC5300, I think OpenWRT should satisfied too after a little hack)
- Update yours router firmware to [Asuswrt-merlin](https://github.com/RMerl/asuswrt-merlin.ng)
- Initialize Entware, please follow this [wiki](https://github.com/RMerl/asuswrt-merlin.ng/wiki/Entware)
- A local ssh client which can login to router use ssh key.
- If VPS behind a firewall, (e.g. UCloud, Google Cloud), you need enable 22334/22335
tcp/udp port on server manually.
- A real domain name, if you want to use Xray + XTLS mode.

For better performance, update your's VPS linux kernel to a more recently version
(>= 4.9) is encouraged, script can enable BBR for you on this case.

## How to use it

Download script from [release page](https://github.com/zw963/asuswrt-merlin-v2ray/releases)

We assume your's linux VPS IP is `34.80.108.8`, your's router IP is `192.168.50.1`.

### Deploy XRay to a linux VPS, serve as both XRay and Shadowsoks server.

Test on CentOS 8, Ubuntu 18.0.4, Debian GNU/linux 9.

Following is the sample output for deploy Xray but keep exists config unchanged.

If you deploy XRay instead of V2Ray, you must replace `set_your_domain_name_here` 
into your's really domain name at first, and run `deploy_tls` to apply the https certificate
if you are not set it correctly, then run `deploy_server` script like following:

```sh
 ╰─ $ use_xtls=1 ./deploy_server root@$hk
sending incremental file list
xray_server.json
          2.31K 100%  914.06kB/s    0:00:00 (xfr#1, to-chk=0/1)

......

Run ./deploy_router admin@192.168.50.1 to deploy to router.
Run ./deploy_side_router root@side_router_ip to deploy to side_router.

```

### Deploy client config to router, serve as a transparent proxy.

Previous step will create a new v2ray client config for you in `router/opt/etc/v2ray.json`.

Run following command will deploy V2ray transparent proxy to your's local ASUS
router automatically.


```sh
./deploy_router admin@192.168.50.1
```

Run following command will deploy to a side router.(for me, it is a HP 2530p laptop + CentOS 8)

```sh
./deploy_side_router root@192.168.51.111
```


A success deploy on router should be looking like this.

![patch_router](/images/patch_router.png)

### deploy code to side router

![deploy_side_router](/images/deploy_side_router.png)

### Useful command for router

You can run following command on router

`/opt/etc/toggle_proxy.sh` is used for disable/enable proxy temporary, for disable completely, you need `chmod -x /opt/etc/patch_router`

`/opt/etc/patch_router` basically, just disable proxy, and then enable it.

`/opt/etc/update_geodata.sh` is used for update geosite data.

`/opt/etc/enable_swap.sh` is used for enable swap for insufficient RAM device.(if not use amtm enable it already.)

`/opt/etc/apply_iptables_rule.sh` `/opt/etc/clean_iptables_rule.sh` for enable/clean iptables rule.

`/opt/etc/restart_dnsmasq.sh` for restart dnsmasq. (for router which install dnsmasq only)

`/opt/etc/check_google_use_socks5` check v2ray if works in router. (not work for fakeDNS mode)

`/opt/etc/check_google_use_proxy` check v2ray transparent proxy if works in router. (not work for fakeDNS mode)

## troubleshooting step by step

1. ensure you can ping your's VPS from local, and can ssh login.
2. ensure you can visit it use telnet from yours VPS, e.g. for port 22334, `telnet 127.0.0.1 22334`
3. ensure you can visit it use telnet from local, e.g. `telnet {yours.ip} 22334`, 
   if not, check if port is blocked in yours area with: https://tcp.ping.pe/{your.ip}:22334
4. ensure your's domain name certificate not expired. (visit site if you have website, or see server xray log)
5. ensure domain name connect to your ip correct.
6. check config settings, especially, the `vless id`, `vless port`, `domain name` correct.
7. test with `./check_google_use_socks5.sh`, ensure it work before test transparent proxy.
8. check the current time in local/remote all correct.
9. Create a issue

## Contributing

  * [Bug reports](https://github.com/zw963/asuswrt-merlin-v2ray/issues)
  * Patches:
    * Fork on Github.
    * Create your feature branch: `git checkout -b my-new-feature`.
    * Commit your changes: `git commit -am 'Add some feature'`.
    * Push to the branch: `git push origin my-new-feature`.
    * Send a pull request :D.
