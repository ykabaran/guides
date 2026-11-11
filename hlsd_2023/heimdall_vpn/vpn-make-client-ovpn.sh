#!/bin/bash
# First argument: Client identifier

cat vpn-client-openvpn.conf \
    <(echo -e '<ca>') \
    ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${1}/client.crt \
    <(echo -e '</cert>\n<key>') \
    ${1}/private.key \
    <(echo -e '</key>\n<tls-crypt>') \
    ta.key \
    <(echo -e '</tls-crypt>') \
    > issued/${1}.ovpn
