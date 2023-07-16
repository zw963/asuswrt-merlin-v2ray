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

You can always check router if check TProxy use:

```sh
# modprobe xt_TPROXY
```

## Switch proxy mode

You can switch modes after deploy successful.

### Switch to use old redirect transparent proxy (need dnsmasq)

```sh
$: ./use_redirect_proxy admin@192.168.50.1
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

sent 372 bytes  received 59 bytes  287.33 bytes/sec
total size is 2.31K  speedup is 5.35
sending incremental file list
v2ray_server.json
          1.89K 100%  501.95kB/s    0:00:00 (xfr#1, to-chk=0/1)

sent 348 bytes  received 53 bytes  267.33 bytes/sec
total size is 1.89K  speedup is 4.70
sending incremental file list
xray.service
            449 100%    0.00kB/s    0:00:00 (xfr#1, to-chk=0/1)

sent 90 bytes  received 41 bytes  87.33 bytes/sec
total size is 449  speedup is 3.43
sending incremental file list
xray@.service
            445 100%    0.00kB/s    0:00:00 (xfr#1, to-chk=0/1)

sent 91 bytes  received 41 bytes  88.00 bytes/sec
total size is 445  speedup is 3.37
***********************************************************
Remote deploy scripts is started !!
***********************************************************
Warning: The unit file, source configuration file or drop-ins of xray.service changed on disk. Run 'systemctl daemon-reload' to reload units.
Archive:  /tmp/202722541/Xray-linux-64.zip
  inflating: /tmp/202722541/README.md  
  inflating: /tmp/202722541/LICENSE  
  inflating: /tmp/202722541/geoip.dat  
  inflating: /tmp/202722541/xray     
  inflating: /tmp/202722541/geosite.dat  
Archive:  /tmp/1530510623/v2ray-linux-64.zip
  inflating: /tmp/1530510623/geoip-only-cn-private.dat  
  inflating: /tmp/1530510623/vpoint_socks_vmess.json  
  inflating: /tmp/1530510623/v2ctl   
  inflating: /tmp/1530510623/geosite.dat  
  inflating: /tmp/1530510623/config.json  
  inflating: /tmp/1530510623/vpoint_vmess_freedom.json  
   creating: /tmp/1530510623/systemd/
   creating: /tmp/1530510623/systemd/system/
  inflating: /tmp/1530510623/systemd/system/v2ray@.service  
  inflating: /tmp/1530510623/systemd/system/v2ray.service  
  inflating: /tmp/1530510623/v2ray   
  inflating: /tmp/1530510623/geoip.dat  
`RestartPreventExitStatus=23' was replaced with `RestartPreventExitStatus=23
# Added by user
LimitNPROC=500
LimitNOFILE=1000000' globally for `/etc/systemd/system/v2ray.service'!
tcp_bbr                20480  31
net.ipv4.tcp_available_congestion_control = reno cubic bbr
bbr
`RestartPreventExitStatus=23' was replaced with `RestartPreventExitStatus=23
# Added by user
LimitNPROC=500
LimitNOFILE=1000000' globally for `/etc/systemd/system/v2ray@.service'!
`/usr/local/etc/v2ray/config.json' was replaced with `/etc/v2ray/config.json' globally for `/etc/systemd/system/v2ray.service'!
`/usr/local/etc/v2ray/%i.json' was replaced with `/etc/v2ray/%i.json' globally for `/etc/systemd/system/v2ray@.service'!
`NEWUUID' was replaced with `c8b7fd23-3e74-4300-b9fe-fe7f2a4e27df' globally for `/etc/xray/config.json'!
`NEWUUID' was replaced with `c8b7fd23-3e74-4300-b9fe-fe7f2a4e27df' globally for `/etc/v2ray/config.json'!
Last metadata expiration check: 1 day, 20:00:56 ago on Sat 18 Dec 2021 06:48:13 AM HKT.
Package mlocate-0.26-20.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 1 day, 20:00:59 ago on Sat 18 Dec 2021 06:48:13 AM HKT.
Package git-2.27.0-1.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 1 day, 20:01:01 ago on Sat 18 Dec 2021 06:48:13 AM HKT.
Package coreutils-8.30-12.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 1 day, 20:01:03 ago on Sat 18 Dec 2021 06:48:13 AM HKT.
Package yum-utils-4.0.21-3.el8.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 1 day, 20:01:05 ago on Sat 18 Dec 2021 06:48:13 AM HKT.
Package epel-release-8-13.el8.noarch is already installed.
Dependencies resolved.
Nothing to do.
Complete!
Last metadata expiration check: 1 day, 20:01:07 ago on Sat 18 Dec 2021 06:48:13 AM HKT.
Package socat-1.7.4.1-1.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  204k  100  204k    0     0  1357k      0 --:--:-- --:--:-- --:--:-- 1357k
[Mon Dec 20 02:49:22 HKT 2021] Installing from online archive.
[Mon Dec 20 02:49:22 HKT 2021] Downloading https://github.com/acmesh-official/acme.sh/archive/master.tar.gz
[Mon Dec 20 02:49:23 HKT 2021] Extracting master.tar.gz
[Mon Dec 20 02:49:24 HKT 2021] Installing to /root/.acme.sh
[Mon Dec 20 02:49:24 HKT 2021] Installed to /root/.acme.sh/acme.sh
[Mon Dec 20 02:49:24 HKT 2021] Installing alias to '/root/.bashrc'
[Mon Dec 20 02:49:24 HKT 2021] OK, Close and reopen your terminal to start using acme.sh
[Mon Dec 20 02:49:24 HKT 2021] Installing alias to '/root/.cshrc'
[Mon Dec 20 02:49:24 HKT 2021] Installing alias to '/root/.tcshrc'
[Mon Dec 20 02:49:24 HKT 2021] Installing cron job
13 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
[Mon Dec 20 02:49:24 HKT 2021] Good, bash is found, so change the shebang to use bash as preferred.
[Mon Dec 20 02:49:25 HKT 2021] OK
[Mon Dec 20 02:49:25 HKT 2021] Install success!
[Mon Dec 20 02:49:25 HKT 2021] Already uptodate!
[Mon Dec 20 02:49:25 HKT 2021] Upgrade success!
[Mon Dec 20 02:49:26 HKT 2021] Changed default CA to: https://acme-v02.api.letsencrypt.org/directory
0.0.0.0:80
[Mon Dec 20 02:49:26 HKT 2021] Installing key to: /etc/ssl/stocks.zw963.online/privkey.pem
[Mon Dec 20 02:49:26 HKT 2021] Installing full chain to: /etc/ssl/stocks.zw963.online/fullchain.pem
[Mon Dec 20 02:49:26 HKT 2021] Run reload cmd: systemctl restart xray; systemctl restart nginx;
[Mon Dec 20 02:49:26 HKT 2021] Reload success
Certificate install to `/etc/ssl/stocks.zw963.online/fullchain.pem', `/etc/ssl/stocks.zw963.online/privkey.pem'
● xray.service - Xray Service
   Loaded: loaded (/etc/systemd/system/xray.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-12-20 02:49:26 HKT; 45ms ago
     Docs: https://github.com/xtls
 Main PID: 1672774 (xray)
    Tasks: 3 (limit: 11971)
   Memory: 7.5M
   CGroup: /system.slice/xray.service
           └─1672774 /usr/local/bin/xray run -config /etc/xray/config.json

Dec 20 02:49:26 zw963.online systemd[1]: xray.service: Succeeded.
Dec 20 02:49:26 zw963.online systemd[1]: Stopped Xray Service.
Dec 20 02:49:26 zw963.online xray[1672774]: Xray 1.5.0 (Xray, Penetrates Everything.) Custom (go1.17.2 linux/amd64)
Dec 20 02:49:26 zw963.online xray[1672774]: A unified platform for anti-censorship.
Dec 20 02:49:26 zw963.online systemd[1]: Started Xray Service.
Dec 20 02:49:26 zw963.online xray[1672774]: 2021/12/20 02:49:26 [Info] infra/conf/serial: Reading config: /etc/xray/config.json
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
SELINUX=disabled
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
SELINUX=disabled
Congratulations, Deploy succssful!
Please check generated client config file at router/opt/etc/v2ray.json

Please wait copy generated client config into local machine ...
v2ray.json                                                                                                100% 9279   154.2KB/s   00:00    
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

![deploy_side_router](/images/deploy_side_router.jpg)

### Useful command for router

You can run following command on router

`/opt/etc/toggle_proxy.sh` is used for disable/enable proxy temporary, for disable completely, you need `chmod -x /opt/etc/patch_router`

`/opt/etc/patch_router` basically, just disable proxy, and then enable it.

`/opt/etc/update_geosite.sh` or `/opt/etc/update_big_geosite.sh` is used for update geosite data.

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
