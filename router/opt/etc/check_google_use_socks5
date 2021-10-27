#!/bin/bash

curl -so /dev/null -w "Check ${1-google.com} use socks5://127.0.0.1:1080, %{http_code}\n" ${1-google.com} -x socks5://127.0.0.1:1080
