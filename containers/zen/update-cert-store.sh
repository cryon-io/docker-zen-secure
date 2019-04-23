#!/bin/bash
#source ~/envvars

# https://www.zen-solutions.io/unable-to-verify-the-first-cert/
curl -sl https://letsencrypt.org/certs/isrgrootx1.pem.txt -o /usr/local/share/ca-certificates/isrg.crt
curl -sl https://letsencrypt.org/certs/letsencryptauthorityx3.pem.txt -o /usr/local/share/ca-certificates/leauthx3.crt
chmod 750 /usr/local/share/ca-certificates/isrg.crt
chmod 750 /usr/local/share/ca-certificates/leauthx3.crt

cp -f ../data/certs/chain.crt /usr/local/share/ca-certificates/chain.crt
chmod 750 /usr/local/share/ca-certificates/chain.crt

update-ca-certificates --fresh
