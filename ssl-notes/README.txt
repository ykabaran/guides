--createing root certificate
openssl genrsa -aes-256-cbc -out rootCA.key 4096
2UIK3hGPiP1LtcCGZTtp4ef0MlFZtZ3z

openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -config ca.cnf

*****

--creating a server certificate
openssl genrsa -out server01.key 2048

openssl req -new -sha256 -key server01.key -out server01.csr -config server.cnf -sha256


-- signing server certificate with rootCA
openssl x509 -sha256 -req -in server01.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -extfile server01.cnf -days 365 -out server01.crt  

*****

--creating a client certificate
openssl genrsa -out client01.key 2048

openssl req -new -sha256 -key client01.key -out client01.csr -config client01.cnf -sha256


-- signing client certificate with rootCA
openssl x509 -sha256 -req -in client01.csr -CA rootCA.crt -CAkey rootCA.key -CAserial rootCA.srl -extfile client01.cnf -days 365 -out client01.crt 