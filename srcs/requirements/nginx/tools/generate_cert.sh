#!/bin/sh
set -eu

SSL_DIR=/etc/ssl
CRT=${SSL_DIR}/certs/server.crt
KEY=${SSL_DIR}/private/server.key
DHPARAM=${SSL_DIR}/certs/dhparam.pem

mkdir -p "${SSL_DIR}/certs" "${SSL_DIR}/private"

CN=${DOMAIN_NAME:-localhost}
ALT_NAMES=${ALT_NAMES:-DNS:localhost,IP:127.0.0.1}

if [ ! -f "$KEY" ] || [ ! -f "$CRT" ]; then
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$KEY" -out "$CRT" -days 365 \
    -subj "/CN=${CN}" \
    -addext "subjectAltName=${ALT_NAMES}"
fi

if [ ! -f "$DHPARAM" ]; then
  openssl dhparam -out "$DHPARAM" 2048
fi

chmod 600 "$KEY"
chmod 644 "$CRT" "$DHPARAM"
echo "[nginx] Certificates ready."
