#!/bin/bash

function perl_replace() {
    local regexp replace
    regexp=$1
    # 注意 replace 当中的特殊变量, 例如, $& $1 $2 的手动转义.
    # 写完一定测试一下，perl 变量引用: http://www.perlmonks.org/?node_id=353259
    replace=$2
    escaped_replace=$(echo "$replace" |sed 's#"#\\"#g')

    perl -i -ne "s$regexp$replacegs; print \$_; unless ($& eq \"\") {print STDERR \"\`\033[0;33m$&\033[0m' was replaced with \`\033[0;33m${escaped_replace}\033[0m'\n\"};" "$3" "$4"
}

function replace_regex () {
    local regexp="$1"
    local replace="$2"
    local file=$3

    perl_replace "$regexp" "$replace" -0 "$file"
}

if egrep -qe '"loglevel":\s*".+"' config.json; then
    replace_regex '"loglevel":\s*".+?"' '"loglevel": "debug"' config.json
fi

if [ -e /opt/etc/init.d/S22v2ray ]; then
    chmod -x /opt/etc/init.d/S22v2ray && sh /opt/etc/init.d/S22v2ray stop
else
    systemctl stop v2ray
fi

/opt/sbin/v2ray -config ${v2ray_config-/opt/etc/config.json}
