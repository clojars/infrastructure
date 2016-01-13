#!/bin/sh
set -ex

cd private
mkdir -p nginx-ssl
touch nginx-ssl/clojars.org.crt
touch nginx-ssl/clojars.org.csr
touch nginx-ssl/clojars.org.key
touch nginx-ssl/dhparams-1024.pem
touch nginx-ssl/dhparams-2048.pem
touch nginx-ssl/sub.class1.server.ca.pem

mkdir -p postfix-ssl
touch postfix-ssl/cacert.pem
touch postfix-ssl/smtpd.crt
touch postfix-ssl/smtpd.key

cp -n vars.yml.example vars.yml

