#!/bin/bash

curl -so /dev/null -w "Check ${1-google.com} use transparent proxy, %{http_code}\n" ${1-google.com}
