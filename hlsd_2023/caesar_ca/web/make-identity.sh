#!/bin/bash

set -e

cn_name=$1
cn_type=$2
cn_host=$3

if [ $# -lt 3 ] || { [ $cn_type != "client" ] && [ $cn_type != "server" ]; }; then
  echo "invalid arguments, usage ./make-identity.sh name client/server host [all/renew/gen_key/gen_csr/sign_csr/make_p12/make_7z]"
  exit 1
fi

client_template=$(cat <<EOF
# OpenSSL configuration file.

[req]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
prompt              = no

[req_distinguished_name]
countryName                     = CY
stateOrProvinceName             = Nicosia
localityName                    = Nicosia
0.organizationName              = High Level Software Ltd
commonName                      = {{cn_name}}.client.{{cn_host}}
EOF
)

server_template=$(cat <<EOF
# OpenSSL configuration file.

[req]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
req_extensions      = v3_req
prompt              = no

[req_distinguished_name]
countryName                     = CY
stateOrProvinceName             = Nicosia
localityName                    = Nicosia
0.organizationName              = High Level Software Ltd
commonName                      = {{cn_name}}.{{cn_host}}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = {{cn_name}}.server.{{cn_host}}
EOF
)

if [ $# == 3 ]; then
  step_case="all"
else
  step_case=${4}
fi

if [ $cn_type == "server" ]; then
  cn_full="${cn_name}.${cn_host}"
  current_template=$server_template
else
  cn_full="${cn_name}.client.${cn_host}"
  current_template=$client_template
fi

if [ $step_case == "all" ] || [ $step_case == "gen_key" ]; then
  echo "generating key"
  cd ${cn_type}
  mkdir ${cn_full}
  chmod 700 ${cn_full}
  echo "${current_template}" | sed -e "s/{{cn_name}}/${cn_name}/g" | sed -e "s/{{cn_host}}/${cn_host}/g" > ${cn_full}/openssl.conf
  openssl genrsa -aes256 -out ${cn_full}/private.key 4096
  chmod 600 ${cn_full}/private.key
  cd ../
fi

if [ $step_case == "all" ] || [ $step_case == "renew" ] || [ $step_case == "gen_csr" ]; then
  echo "generating csr"
  cd ${cn_type}/${cn_full}
  openssl req -config openssl.conf -new -sha256 -key private.key -out ${cn_type}.csr
  cd ../../
fi

if [ $step_case == "all" ] || [ $step_case == "renew" ] || [ $step_case == "sign_csr" ]; then
  echo "signing csr"
  cp ${cn_type}/${cn_full}/${cn_type}.csr csr/${cn_full}.csr
  openssl ca -config openssl.conf -extensions ${cn_type}_cert -days 375 -notext -md sha256 -in csr/${cn_full}.csr -out issued/${cn_full}.crt
  cp issued/${cn_full}.crt ${cn_type}/${cn_full}/${cn_type}.crt
fi

if [ $step_case == "all" ] || [ $step_case == "renew" ] || [ $step_case == "make_p12" ]; then
  echo "making p12"
  cd ${cn_type}
  openssl pkcs12 -export -out issued/${cn_full}.p12 -inkey ${cn_full}/private.key -in ${cn_full}/${cn_type}.crt -certfile ca.crt
  cd ../
fi

if [ $step_case == "all" ] || [ $step_case == "renew" ] || [ $step_case == "make_7z" ]; then
  echo "making 7z"
  cd ${cn_type}/${cn_full}
  mkdir ${cn_full}
  openssl rsa -in private.key -out ${cn_full}/private.key
  cp private.key ${cn_full}/private.enc.key
  cp ${cn_type}.crt ${cn_full}/
  cp ../ca.crt ${cn_full}/
  7z a -p ../issued/${cn_full}.7z ${cn_full}
  rm -rf ${cn_full}
  cd ../../
fi
