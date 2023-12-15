#!/bin/bash
# First argument: Client identifier

openssl genrsa -out ${1}.key.pem 4096
sed "s/client.vpn.hlsd.com/${1}/" vpn-client-openssl.conf > ${1}-openssl.conf
openssl req -config ${1}-openssl.conf -new -sha256 -key ${1}.key.pem -out ${1}.csr
