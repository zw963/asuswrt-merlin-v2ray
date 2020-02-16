# Use Asuswrt Merlin as a transparent proxy, powered by V2ray

## Intro

This project is for config you asus router (merlin based) to serve as a transparent forward proxy,

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

Please finish prerequisites steps before do this.

Assume your's linux VPS is 34.80.108.8, your's router is 192.168.50.1

1) ./deploy_v2ray+ss_to_vps root@34.80.108.8, wait run successful.

2) ./deploy_v2ray_to_router admin@192.168.50.1, wait run successful.

If you see following error issue, please run it again and again ..... again, until it successful.

![error_msg](/image.png)

Done.

## Contributing

  * [Bug reports](https://github.com/zw963/asuswrt-merlin-v2ray/issues)
  * Patches:
    * Fork on Github.
    * Create your feature branch: `git checkout -b my-new-feature`.
    * Commit your changes: `git commit -am 'Add some feature'`.
    * Push to the branch: `git push origin my-new-feature`.
    * Send a pull request :D.
