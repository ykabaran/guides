#!/bin/bash
# First argument: Client identifier

if [ $# == 0 ]; then
  echo "No arguments supplied"
  exit 1
fi

if [ $# == 1 ] || [ $2 == "gen_key" ]; then
  mkdir ${1}
  sed "s/name.client.vpn.hlsd.com/${1}/" client.vpn.hlsd.com-openssl.conf > ${1}/openssl.conf
  openssl genrsa -aes256 -out ${1}/private.key 4096
  chmod 600 ${1}/private.key
fi

if [ $# == 1 ] || [ $2 == "gen_csr" ]; then
  openssl req -config ${1}/openssl.conf -new -sha256 -key ${1}/private.key -out ${1}/client.csr
fi

if [ $# == 1 ] || [ $2 == "sign_csr" ]; then
  cd ../
  cp client/${1}/client.csr csr/${1}.csr
  openssl ca -config openssl.conf -extensions client_cert -days 375 -notext -md sha256 -in csr/${1}.csr -out issued/${1}.crt
  cp issued/${1}.crt client/${1}/client.crt
  cd client
fi

if [ $# == 1 ] || [ $2 == "make_p12" ]; then
  openssl pkcs12 -export -out issued/${1}.p12 -inkey ${1}/private.key -in ${1}/client.crt -certfile ca.crt
fi

if [ $# == 1 ] || [ $2 == "make_ovpn" ]; then
  cat vpn-client.conf \
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
fi