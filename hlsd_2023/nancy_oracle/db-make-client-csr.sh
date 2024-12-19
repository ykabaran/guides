#!/bin/bash
# First argument: Client CN

openssl genrsa -out ${1}.key.pem 4096
sed "s/client.db.hlsd.com/${1}/" db-client-openssl.conf > ${1}-openssl.conf
openssl req -config ${1}-openssl.conf -new -sha256 -key ${1}.key.pem -out ${1}.csr
