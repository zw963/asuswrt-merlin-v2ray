# Use Asuswrt Merlin as a transparent proxy, powered by V2ray

## Intro

This project is several scripts for config you ASUS router(merlin based) to serve
as a transparent forward proxy.

Since 2020-09-19, this project's release version just follow v2ray's version.

## Feature

1. transparent proxy(you know reason) for all devices connect to your's WiFi.
2. use your router 1080 port (e.g. router.asus.com:1080) as a socks5/http proxy directly.
3. Ad block.
4. All additional benefits come from [V2ray](https://github.com/v2fly).

## Prerequisites

- A VPS which can visit free internet.
- A newer router which support [Entware](https://github.com/Entware/Entware), and can run V2ray comfortable.
  (i use ASUS RT-AC5300, I think OpenWRT should satisfied too after a little hack)
- A local ssh client which can login to router use ssh key.
- If VPS behind a firewall, (e.g. UCloud, Google Cloud), you need enable 22334/22335
tcp/udp port on server manually.

For better performance, update your's VPS linux kernel to a more recently version
(>= 4.9) is encouraged, script can enable BBR for you on this case.

## How to use it

Download this script from [release page](https://github.com/zw963/asuswrt-merlin-v2ray/releases)

We assume your's linux VPS IP is `34.80.108.8`, your's router IP is `192.168.50.1`.

### Deploy V2ray to one linux VPS, serve as both V2ray and Shadowsoks server.
Test on CentOS 7.7, Ubuntu 18.0.4, Debian GNU/linux 9.

A success deploy on VPS should be looking like this on CentOS 7.

```sh
╰─ $ ./deploy_v2ray+ss_to_vps root@34.80.108.8
sending incremental file list
server.json
          1.60K 100%  226.56kB/s    0:00:00 (xfr#1, to-chk=0/1)

sent 342 bytes  received 53 bytes  158.00 bytes/sec
total size is 1.60K  speedup is 4.06
***********************************************************
Remote deploy scripts is started !!
***********************************************************
Last metadata expiration check: 2:43:19 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package mlocate-0.26-20.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:20 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package git-2.18.4-2.el8_2.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:21 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package tree-1.7.0-15.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:22 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package yum-utils-4.0.12-4.el8_2.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:23 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package epel-release-8-8.el8.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:24 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package gcc-8.3.1-5.el8.0.2.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:25 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package autoconf-2.69-27.el8.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:26 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package automake-1.16.1-6.el8.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:27 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package make-1:4.2.1-10.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:28 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package libtool-2.4.6-25.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:29 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package bzip2-1.0.6-26.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:30 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package unzip-6.0-43.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:31 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package patch-2.7.6-11.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:31 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package wget-1.19.5-8.el8_1.1.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:32 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package curl-7.61.1-12.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:33 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package perl-4:5.26.3-416.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:34 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package gcc-c++-8.3.1-5.el8.0.2.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:35 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package xz-5.2.4-3.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 2:43:36 ago on Tue 03 Nov 2020 12:17:18 PM HKT.
Package pkgconf-pkg-config-1.4.2-1.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Archive:  /tmp/1813531744/v2ray-linux-64.zip
  inflating: /tmp/1813531744/config.json
  inflating: /tmp/1813531744/geoip.dat
  inflating: /tmp/1813531744/geosite.dat
   creating: /tmp/1813531744/systemd/
   creating: /tmp/1813531744/systemd/system/
  inflating: /tmp/1813531744/systemd/system/v2ray.service
  inflating: /tmp/1813531744/systemd/system/v2ray@.service
  inflating: /tmp/1813531744/v2ctl
  inflating: /tmp/1813531744/v2ray
  inflating: /tmp/1813531744/vpoint_socks_vmess.json
  inflating: /tmp/1813531744/vpoint_vmess_freedom.json
rm: cannot remove '*.sig': No such file or directory
V2Ray 4.32.0 (V2Fly, a community-driven edition of V2Ray.) Custom (go1.15.3 linux/amd64)
A unified platform for anti-censorship.
cp: cannot stat 'systemd/v2ray.service': No such file or directory
`NEWUUID' is replace with `d26a6447-1113-49d0-8962-1ff18d529b36'
tcp_bbr                20480  14
net.ipv4.tcp_available_congestion_control = reno cubic bbr
bbr
● v2ray.service - V2Ray Service
   Loaded: loaded (/etc/systemd/system/v2ray.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-11-03 15:00:58 HKT; 23ms ago
     Docs: https://www.v2ray.com/
           https://www.v2fly.org/
 Main PID: 39368 (v2ray)
    Tasks: 3 (limit: 12006)
   Memory: 6.6M
   CGroup: /system.slice/v2ray.service
           └─39368 /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json

Nov 03 15:00:58 10-8-2-238 systemd[1]: Started V2Ray Service.
Nov 03 15:00:59 10-8-2-238 v2ray[39368]: V2Ray 4.32.0 (V2Fly, a community-driven edition of V2Ray.) Custom (go1.15.3 linux/amd64)
Nov 03 15:00:59 10-8-2-238 v2ray[39368]: A unified platform for anti-censorship.
success
Warning: ALREADY_ENABLED: 22334:tcp
success
Warning: ALREADY_ENABLED: 22334:udp
success
success
Warning: ALREADY_ENABLED: 22335:tcp
success
Warning: ALREADY_ENABLED: 22335:udp
success
Your's shadowsocks port: 22335
Your's shadowsocks encrypt method: chacha20-ietf-poly1305
Your's shadowsocks password: my_password
Congratulations, Deploy succssful!

Please wait copy generated client v2ray.json into local machine ...
v2ray.json                                                                                                                  100% 9051    86.4KB/s   00:00
Run ./deploy_v2ray_to_router admin@192.168.50.1 to deploy to router.
```

### Deploy client config to router, serve as a transparent proxy.

Previous step will create a new v2ray client config for you in `router/opt/etc/v2ray.json`.

Run following script will deploy this script alone with V2ray to your's local ASUS
router automatically.


```sh
./deploy_v2ray_to_router admin@192.168.50.1
```

A success deploy on router should be looking like this.

```sh
╰─ $ ./deploy_v2ray_to_router admin@192.168.50.1
v2ray.json                                                                                                                  100% 9051   803.2KB/s   00:00
apply_iptables_rule.sh                                                                                                      100% 1940   295.9KB/s   00:00
clean_iptables_rule.sh                                                                                                      100% 1072   129.9KB/s   00:00
toggle_proxy.sh                                                                                                             100% 1680   185.4KB/s   00:00
enable_swap.sh                                                                                                              100%  482    94.7KB/s   00:00
patch_router                                                                                                                100%  214    29.2KB/s   00:00
restart_dnsmasq.sh                                                                                                          100%   84    11.0KB/s   00:00
update_geosite.sh                                                                                                           100%  599    70.5KB/s   00:00
Copy predownloaded binary to router ...
v2ray-linux-arm32-v5-4.32.0.zip                                                                                             100%   11MB   3.7MB/s   00:02
***********************************************************
Remote deploy scripts is started !!
***********************************************************
opkg version dcbc142e51f5f5f2fb9e4e44657e013d3c36a52b (2019-06-14)
Archive:  v2ray-linux-arm32-v5-4.32.0.zip
  inflating: config.json
  inflating: geoip.dat
  inflating: geosite.dat
   creating: systemd/
   creating: systemd/system/
  inflating: systemd/system/v2ray.service
  inflating: systemd/system/v2ray@.service
  inflating: v2ctl
  inflating: v2ray
  inflating: vpoint_socks_vmess.json
  inflating: vpoint_vmess_freedom.json
V2Ray 4.32.0 (V2Fly, a community-driven edition of V2Ray.) Custom (go1.15.3 linux/arm)
A unified platform for anti-censorship.
v2ray is installed
 Checking v2ray...              alive.
 Shutting down v2ray...              done.
 Starting v2ray...              done.
 Starting v2ray...              done.
Enabling proxy ...
 Starting v2ray...              already running.
dnsmasq: syntax check OK.
Proxy is enabled.
Congratulations, Deploy succssful!
```

## Contributing

  * [Bug reports](https://github.com/zw963/asuswrt-merlin-v2ray/issues)
  * Patches:
    * Fork on Github.
    * Create your feature branch: `git checkout -b my-new-feature`.
    * Commit your changes: `git commit -am 'Add some feature'`.
    * Push to the branch: `git push origin my-new-feature`.
    * Send a pull request :D.
