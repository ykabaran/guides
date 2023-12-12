#!/bin/bash
# First argument: Client identifier

cat vpn-client.conf \
    <(echo -e '<ca>') \
    ca.cert.pem \
    <(echo -e '</ca>\n<cert>') \
    inter_ca.cert.pem \
    ${1}.cert.pem \
    <(echo -e '</cert>\n<key>') \
    ${1}.key.pem \
    <(echo -e '</key>\n<tls-auth>') \
    ta.key \
    <(echo -e '</tls-auth>') \
    > ${1}.ovpn
