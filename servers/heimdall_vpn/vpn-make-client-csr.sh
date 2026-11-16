#!/bin/bash
# First argument: Client identifier

mkdir ${1}
openssl genrsa -out ${1}/private.key 4096
sed "s/client.vpn.heimdall.hlsd.com/${1}/" vpn-client-openssl.conf > ${1}/openssl.conf
openssl req -config ${1}/openssl.conf -new -sha256 -key ${1}/private.key -out ${1}/client.csr
