#!/bin/bash
# First argument: Client identifier

cat vpn-client.conf \
    <(echo -e '<ca>') \
    inter_ca.cert.pem \
    ca.cert.pem \
    <(echo -e '</ca>\n<cert>') \
    ${1}.cert.pem \
    <(echo -e '</cert>\n<key>') \
    ${1}.key.pem \
    <(echo -e '</key>\n<tls-crypt>') \
    ta.key \
    <(echo -e '</tls-crypt>') \
    > ${1}.ovpn
