## AVISO:

El mantenedor utiliza la solución `Xray` + `side router` a diario.

Otras soluciones no se actualizarán a tiempo y es posible que no funcionen en absoluto.

# Usar Asuswrt Merlin como proxy transparente, con V2ray

## Introducción

Este proyecto contiene varios scripts para configurar tu router ASUS (basado en Merlin) o
un router secundario (un portátil Linux muy antiguo) para que funcione como proxy directo transparente.

Desde el 2023-07-16, la versión publicada de este proyecto sigue la versión de [Xray-core](https://github.com/XTLS/Xray-core).
Desde el 2024-01-07, el despliegue predeterminado utiliza Xray + Reality.

## Características

1. Proxy transparente (ya conoces la razón) para todos los dispositivos conectados a tu LAN.
2. Usa el puerto 1080 de tu router (por ejemplo, router.asus.com:1080) como proxy socks5/http directamente.
3. Bloqueo de anuncios.
4. Todos los beneficios adicionales que proporciona V2Ray.
5. Soporte para Xray + XTLS.

Para el proxy transparente, actualmente solo se admite el modo tproxy, que puede usarse con fakedns de forma opcional.

*AVISO*

El modo redirect es posible; consulta el script `./deploy_router_use_direct`. dnsmasq actúa como servidor DNS de la LAN, solo necesitas esto si tienes un router ASUS muy antiguo que no soporte tproxy.
Incluso, siempre puedes elegir `side router + router` para cualquier router (antiguo).

Puedes comprobar si tu router soporta TProxy con:

```sh
# modprobe xt_TPROXY
```

## Cambiar el modo del proxy

Puedes intentar cambiar al proxy transparente basado en fakedns después de un despliegue exitoso así:

```sh
$: ./use_fakedns admin@192.168.50.1
```

y volver atrás con:

```sh
$: ./use_auto_proxy admin@192.168.50.1
```

## Requisitos previos

- Un VPS que pueda acceder a internet libre.
- Un router más nuevo que soporte [Entware](https://github.com/Entware/Entware), y que pueda ejecutar V2ray/xray cómodamente.
  (Yo uso ASUS RT-AC5300, creo que OpenWRT debería satisfacerlo también después de un pequeño ajuste)
- Actualiza el firmware de tu router a [Asuswrt-merlin](https://github.com/RMerl/asuswrt-merlin.ng)
- Inicializa Entware, sigue esta [wiki](https://github.com/RMerl/asuswrt-merlin.ng/wiki/Entware)
- Un cliente SSH local que pueda iniciar sesión en el router usando clave SSH.
- Si el VPS está detrás de un firewall (por ejemplo, UCloud, Google Cloud), necesitas habilitar los puertos tcp/udp 22334/22335 en el servidor manualmente.
- Un nombre de dominio real, si quieres usar el modo Xray + XTLS.

Para un mejor rendimiento, se recomienda actualizar el kernel de Linux de tu VPS a una versión más reciente
(>= 4.9); el script puede habilitar BBR por ti en ese caso.

## Cómo usarlo

Descarga el script desde la [página de lanzamientos](https://github.com/zw963/asuswrt-merlin-v2ray/releases)

Asumimos que tu IP de VPS Linux es `34.80.108.8` y la IP de tu router es `192.168.50.1`.

### Desplegar XRay en un VPS Linux, sirviendo como servidor XRay y Shadowsocks.

Probado en CentOS 8, Ubuntu 18.0.4, Debian GNU/Linux 9.

De forma predeterminada, se usa Xray + Reality; necesitas exponer los puertos 22334/22335 para escuchar en vless/shadowsocks

```sh
 ╰─ $ ./deploy_server root@$hk
sending incremental file list
xray_server.json
          2.31K 100%  914.06kB/s    0:00:00 (xfr#1, to-chk=0/1)

......

Run ./deploy_router admin@192.168.50.1 to deploy to router.
Run ./deploy_side_router root@side_router_ip to deploy to side_router.

```

### Desplegar la configuración del cliente en el router, sirviendo como proxy transparente.

El paso anterior creará una nueva configuración de cliente xray con el binario para ti en `downloaded_binary/$your_router_arch/`. La arquitectura predeterminada del router es linux-arm-v5 para ASUS AC-5300; puedes sobrescribirla con `export router_arch=YOUR_ROUTER_ARCH`. Para el nombre de arquitectura correcto, consulta https://github.com/XTLS/Xray-core/releases/assets

Entonces, ejecutar el siguiente comando desplegará el proxy transparente Xray en tu router ASUS automáticamente.


```sh
./deploy_router admin@192.168.50.1
```

Ejecutar el siguiente comando desplegará los archivos en `downloaded_binary/amd64` a un router secundario. (para mí, es un portátil HP 2530p + CentOS 8)

```sh
./deploy_side_router root@192.168.51.111
```


Un despliegue exitoso en el router debería verse así.

![patch_router](/images/patch_router.png)

### Desplegar código en el router secundario

![deploy_side_router](/images/deploy_side_router.png)

### Comandos útiles para el router

Puedes ejecutar los siguientes comandos en el router

`/opt/etc/toggle_proxy.sh` se usa para deshabilitar/habilitar el proxy temporalmente; para deshabilitarlo completamente, necesitas `chmod -x /opt/etc/patch_router`

`/opt/etc/patch_router` básicamente, deshabilita el proxy y luego lo habilita.

`/opt/etc/update_geodata.sh` se usa para actualizar los datos de geosite.

`/opt/etc/apply_iptables_rule.sh` `/opt/etc/clean_iptables_rule.sh` para habilitar/limpiar las reglas de iptables.

`/opt/etc/check_google_use_socks5` comprueba si la conexión xray funciona. (no funciona en modo fakeDNS)

`/opt/etc/check_google_use_proxy` comprueba si el proxy transparente funciona en el (side)router. (no funciona en modo fakeDNS)

## pasos de solución de problemas

1. Asegúrate de que puedes hacer ping a través de tu VPS desde la red local, y de que puedes iniciar sesión por SSH en el servidor VPS.
2. Asegúrate de que puedes visitar el puerto escuchado del VPS usando telnet localmente en el VPS, por ejemplo, `telnet 127.0.0.1 22334`
3. Asegúrate de que puedes visitar el puerto expuesto del VPS desde fuera del VPS localmente, por ejemplo, `telnet {tu.ip.vps} 22334`,
   si no es así, comprueba si el puerto está bloqueado en tu zona con: https://tcp.ping.pe/{tu.ip}:22334
4. Asegúrate de que el certificado de tu nombre de dominio no ha expirado. (prueba a visitarlo si tienes un sitio web, o revisa los registros del servidor xray)
5. Asegúrate de que el nombre de dominio apunta correctamente a tu IP.
6. Comprueba la configuración, especialmente el `vless id`, `vless port`, `domain name` sean correctos.
7. Prueba con `./check_google_use_socks5.sh`, asegúrate de que funcione antes de probar el proxy transparente.
8. Comprueba que la hora del sistema sea correcta en local/remoto.
9. Crea un [issue](https://github.com/zw963/asuswrt-merlin-v2ray/issues)

## Contribuyendo

  * [Informes de errores](https://github.com/zw963/asuswrt-merlin-v2ray/issues)
  * Parches:
    * Haz un fork en GitHub.
    * Crea tu rama de características: `git checkout -b my-new-feature`.
    * Confirma tus cambios: `git commit -am 'Add some feature'`.
    * Envía la rama: `git push origin my-new-feature`.
    * Envía un pull request :D.
