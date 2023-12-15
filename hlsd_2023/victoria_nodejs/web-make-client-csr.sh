#!/bin/bash
# First argument: Client CN

openssl genrsa -out ${1}.key.pem 4096
sed "s/client.web.hlsd.com/${1}/" web-client-openssl.conf > ${1}-openssl.conf
openssl req -config ${1}-openssl.conf -new -sha256 -key ${1}.key.pem -out ${1}.csr
