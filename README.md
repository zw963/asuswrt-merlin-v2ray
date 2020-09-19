# Use Asuswrt Merlin as a transparent proxy, powered by V2ray

## Intro

This project is for config you asus router (merlin based) to serve as a transparent forward proxy.

Since 2020-09-19, this project's release version just follow v2ray's version.

## Feature
1. Auto deploy V2ray to a linux VPS, serve as a Shadowsocks server and V2ray server.
   Test on CentOS 7.7, Ubuntu 18.0.4, Debian GNU/linux 9.
2. Auto generate V2ray client config, can be used both on router(transparent proxy) or local.
2. Auto deploy client config to router, serve as a transparent proxy.
3. Ad block.
4. All additional benefits come from V2ray.

## Prerequisites

- A VPS which can access free internet
- A router which support opkg package manager. (i use Merlin, I think OpenWRT can satisfied too after some hack)
- A local ssh client which can login to router.
- A not too older router, which can run V2ray comfortable.

If VPS behind a firewall, (e.g. ucloud, google cloud), you need enable 22334/22335 tcp/udp port manually.

## Optional

- Always update your's VPS linux kernel to newer version (>= 4.9) to make script can enable BBR for you.
- Make you VPS root@your.ip use ssh key and can ssh in without password.

## How to use

Please finish server prerequisites steps before do this if you are not a working
v2ray server is running.

Then, download the newest deploy script from [release page](https://github.com/zw963/asuswrt-merlin-v2ray/releases)

Assume your's linux VPS IP is `34.80.108.8`, your's router IP is `192.168.50.1`.

1) deploy server script to your's remote VPS.

```sh
$: ./deploy_v2ray+ss_to_vps root@34.80.108.8, wait run successful.
```


2) deploy router script to your's local ASUS router.

```sh
./deploy_v2ray_to_router admin@192.168.50.1, wait run successful.
```

A success deploy on router looking like this.

```sh
╰─ $ ./deploy_v2ray_to_router admin@192.168.50.1
v2ray.json                                  100% 7749     1.3MB/s   00:00
apply_iptables_rule.sh                      100% 1940   271.7KB/s   00:00
clean_iptables_rule.sh                      100% 1072   146.1KB/s   00:00
toggle_proxy.sh                             100% 1680   236.7KB/s   00:00
enable_swap.sh                              100%  482    95.6KB/s   00:00
patch_router                                100%  214    34.0KB/s   00:00
restart_dnsmasq.sh                          100%   84    11.2KB/s   00:00
update_geosite.sh                           100%  599    78.4KB/s   00:00
Copy predownloaded binary to router ...
v2ray-linux-arm32-v5.zip                    100%   11MB   7.0MB/s   00:01
***********************************************************
Remote deploy scripts is started !!
***********************************************************
opkg version dcbc142e51f5f5f2fb9e4e44657e013d3c36a52b (2019-06-14)
Archive:  v2ray-linux-arm32-v5.zip
  inflating: config.json
   creating: doc/
  inflating: doc/readme.md
  inflating: geoip.dat
  inflating: geosite.dat
   creating: systemd/
  inflating: systemd/v2ray.service
   creating: systemv/
  inflating: systemv/v2ray
  inflating: v2ctl
  inflating: v2ctl.sig
  inflating: v2ray
  inflating: v2ray.sig
  inflating: vpoint_socks_vmess.json
  inflating: vpoint_vmess_freedom.json
V2Ray 4.27.0 (V2Fly, a community-driven edition of V2Ray.) Custom (go1.14.6 linux/arm)
A unified platform for anti-censorship.
v2ray is installed
 Checking v2ray...              dead.
 Starting v2ray...              done.
 Shutting down v2ray...              done.
 Starting v2ray...              done.
Enabling proxy ...
Applying iptables rule ...
Done apply iptables rule.
 Starting v2ray...              already running.
dnsmasq: syntax check OK.
Proxy is enabled.
Congratulations, Deploy succssful!
```

Done.

## Contributing

  * [Bug reports](https://github.com/zw963/asuswrt-merlin-v2ray/issues)
  * Patches:
    * Fork on Github.
    * Create your feature branch: `git checkout -b my-new-feature`.
    * Commit your changes: `git commit -am 'Add some feature'`.
    * Push to the branch: `git push origin my-new-feature`.
    * Send a pull request :D.
